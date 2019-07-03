# Ringly for iOS

## Development

### Setup
Ringly uses [Carthage](https://github.com/Carthage/Carthage) for dependency management. To work on the Ringly app after it has been cloned, the Carthage frameworks must first be built. Generally, this will only need to be done once - it will only need to be repeated if a framework version is updated.

First, if necessary, install Carthage:

    brew install carthage

Then, in the root directory for your clone of this repository, run the bootstrapping script:

    ./Tools/bootstrap

The app should then be ready to build in Xcode (make sure that the right scheme is selected in the top left of the your Xcode window - it should be "Ringly" with a pink icon).

### Project Structure
The Ringly workspace (`Ringly.xcworkspace`) contains several separate projects:

- [`Ringly`](https://github.com/ringly/ios/tree/master/Ringly): the Ringly app itself.
- [`RinglyAPI`](https://github.com/ringly/ios/tree/master/RinglyAPI): a client for the Ringly API.
- [`RinglyActivityTracking`](https://github.com/ringly/ios/tree/master/RinglyActivityTracking): manages the database of activity tracking data, and integrates with the Apple Health app.
- [`RinglyDFU`](https://github.com/ringly/ios/tree/master/RinglyDFU): implements firmware updates for Ringly peripherals.
    - [`DFULibrary`](https://github.com/ringly/IOS-DFU-Library/tree/ringly-swift-3): a fork of the Nordic DFU library. `RinglyDFU` is implemented on top of this library.
- [`RinglyExtensions`](https://github.com/ringly/ios/tree/master/RinglyExtensions): extensions and utilities for use in other projects.
- [`RinglyKit`](https://github.com/ringly/ios/tree/master/RinglyKit): implements the Bluetooth layer, connecting and managing Ringly peripherals. This framework is written in Objective-C.
    - [`ReactiveRinglyKit`](https://github.com/ringly/ios/tree/master/ReactiveRinglyKit): A bridge from `RinglyKit` classes to `ReactiveSwift`.

Additionally, the Ringly app and frameworks are built atop some dependencies, which are declared in `Cartfile`:

- [`DOHexKeyboard`](https://github.com/ringly/dohexkeyboard): a keyboard for entering hex strings. This framework is only used in `DeveloperWriteViewController`, and is not included in `Release` builds for the App Store.
- [`HockeySDK`](https://github.com/bitstadium/hockeysdk-ios): the HockeyApp SDK. This framework is not included in `Release` builds for the App Store or in `Debug` builds.
- [`Mixpanel`](https://github.com/mixpanel/mixpanel-iphone/): analytics.
- [`Nimble`](https://github.com/quick/nimble): a better `XCAssert...`. This framework is only used in tests, and is not included in any app builds.
- [`PureLayout`](https://github.com/ringly/purelayout/tree/feature/add-swift-names): a better API for Auto Layout. We maintained a fork for better Swift function names in Swift 2, but this might be worth revisiting to see if Swift 3's new Objective-C import rules have improved the naming. There are additionally some `PureLayout`-inspired extensions in `RinglyExtensions`.
- [`ReactiveSwift`](https://github.com/reactivecocoa/reactiveswift): functional-reactive programming. Used extensively for reacting to peripheral events.
- [`Realm`](https://github.com/realm/realm-cocoa): a database used for activity tracking data.
- [`Result`](https://github.com/antitypical/Result/): a dependency of `ReactiveSwift`.

### Git Branches
- [`master`](https://github.com/ringly/ios/tree/master) is protected.
- [`experimental`](https://github.com/ringly/ios/tree/experimental) should never be directly committed to (and the Git hooks installed with `./tools/bootstrap` will disallow it). Instead, `reset` it to a commit that you'd wish to deploy via the experimental HockeyApp build, then force-push it.
- `feature/X` branches can be rebased and force pushed.

### Logging with `RLog`/`SLog`
The app uses the `RLog` functions (`SLog` in Swift code) to log data to the console. To make the logs more usable for development, the logs are filtered based on categories. While ad-hoc (HockeyApp) builds will have all categories enabled, builds made in Xcode will not. The enabled categories are set at the top of `AppDelegate`'s `application:didFinishLaunchingWithOptions:` callback.

If you are not running the app in Xcode, you can still view log information with `idevicesyslog`. This program is part of `libimobiledevice`:

    brew install libimobiledevice

Then, with your iOS device connected, run `idevicesyslog`. It may be necessary to pipe the output to `grep "Ringly"` to cut down on unrelated output. However, if the logs are unfiltered, additional ANCS logging from iOS itself can also be viewed.

### Resources
We use [`swiftgen`](https://github.com/SwiftGen/SwiftGen) to create type-safe enumerations for resources (currently, images and localizable strings). It's available from Homebrew:

    brew install swiftgen

Whenever an image is added to `Images.xcassets` or a string is added to `Localizable.strings`, run the script `./Tools/generate-resources` to update `Resources.swift` with new `case` values. The generated code in that file can be used as follows:

- For images, use the `UIImage(asset: ...)` initializer.
- For localizable strings, use the `tr(...)` function. The `trUpper(...)` function is also provided for `SCREAMING CAPS` (if these aren't set directly in `Localizable.strings`).

### Adding new Ringly Peripherals
- In `RLYPeripheralEnumerations.h`, add a new case to the `RLYPeripheralStyle` enumeration.
- This will cause build errors throughout the app for the missing case in `switch` statements. Fix those.
- Be sure to update `RLYPeripheralStyleFromShortName` - this is not a switch statement and will not raise an error.
- Add new images to the `Peripheral Images` folder of `Images.xcassets` as is appropriate.
    - `Photographic` images are edited photorealistic renditions of the peripheral, with a transparent background.
    - `Ring Stones` images are drawn versions of each type of stone on a ring.
    - `Shadows` images are unique to each type of peripheral (i.e. ring, bracelet).
    - `Stylized` images are drawn versions. Currently they are only used for bracelets, `OnboardingRingView` (which uses the `Ring Stones` images) is used for rings.
- Test the app with the new peripheral!

### Adding new Supported Applications
The applications that Ringly supports are listed in the file `Ringly/Ringly/Apps.plist`. To add a new app, follow these steps:

1. Download the app from the iTunes, then reveal it in Finder by right-clicking on it in the "My iPhone Apps" screen.
2. Run the script `./Tools/ringly-ipa.py` on the downloaded file. Multiple applications can be processed at once. For each `.ipa` file, the filename will be printed first, followed by the bundle identifier, then the URL schemes for the app.
3. Add an entry to the `Apps.plist` file for the new app.
 - `Scheme` is the URL scheme - choose the scheme that makes sense (i.e., not a Facebook callback scheme, if possible).
 - `Name` is the display name of the app.
 - `Identifiers` is a comma-separated list of bundle identifiers - for most apps, there should only be one identifier. Multiple identifiers are only used to combine two apps into one, i.e. `com.apple.mobilephone,com.apple.facetime`.
 - `Analytics` the the identifier that will be sent to the Ringly analytics endpoints for this app.
4. Run `./Tools/LSApplicationQueriesSchemes.py`. This will update `Ringly/Ringly/Ringly-Info.plist`, so that the app has permission to read the URL scheme for the new app.
5. Add an icon set for the app to `Apps.xcassets`. The name of the image should be the app's URL scheme. Include a `40×40` `@2x` and `60×60` `@3x` version. To help with this, there is a Photoshop script, `./Tools/Save Ringly app images.jsx`. This can either be installed into Photoshop, or can be run from a shell with the `open` command. The script will make the image square, then resize and save all required scales - the image should already have been converted to a white/transparent icon before running the script, we can't automate that.

## Features
### URL Scheme
The `com.ringly.ringly://` URL scheme can be used to control app features via URLs. Note that in non-release builds, the bundle identifier suffix is also applied to this URL scheme, i.e. `com.ringly.ringly.future://`

#### A/B Tests
- `ab/enable/[test]?expires=[timestamp]` - Enables the A/B test `[test]`, which will expire at the Unix timestamp specified. The `expires` parameter may be omitted, for a test that will never expire.
- `ab/disable/[test]` - Disables the A/B test `[test]`.

#### DFU
- `dfu?hardware=[version]&application=[version]` For example, `com.ringly.ringly://dfu?hardware=V00&application=1.5.0` will attempt to load application version `1.5.0` on hardware version `V00`.

#### Multi
- `multi?[anything]=[url]` - evaluates an arbitrary number of URLs, in the order in which they are included in the query string. The names of the query parameters are ignored, as are URLs that are not valid `com.ringly.ringly` URLs.

#### Resetting Password
- `reset-password/[token]` - presents the user with the password reset interface, using the reset token provided in the URL. If the user is already authenticated, this URL will have no effect.

#### Collecting Diagnostic Data
- `collect-diagnostic-data[?reference=]` - builds a CSV representation of the logs, and uploads it to the Ringly API.

#### Developer Mode
- `developer-mode/enable`
- `developer-mode/disable`

Note that developer mode is automatically enabled when the app starts in a `Debug` build.

#### Reviewing the App
- `review` - immediately enables the review prompt in the peripherals view.

These endpoints enable and disable developer mode, which allows access to diagnostic information. Developer mode is not included in apps submitted to the App Store.
