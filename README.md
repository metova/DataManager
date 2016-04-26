# DataManager

[![Twitter](https://img.shields.io/badge/twitter-@Metova-3CAC84.svg)](http://twitter.com/metova)
[![Build Status](https://travis-ci.org/metova/DataManager.svg)](https://travis-ci.org/metova/DataManager)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/DataManager.svg)](https://img.shields.io/cocoapods/v/DataManager.svg)
[![Platform](https://img.shields.io/cocoapods/p/DataManager.svg?style=flat)](http://cocoadocs.org/docsets/DataManager)
![Documentation](https://img.shields.io/cocoapods/metrics/doc-percent/DataManager.svg)

DataManager is a lightweight Core Data utility written in Swift.

## Requirements

- Swift 2.2

## Installation

DataManager is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'DataManager'
```

## Setup

When your app is launched, set up 'DataManager' with the data model name and a name for the persistent store file:
```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

    DataManager.setUpWithDataModelName("MyApp", persistentStoreName: "MyApp")

    /* ... */

    return true
}
```

## Credits

DataManager is owned and maintained by [Metova Inc.](https://metova.com)

[Contributors](https://github.com/Metova/DataManager/graphs/contributors)

## License

MetovaBase is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Alternatives

- [CoreDataMate](https://github.com/groomsy/coredatamate) by [Todd Grooms](https://github.com/groomsy) is essentially the original Objective-C version that DataManager evolved from.
