import Foundation
import RinglyAPI
import ReactiveSwift

protocol AnalyticsNotifiedStore
{
    func trackNotifiedProducer(parameters: [String:AnyObject]) -> SignalProducer<(), NSError>
}

extension APIService: AnalyticsNotifiedStore
{
    func trackNotifiedProducer(parameters: [String : AnyObject]) -> SignalProducer<(), NSError>
    {
        return producer(for: AppEventsRequest(parameters: parameters)).void
    }
}
