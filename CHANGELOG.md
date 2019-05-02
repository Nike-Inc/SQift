# Changelog

All notable changes to this project will be documented in this file.
`SQift` adheres to [Semantic Versioning](http://semver.org/).

#### 4.x Releases

- `4.1.x` Releases - [4.1.0](#410) | [4.1.1](#411)
- `4.0.x` Releases - [4.0.0](#400)

#### 3.x Releases

- `3.3.x` Releases - [3.3.0](#330)
- `3.2.x` Releases - [3.2.0](#320) | | [3.2.1](#321) 
- `3.1.x` Releases - [3.1.0](#310)
- `3.0.x` Releases - [3.0.0](#300) | [3.0.1](#301)

#### 2.x Releases

- `2.1.x` Releases - [2.1.0](#210) | [2.1.1](#211)
- `2.0.x` Releases - [2.0.0](#200)

#### 1.x Releases

- `1.1.x` Releases - [1.1.0](#110) | [1.1.1](#111) | [1.1.2](#112)
- `1.0.x` Releases - [1.0.0](#100)

#### 0.x Releases

- `0.9.x` Releases - [0.9.0](#090)
- `0.8.x` Releases - [0.8.0](#080)
- `0.7.x` Releases - [0.7.0](#070) | [0.7.1](#071)
- `0.6.x` Releases - [0.6.0](#060) | [0.6.1](#061)
- `0.5.x` Releases - [0.5.0](#050)
- `0.4.x` Releases - [0.4.0](#040)
- `0.3.x` Releases - [0.3.0](#030)
- `0.2.x` Releases - [0.2.0](#020)
- `0.1.x` Releases - [0.1.0](#010)

---

## Unreleased

#### Added

#### Updated

#### Deprecated

#### Removed

#### Fixed

---

## [4.1.1](https://github.com/Nike-Inc/SQift/releases/tag/4.1.1)

Release on 2019-05-02. All issues associated with this milestone can be found using this
[filter](https://github.com/Nike-Inc/SQift/milestone/11?closed=1).

#### Fixed
-  Issue where Xcode project was incorrectly set to Swift 5.0 instead of 4.2 breaking Carthage and submodule support.
  - Fixed by [William Thompson](https://github.com/eSpecialized) & [Greg Tropino](https://github.com/gtrop1) in Pull Request [#25](https://github.com/Nike-Inc/SQift/pull/25).

---

## [4.1.0](https://github.com/Nike-Inc/SQift/releases/tag/4.1.0)

Release on 2019-04-30.  All issues associated with this milestone can be found using this
[filter](https://github.com/Nike-Inc/SQift/milestone/8?closed=1).

#### Updated
-  To Swift 5 with backwards compatibility to Swift 4.2.
   - Updated by [William Thompson](https://github.com/eSpecialized) in Pull Request [#18](https://github.com/Nike-Inc/SQift/pull/18).
-  Deployment targets to watchOS 3.0 and tvOS 10.0 in Xcode project to match podspec.
   - Updated by [William Thompson](https://github.com/eSpecialized) in Pull Request [#18](https://github.com/Nike-Inc/SQift/pull/18).

---

## [4.0.0](https://github.com/Nike-Inc/SQift/releases/tag/4.0.0)

Release on 2018-11-30.  All issues associated with this milestone can be found using this
[filter](https://github.com/Nike-Inc/SQift/milestone/7?closed=1).

#### Added
- Migration Guide for SQift 4 and added it to the README.
  - Added by [Jereme Claussen](https://github.com/jereme) in Pull Request [#16](https://github.com/Nike-Inc/SQift/pull/16).

#### Updated
- Deployment targets to iOS 9.0, Mac OSX 10.11, WatchOS 2.0 and tvOS 9.0.
  - Updated by [Jereme Claussen](https://github.com/jereme) in Pull Request [#16](https://github.com/Nike-Inc/SQift/pull/16).
  
#### Removed
- `Connection.trace` in favor of `Connection.traceEvent()`
  - Removed by [Jereme Claussen](https://github.com/jereme) in Pull Request [#16](https://github.com/Nike-Inc/SQift/pull/16).

---

## [3.3.0](https://github.com/Nike-Inc/SQift/releases/tag/3.3.0)

Released on 2018-11-30. All issues associated with this milestone can be found using this
[filter](https://github.com/Nike-Inc/SQift/milestone/5?closed=1).

#### Deprecated

- The `trace` API to prepare for 4.0 migration since the internal `sqlite3_trace` API is deprecated when bumping deployment targets.
  - Deprecated by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#15](https://github.com/Nike-Inc/SQift/pull/15).

---

## [3.2.1](https://github.com/Nike-Inc/SQift/releases/tag/3.2.1)

Released on 2018-09-17. All issues associated with this milestone can be found using this
[filter](https://github.com/Nike-Inc/SQift/milestone/6?closed=1).

#### Added

- An internal initializer to `SQLiteError` to assist in error mocking for testing.
  - Added by [Christian Noon](https://github.com/cnoon).

#### Updated

- The Xcode project to use Xcode 9.3 compatibility mode. 
  - Updated by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#10](https://github.com/Nike-Inc/SQift/pull/10).
- The Xcode project to support Xcode 10 and Swift 4.2. 
  - Updated by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#10](https://github.com/Nike-Inc/SQift/pull/10).
- The Travis-CI YAML file to use `bundler` and Xcode 10.
  - Updated by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#10](https://github.com/Nike-Inc/SQift/pull/10).

## [3.2.0](https://github.com/Nike-Inc/SQift/releases/tag/3.2.0)

Released on 2018-05-02. All issues associated with this milestone can be found using this
[filter](https://github.com/Nike-Inc/SQift/milestone/3?closed=1).

#### Added

- A new `TableLockPolicy` to handle table lock errors on `execute`, `prepare`, and `step` operations.
  - Added by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#7](https://github.com/Nike-Inc/SQift/pull/7).

#### Updated

- The test suite by replacing `do-catch` implementations with `throws` test API variants and unhelpful assertion strings.
  - Updated by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#8](https://github.com/Nike-Inc/SQift/pull/8).

---

## [3.1.0](https://github.com/Nike-Inc/SQift/releases/tag/3.1.0)

Released on 2018-04-10. All issues associated with this milestone can be found using this
[filter](https://github.com/Nike-Inc/SQift/milestone/2?closed=1).

#### Updated

- The Xcode project and Travis CI to support Xcode 9.3.
  - Updated by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#6](https://github.com/Nike-Inc/SQift/pull/6).

#### Fixed

- Compiler warnings in aggregate context generation due to Swift 4.1 compiler.
  - Fixed by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#6](https://github.com/Nike-Inc/SQift/pull/6).
- Compiler warnings in `CodableBinding` protocol extension with associated type typealias.
  - Fixed by [Christian Noon](https://github.com/cnoon) in Pull Request 
  [#6](https://github.com/Nike-Inc/SQift/pull/6).

---

## [3.0.1](https://github.com/Nike-Inc/SQift/releases/tag/3.0.1)

Released on 2018-01-02. All issues associated with this milestone can be found using this
[filter](https://github.com/Nike-Inc/SQift/milestone/4?closed=1).

#### Updated

- The Xcode project and Travis CI to support Xcode 9.2.
  - Updated by [Christian Noon](https://github.com/cnoon) in Pull Request
  [#5](https://github.com/Nike-Inc/SQift/pull/5).

## [3.0.0](https://github.com/Nike-Inc/SQift/releases/tag/3.0.0)

Released on 2017-10-25. All issues associated with this milestone can be found using this
[filter](https://github.com/Nike-Inc/SQift/milestone/1?closed=1).

### Breaking Changes

The SQift 3.0.0 release is a MAJOR version bump that comes with many new APIs and a few breaking changes worth calling out.

#### Swift 4

The SQift 3 release has been converted to only support Swift 4.
If you need to use Swift 3.2 or earlier, please stick with the latest SQift 2.x release until you can move to Swift 4.

#### Sequence Conformance on Statement

The biggest source code change in SQift 3 was the removal of `Sequence` conformance on `Statement`.
This change was made because it's not safe to assume errors will not be encountered while stepping through a result set.

#### New Query APIs

New `query` APIs have been added to safely iterate through a result set and throw if an error is encountered.
These are meant to replace the `Sequence` conformance on `Statement` and are safer and more robust as well.

The `fetch` APIs have also been removed and replaced with new `query` variants.
SQift 3 unifies all SQL "queries" underneath the `query` APIs.
The `ExpressibleByRow` protocol was also added to make it easier to convert result sets to model objects.

#### Non-Optional Query APIs

The other breaking change worth noting is the removal of non-optional `query` APIs.
In SQift 2.x, you could query for non-optional `Extractable` values directly.
SQift would internally force unwrap the optional value for you.
In SQift 3, these APIs have been removed entirely for safety reasons.

#### Generic Subscripts on Row

Swift 4 added the ability to make use of generics in subscripts.
This means that you no longer need to write custom extensions on `Row` to support your own custom bindings.
We were able to delete all the custom subscript functions in SQift itself for each of the primitive type bindings.

### Release Notes

#### Added

- A new test verifying that `Connection` supports FTS4 out-of-the-box.
- New `query` APIs to `Connection` and `Statement` to replace the `Sequence` conformance on `Statement`.
- Better support for converting result sets into model objects through the `ExpressibleByRow` and `ExpressibleByRowError` types.
- New APIs allowing you to query for `Column` information for each column in a `Row`.
- A `SQL` typealias used throughout the codebase to represent SQL statement strings.
- Support to `Connection` for interrupts.
- Support to `Statement` to query for busy, read-only status, and bound SQL.
- `BaseTestCase` class to the test suite to help DRY up the tests.
- Support to `Connection` to checkpoint a WAL database.
- Support to `Connection` for wiring up a busy handler or busy timeout.
- Support to `Connection` for update, commit, and rollback hooks.
- Support to `Connection` to backup database with progress monitoring, cancellation, and pausing.
- The ability to add an `Authorizer` to a `Connection` to prevent certain types of statements from being executed.
- Support for codable bindings along with array, set, and dictionary bindings.
- Database test demonstrating how a shared cache can compensate for checkpoint gaps in WAL databases.
- Deployment and documentation groups to the Xcode project.
- LICENSE and NOTICE documents to the project.

#### Updated

- The trace and transaction APIs to use Swift boxes instead of Objective-C block typealiases.
- The Xcode project and source code to compile against Swift 4 only.
- The `Row` subscript APIs to leverage generic subscripts in Swift 4 so you no longer need to write you own.
- The source code structure by separating out `Connection` extensions into separate files.
- The Xcode project to `import SQLite3` directly rather than including the `sqlite3.h` header.
- The copyright headers throughout the project to conform to the LICENSE.

#### Removed

- The `Sequence` conformance on `Statement` since stepping through the result set can throw an error in certain conditions.
- The `fetch` APIs from `Statement` and `Connection` and replaced with new `query` APIs.
- The non-optional `query` APIs on `Connection` due to them being unsafe.

---

## 2.1.1

### Release Notes

#### Added

- A `.swift-version` file to the project for CocoaPods set to `3.2`.

#### Updated

- The Xcode project to support Xcode 9 and Swift 3.2.
- The source and test code to compile against Swift 3.1 and 3.2.
- The sqlite3 header to the iOS 11 version.

## 2.1.0

### Release Notes

#### Added

- Support for adding and removing custom scalar and aggregate functions to SQLite.

---

## 2.0.0

### Breaking Changes

#### Extractable API

This major release contains only a single API change.
The `Extractable` protocol has been updated to allow optional return values instead of non-optional.

```swift
public protocol Extractable {
    associatedtype BindingType
    associatedtype DataType = Self

    static func fromBindingValue(_ value: Any) -> DataType?
}
```

To update to SQift 2.x, you only need to make the `DataType` return value of the `fromBindingValue` API optional in all your custom `Binding` implementations.
You'll also want to investigate your `fromBindingValue` implementations to see if you can add some additional safety now that the return type is optional.

#### Extractable Implementation for Numeric Types

The `Extractable` implementation of the numeric types has been updated to no longer clamp values outside the bounds of the type to the bounds of the type.
The implementations now return `nil` if the underlying value lies outside the bounds of the type.
The best way to demonstrate this is through an example.

If you store a value in the database with a value of `1_000`, and try to extract it as a `UInt8`, you will no longer receive `255`, but instead `nil` since the value does not fit within the `0...255` range.

### Release Notes

#### Updated

- The `Extractable` protocol to allow safe conversions of `Any` values into `DataType` by returning an optional value instead of non-optional.
- The `Extractable` implementations for all number types (`UInt8`, `Int32`, etc.) to no longer "clamp" values outside the type's bounds.

---

## 1.1.2

### Release Notes

#### Fixed

- Issue where `@discardableResult` attribute was used incorrectly on `bind` API that does not return a value.
- Issue where `TraceEvent` extension did not correctly use availability checks in the test suite.

## 1.1.1

### Release Notes

#### Updated

- Enabled `APPLICATION_EXTENSION_API_ONLY` for iOS, macOS and tvOS targets (was already on for watchOS).

---

## 1.1.0

### Release Notes

#### Updated

- The `Migrator` to an `open` ACL to allow subclassing.

---

## 1.0.0

### Release Notes

#### Updated

- All source and test APIs to compile against Swift 3 and follow the Swift API Design Guidelines.

---

## 0.9.0

### Release Notes

#### Added

- New `TraceEvent` system with `Connection.traceEvent` API backed by the new `sqlite3_tracev2` APIs.

#### Updated

- Updated to SQLite 3.14.0 header used in iOS 10.

#### Fixed

- Deprecation warning for `sqlite3_trace` function by manually removing the deprecation warning.
This is necessary since C libraries don't have availability checks.

---

## 0.8.0

### Release Notes

This release is all about updating to Xcode 8 and Swift 2.3. There are no other changes in this release.

#### Updated

- Updated project to Xcode 8 and Swift 2.3 and bumped deployment targets.
- Set code signing to automatic with no team on framework and test targets.

---

## 0.7.1

### Release Notes

Due to CI not being able to always have Xcode live in the /Applications folder, we needed to move away from module maps.
The alternative solution is to directly import the `sqlite3.h` header into the project and into the umbrella header.
Since the header is the same on all platforms, there's no reason to import different ones for each platform.

#### Added

- The `sqlite3.h` header to the project and the `-lsqlite3` linker flag.

#### Removed

- Modulemaps that created the `CSQLite` framework to import.

## 0.7.0

### Release Notes

Unfortunately the SQLCipher team is having a difficult time keeping up their support for the various Apple platforms.
Because of this, we've had to move away from the dependency altogether.
This required the database encryption logic to be removed from SQift.

#### Added

- Modulemaps to create `CSQLite` modules for each supported platform.

#### Updated

- Podspec to `preserve_paths` of the new modulemaps and import them using the `SWIFT_INCLUDE_PATHS` build setting.

#### Removed

- SQLCipher dependency and all encryption logic due to instability in the framework.
- All sections in the README referencing SQLCipher or Encryption.

## 0.6.1

### Release Notes

#### Updated

- Submodule reference for SQLCipher to point at Bitbucket clone.
- Connection tests to verify foreign key settings were connection specific.

## 0.6.0

### Release Notes

#### Added

- String extension allowing users to safely escape SQL strings.

## 0.5.0

### Release Notes

#### Updated

- All logic to use Swift 2.2 APIs.
- The required Xcode version to 7.3.

## 0.4.0

### Release Notes

#### Added

- Added `NSURL` binding along with `Row` subscripts and unit tests.

## 0.3.0

### Release Notes

#### Added

- New `run` and `fetch` variant APIs for arrays and dictionaries to `Connection`.
- Tests verifying all parameter binding variants work as expected for `fetch` and `query` APIs.

#### Updated

- `Database` and `Connection` initializers now set `sharedCache` to `false` by default.

> Using a `sharedCache` is intended for use with embedded servers to help keep memory usage low for embedded devices.

#### Removed

- The `readOnly` parameter from the `Database` initializer.

#### Fixed

- Refactored test names to use `Connection` instead of `Database` where applicable.

## 0.2.0

### Release Notes

#### Added

- Test around fetching a `Row` that cannot be found.
- Method to `Connection` allowing you to query a value with a parameter array.

#### Updated

- The connection property ACL on the `ConnectionQueue` to `public`.
- The writer queue and reader pool property ACLs on the `Database` to `public`.
- `Connection` and `Statement` fetch functions to return an optional `Row` for cases where the fetch does not find a valid `Row`.
- The code sample in the README for fetching a single `Row`.
- `Database` and `ConnectionPool` initializers to take connection preparation closures to allow you to prepare a `Connection` for use. This allows you to set PRAGMAs, custom collation closures, etc. on a connection before starting to use it.

## 0.1.0

### Release Notes

This is the initial release of SQift.
Things will continue to evolve through the November '15 - January '16 timeframe as more SQift features are added.
The goal is to be ready to release the 1.0.0 version around late January '16.
The road to 1.0.0 will attempt to follow semver as closely as possible, but is not guaranteed.
Until the 1.0.0 release, please pay close attention to the upgrade and release notes for each version.
