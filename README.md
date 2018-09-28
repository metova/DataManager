![DataManager](header_logo.png)

[![Build Status](https://travis-ci.org/metova/DataManager.svg)](https://travis-ci.org/metova/DataManager?branch=master)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/DataManager.svg)](https://img.shields.io/cocoapods/v/DataManager.svg)
[![Documentation](https://img.shields.io/cocoapods/metrics/doc-percent/DataManager.svg)](http://cocoadocs.org/docsets/DataManager/)
[![Coverage Status](https://coveralls.io/repos/github/metova/DataManager/badge.svg?branch=master)](https://coveralls.io/github/metova/DataManager?branch=master)
[![Platform](https://img.shields.io/cocoapods/p/DataManager.svg?style=flat)](http://cocoadocs.org/docsets/DataManager)
[![Twitter](https://img.shields.io/badge/twitter-@Metova-3CAC84.svg)](http://twitter.com/metova)

DataManager is a lightweight Core Data utility. It is not a replacement/wrapper for Core Data. Here are some of the highlights:

- Encapsulates the boilerplate associated with setting up the Core Data stack.
- Sets up the stack with a private `NSPrivateQueueConcurrencyType` context as the root context with a public `NSMainQueueConcurrencyType` child context. This setup allows for asynchronous saves to disk.
- Provides Swift-friendly convenience fetching methods that make use of generics to prevent you from having to handle downcasting from `NSManagedObject` to the entity's class every time you perform a fetch.

## Requirements

- iOS 9.0
- Swift 4.2

## Installation

DataManager is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'DataManager'
```

If you would like to test a beta version of DataManager, you can install the latest from develop:

```ruby
pod 'DataManager', :git => 'https://github.com/metova/DataManager.git', :branch => 'develop'
```

## Usage

#### Setup

When your app is launched, set up `DataManager` with the data model name and a name for the persistent store file:
```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

    DataManager.setUp(withDataModelName: "MyApp", bundle: .main, persistentStoreName: "MyApp")

    /* ... */

    return true
}
```

This won't set up the Core Data stack right away. The stack is lazy loaded when `DataManager.mainContext` is first used.

#### Fetching

DataManager uses generics so you don't have to worry about casting the `NSManagedObject` results to the entity's class every time you perform a fetch. For example, the type of `olderUsers` below is `[User]`.

```swift
let predicate = NSPredicate(format: "\(#keyPath(Person.birthDate)) < %@", someDate)
let olderUsers = DataManager.fetchObjects(entity: User.self, predicate: predicate, context: DataManager.mainContext)
```

#### Deleting

```swift
DataManager.delete([user1, user2], in: DataManager.mainContext)
```

#### Saving

```swift
DataManager.persist(synchronously: false)
```

#### Child Contexts

```swift
let backgroundContext = DataManager.createChildContext(withParent: DataManager.mainContext)

backgroundContext.perform {
    /* Do heavy lifting in the background */
}
```

## Credits

DataManager is owned and maintained by [Metova Inc.](https://metova.com)

[Contributors](https://github.com/Metova/DataManager/graphs/contributors)

## License

DataManager is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Alternatives

- [CoreDataMate](https://github.com/groomsy/coredatamate) by [Todd Grooms](https://github.com/groomsy) is essentially the original Objective-C version that DataManager evolved from.
