# Changelog

The changelog for SQift includes information about the each release including any update notes, release notes as well as bug fixes, updates to existing features and new features. Additionally, SQift follows [semantic versioning](http://semver.org/) (a.k.a semver) which makes it easy to tell whether the release was a MAJOR, MINOR or PATCH revision.

---

## 0.7.1

### Release Notes

Due to CI not being able to always have Xcode live in the /Applications folder, we needed to move away from module maps. The alternative solution is to directly import the `sqlite3.h` header into the project and into the umbrella header. Since the header is the same on all platforms, there's no reason to import different ones for each platform.

#### Added

* The `sqlite3.h` header to the project and the `-lsqlite3` linker flag.

#### Removed

* Modulemaps that created the `CSQLite` framework to import.

## 0.7.0

### Release Notes

Unfortunately the SQLCipher team is having a difficult time keeping up their support for the various Apple platforms. Because of this, we've had to move away from the dependency altogether. This required the database encryption logic to be removed from SQift.

#### Added

* Modulemaps to create `CSQLite` modules for each supported platform.

#### Updated

* Podspec to `preserve_paths` of the new modulemaps and import them using the `SWIFT_INCLUDE_PATHS` build setting.

#### Removed

* SQLCipher dependency and all encryption logic due to instability in the framework.
* All sections in the README referencing SQLCipher or Encryption.

## 0.6.1

### Release Notes

#### Updated

* Submodule reference for SQLCipher to point at Bitbucket clone.
* Connection tests to verify foreign key settings were connection specific.

## 0.6.0

### Release Notes

#### Added

* String extension allowing users to safely escape SQL strings.

## 0.5.0

### Release Notes

#### Updated

* All logic to use Swift 2.2 APIs.
* The required Xcode version to 7.3.

## 0.4.0

### Release Notes

#### Added

* Added `NSURL` binding along with `Row` subscripts and unit tests.

## 0.3.0

### Release Notes

#### Added

* New `run` and `fetch` variant APIs for arrays and dictionaries to `Connection`.
* Tests verifying all parameter binding variants work as expected for `fetch` and `query` APIs.

#### Updated

* `Database` and `Connection` initializers now set `sharedCache` to `false` by default.

> Using a `sharedCache` is intended for use with embedded servers to help keep memory usage low for embedded devices. For app development using a WAL journal mode, it is better to not use a shared cache to avoid table locking.

#### Removed

* The `readOnly` parameter from the `Database` initializer.

#### Fixed

* Refactored test names to use `Connection` instead of `Database` where applicable.

## 0.2.0

### Release Notes

#### Added

* Test around fetching a `Row` that cannot be found.
* Method to `Connection` allowing you to query a value with a parameter array.

#### Updated

* The connection property ACL on the `ConnectionQueue` to `public`.
* The writer queue and reader pool property ACLs on the `Database` to `public`.
* `Connection` and `Statement` fetch functions to return an optional `Row` for cases where the fetch does not find a valid `Row`.
* The code sample in the README for fetching a single `Row`.
* `Database` and `ConnectionPool` initializers to take connection preparation closures to allow you to prepare a `Connection` for use. This allows you to set PRAGMAs, custom collation closures, etc. on a connection before starting to use it.

## 0.1.0

### Release Notes

This is the initial release of SQift. Things will continue to evolve through the November '15 - January '16 timeframe as more SQift features are added. The goal is to be ready to release the 1.0.0 version around late January '16. The road to 1.0.0 will attempt to follow semver as closely as possible, but is not guaranteed. Until the 1.0.0 release, please pay close attention to the upgrade and release notes for each version.
