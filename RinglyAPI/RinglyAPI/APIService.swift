import ReactiveCocoa
import ReactiveSwift
import Result
import RinglyExtensions

/// Enumerates error cases of `APIService`.
public enum APIServiceError: Int, CustomNSError
{
    // MARK: - Cases
    
    /// The JSON response was valid JSON
    case incorrectJSON

    /// The share code was invalid.
    case invalidShareCode

    /// The session is already authenticated.
    case alreadyAuthenticated

    /// The access token was not found in the response.
    case tokenNotFound

    /// A request provider returned a nil request.
    case nilRequest

    /// A non-HTTP URL response was provided.
    case notHTTPURLResponse
    
    // MARK: - NSError Convertible
    
    /// The domain for `NSError` representations.
    public static let errorDomain = "APIServiceError"
}

public final class APIService: NSObject
{
    // MARK: - Initialization
    public init(authenticationStorage: APIServiceAuthenticationStorage)
    {
        // create authentication properties
        let authenticationProperty = authenticationStorage.authentication
        self._authentication = authenticationProperty
        self.authentication = Property(authenticationProperty)

        self.authenticated = Property(
            initial: false,
            then: authenticationProperty.producer.map({ $0.token != nil })
        )

        self.lastAuthenticatedEmail = authenticationStorage.lastAuthenticatedEmail
    }

    // MARK: - Authentication
    fileprivate let _authentication: MutableProperty<Authentication>
    public let authentication: Property<Authentication>
    fileprivate let lastAuthenticatedEmail: MutableProperty<String?>

    /// Whether or not the service is currently authenticated.
    public let authenticated: Property<Bool>

    // MARK: - Session

    /// The URL session used by the service.
    fileprivate let session = URLSession(
        configuration: URLSessionConfiguration.default,
        delegate: nil,
        delegateQueue: nil
    )
}

extension APIService
{
    /// The error domain for HTTP error responses.
    public static let httpErrorDomain = "APIServiceHTTPErrorDomain"

    /// A producer for making an API request.
    ///
    /// - Parameters:
    ///   - provider: A request provider.
    ///   - transform: A function to transform the data response into a value or an error.
    ///   - extraUserInfo: A function to add additional user info error keys for a 400/500 response.
    private func producer<Value>(for provider: RequestProviding,
                                 transform: @escaping (Data) -> Result<Value, NSError>,
                                 extraUserInfo: @escaping (HTTPURLResponse, Value) -> [String:Any])
        -> SignalProducer<Value, NSError>
    {
        guard let request = provider.request(for: authentication.value.server.baseURL) else {
            return SignalProducer(error: APIServiceError.nilRequest as NSError)
        }

        return producer(request: request, transform: transform, extraUserInfo: extraUserInfo)
    }

    /// A producer for making an API request.
    ///
    /// - Parameters:
    ///   - request: A request.
    ///   - transform: A function to transform the data response into a value or an error.
    ///   - extraUserInfo: A function to add additional user info error keys for a 400/500 response.
    fileprivate func producer<Value>(request: URLRequest,
                                     transform: @escaping (Data) -> Result<Value, NSError>,
                                     extraUserInfo: @escaping (HTTPURLResponse, Value) -> [String:Any])
        -> SignalProducer<Value, NSError>
    {
        // add authentication, uuids, etc. to the request
        var copy = request

        // add standard authentication headers
        copy.setValue("iOS", forHTTPHeaderField: "X-PLATFORM")
        copy.setValue(authentication.value.server.appToken, forHTTPHeaderField: "X-APPTOKEN")
        copy.setValue(UIDevice.current.identifierForVendor?.uuidString, forHTTPHeaderField: "X-UUID")

        // if the authorization is not being provided manually, include it - this is necessary for the second
        // part of authentication, which manually provides the token received in the first part
        if copy.value(forHTTPHeaderField: "Authorization") == nil
        {
            copy.setValue(authentication.value.token.map({ "Token \($0)" }), forHTTPHeaderField: "Authorization")
        }

        // make the actual request
        let sendRequest = session.reactive.data(with: copy).mapError({ $0.error as NSError })
        let httpRequest = sendRequest.attemptMap({ data, response in
            Result(unwrap(data, response as? HTTPURLResponse), failWith: APIServiceError.notHTTPURLResponse as NSError)
        })

        // add logging
        func requestString(_ request: URLRequest) -> String
        {
            return "\(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")"
        }

        let logging = httpRequest.on(
            started: { APILogFunction("Sending “\(requestString(copy))”") },
            failed: { error in APILogFunction("Failed “\(requestString(copy))”, error is \(error)") },
            value: { data, response in APILogFunction("\(response.statusCode) <- “\(requestString(copy))” \(String(data: data, encoding: String.Encoding.utf8))") }
        )

        // parse the data, handle any HTTP errors
        let transformed = logging.attemptMap({ data, response -> Result<Value, NSError> in
            transform(data).flatMap({ value -> Result<Value, NSError> in
                let code = response.statusCode

                if code >= 400
                {
                    var userInfo: [String:Any] = [
                        NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: code)
                    ]

                    for (key, value) in extraUserInfo(response, value)
                    {
                        userInfo[key] = value
                    }

                    return .failure(NSError(
                        domain: APIService.httpErrorDomain,
                        code: code,
                        userInfo: userInfo
                    ))
                }
                else
                {
                    return .success(value)
                }
            })
        })

        return transformed.observe(on: QueueScheduler.main)
    }

    /// A producer for retrieving data from the API.
    ///
    /// - Parameter provider: A request provider.
    public func dataProducer(for provider: RequestProviding) -> SignalProducer<Data, NSError>
    {
        return producer(for: provider, transform: Result.success, extraUserInfo: { _, _ in [:] })
    }

    /// A producer for retrieving data from the API.
    ///
    /// - Parameter request: A request.
    public func dataProducer(request: URLRequest) -> SignalProducer<Data, NSError>
    {
        return producer(request: request, transform: Result.success, extraUserInfo: { _, _ in [:] })
    }

    
    /// A noop producer to swap out for cases you dont want to send data to the api
    public func noopProducer(for provider: RequestProviding) -> SignalProducer<Any, NSError> {
        return SignalProducer(value: "").delay(0.5, on: QueueScheduler.main)
    }
    
    /// A producer for retrieving JSON from the API.
    ///
    /// - Parameter provider: A request provider.
    public func producer(for provider: RequestProviding) -> SignalProducer<Any, NSError>
    {
        return producer(for: provider, transform: { data in
            do
            {
                return try .success(
                    JSONSerialization.jsonObject(with: data, options: .allowFragments) // API can return fragments
                )
            }
            catch let error as NSError
            {
                return .failure(error)
            }
        }, extraUserInfo: NSError.userInfoForHTTPResponse)
    }

    /// A producer for retrieving JSON from the API and processing it as a response.
    ///
    /// - Parameter provider: A request provider.
    public func resultProducer<Provider>(for provider: Provider)
        -> SignalProducer<Provider.Output, NSError>
        where Provider: RequestProviding, Provider: ResponseProcessing
    {
        return producer(for: provider).attemptMap(provider.result)
    }
}

extension APIService
{
    fileprivate var authenticationIsAnonymous: Bool
    {
        return authentication.value.token == nil
    }
}

extension APIService
{
    // MARK: - Authentication

    /// A producer that registers a user and updates the service's `authentication`.
    ///
    /// - Parameters:
    ///   - email: The email address to register.
    ///   - password: The password to use for the user's account.
    ///   - firstName: The first name to register.
    ///   - lastName: The last name to register.
    ///   - receiveUpdates: Whether or not the user should receive updates from users.
    ///   - device: The device to use for snapshot values.
    public func registerProducer(email: String,
                                 password: String,
                                 firstName: String?,
                                 lastName: String?,
                                 receiveUpdates: Bool,
                                 device: UIDevice)
        -> SignalProducer<Authentication, NSError>
    {
        return SignalProducer.`defer` {
            // ensure that we are not already authenticated
            guard self.authenticationIsAnonymous else {
                return SignalProducer(error: APIServiceError.alreadyAuthenticated as NSError)
            }

            // create endpoints for registration and authentication
            let registerRequest = UserRegisterRequest(
                username: email,
                password: password,
                firstName: firstName,
                lastName: lastName,
                receiveUpdates: receiveUpdates
            )

            let authenticateRequest = AuthenticationRequest(username: email, password: password, device: device)

            // send a registration request
            let server = self.authentication.value.server

            return self.resultProducer(for: registerRequest)
                .flatMap(.latest, transform: { user in
                    // send an authentication request to retrieve a token
                    self.resultProducer(for: authenticateRequest).map({ token in
                        Authentication(user: user, token: token, server: server)
                    })
                })
                .observe(on: QueueScheduler.main)
                .on(value: { [weak self] authentication in
                    self?._authentication.value = authentication
                })
        }
    }

    /// A producer that authenticates a user and updates the service's `authentication`.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    ///   - device: The device to use for snapshot values.
    public func authenticateProducer(email: String, password: String, device: UIDevice)
        -> SignalProducer<Authentication, NSError>
    {
        return SignalProducer.`defer` {
            // ensure that we are not already authenticated
            guard self.authenticationIsAnonymous else {
                return SignalProducer(error: APIServiceError.alreadyAuthenticated as NSError)
            }

            let server = self.authentication.value.server
            let endpoint = AuthenticationRequest(username: email, password: password, device: device)

            return self.resultProducer(for: endpoint)
                .flatMap(.latest, transform: { token -> SignalProducer<Authentication, NSError> in
                    let base = RESTGetRequest<User>(identifier: "me")
                    let request = AddedHTTPHeadersRequest(
                        base: base,
                        headers: ["Authorization": "Token \(token)"]
                    )

                    return self.producer(for: request).attemptMap(base.result).map({ user in
                        Authentication(user: user, token: token, server: server)
                    })
                })
                .observe(on: QueueScheduler.main)
                .on(value: { [weak self] authentication in
                    self?._authentication.value = authentication
                })
        }
    }

    /// A producer that modifies the current authenticated user, updating `authentication` if successful.
    ///
    /// - Parameter user: The new user value.
    public func editUserProducer(_ user: User) -> SignalProducer<(), NSError>
    {
        return resultProducer(for: RESTPatchRequest(model: user))
            .observe(on: QueueScheduler.main)
            .on(value: { [weak self] (user: User) in
                guard let strongSelf = self else { return }

                strongSelf._authentication.value = Authentication(
                    user: user,
                    token: strongSelf.authentication.value.token,
                    server: strongSelf.authentication.value.server
                )
            })
            .void
    }

    /// Logs the user out, modifying `authentication`.
    public func logout()
    {
        lastAuthenticatedEmail.value = _authentication.value.user?.email
        _authentication.value = Authentication(user: nil, token: nil, server: _authentication.value.server)
    }
}

// MARK: - Authentication Storage
public protocol APIServiceAuthenticationStorage
{
    var lastAuthenticatedEmail: MutableProperty<String?> { get }
    var authentication: MutableProperty<Authentication> { get }
}
