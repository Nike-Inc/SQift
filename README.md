# SQift

[![Build Status](https://travis-ci.org/Nike-Inc/SQift.svg?branch=master)](https://travis-ci.org/Nike-Inc/SQift)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/SQift.svg)](https://img.shields.io/cocoapods/v/SQift.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/SQift.svg?style=flat)](http://cocoadocs.org/docsets/SQift)

SQift is a lightweight Swift wrapper for SQLite.

## Features

- [X] On-Disk, In-Memory and Temporary Database Connections
- [X] SQL Statement Execution
- [X] Generic Parameter Binding and Value Extraction
- [X] Codable and Codable Collection Bindings
- [X] Simple Query APIs for Values, Rows, and Collections
- [X] Transactions and Savepoints
- [X] Tracing and Trace Event Support
- [X] Scalar and Aggregate Functions
- [X] Commit, Rollback, Update, Authorizer Hooks
- [X] WAL Checkpointing
- [X] ConnectionQueue for Serial Execution per Database Connection
- [X] ConnectionPool for Parallel Execution of Read-Only Connections
- [X] Top-Level Database to Simplify Thread-Safe Reads and Writes
- [X] Database Migration Support
- [X] Database Backups
- [x] Comprehensive Unit Test Coverage
- [x] Complete Documentation

## Requirements

- iOS 10.0+, macOS 10.12+, tvOS 10.0+, watchOS 3.0+
- Xcode 10.2+
- Swift 5.0+

## Migration Guides

- [SQift 4.0 Migration Guide](Documentation/SQift%204.0%20Migration%20Guide.md)

## Communication

- Need help? Open an issue.
- Have a feature request? Open an issue.
- Find a bug? Open an issue.
- Want to contribute? Fork the repo and submit a pull request.

---

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.

>Xcode 11+ is required to provide SwiftPM support for iOS, watchOS, and tvOS platforms.

In Xcode menu `File -> Swift Packages -> Add Package Dependency...` enter repository URL `https://github.com/DnV1eX/SQift.git`.

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects.
You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.3+ is required to build SQift.

To integrate SQift into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
platform :ios, '11.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'SQift', '~> 4.0'
end
```

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate SQift into your Xcode project using Carthage, specify it in your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile):

```
github "Nike-Inc/SQift" ~> 4.0
```

Run `carthage update` to build the framework and drag the built `SQift.framework` into your Xcode project.

---

## Usage

SQift is designed to make it as easy as possible to work with SQLite from Swift.
It does not, however, eliminate the need to understand how SQLite actually works.
Before diving into SQift, it is recommended to first have a firm grasp on what SQLite is, how it works and how to use it.

- [SQLite Docs](https://www.sqlite.org/docs.html)
- [SQLite Tutorial](http://zetcode.com/db/sqlite/)

SQift heavily leverages the new error handling model released with Swift 2.0.
It was designed from the ground up to throw in all applicable cases.
This makes it easy to wrap all your SQift calls in the do-catch paradigm.

### Creating a Database Connection

Creating a database connection is simple.

```swift
let onDiskConnection = try Connection(storageLocation: .onDisk("path_to_db"))
let inMemoryConnection = try Connection(storageLocation: .inMemory)
let tempConnection = try Connection(storageLocation: .temporary)
```

There are also convenience parameters to make it easy to customize the flags when initializing the database connection:

```swift
let connection = try Connection(
    storageLocation: .onDisk("path_to_db"),
    readOnly: true,
    multiThreaded: false,
    sharedCache: false
)
```

> In most cases, the default values are preferred.
> For more details about creating a database connection, please refer to the SQLite [documentation](https://www.sqlite.org/c3ref/open.html).

### Executing Statements

To execute a SQL statement on the `Connection`, you need to first create a `Connection`, then call `execute`.

```swift
let connection = try Connection(storageLocation: .onDisk("path_to_db"))

try connection.execute("PRAGMA foreign_keys = true")
try connection.execute("PRAGMA journal_mode = WAL")

try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

try connection.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
try connection.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")

try connection.execute("UPDATE cars SET name = 'Honda' where id = 1")
try connection.execute("UPDATE cars SET price = 61_999 where name = 'Mercedes'")

try connection.execute("DELETE FROM cars where name = 'Mercedes'")
try connection.execute("DROP TABLE cars")
```

### Bindings

Most Swift data types cannot be directly stored inside the database.
They need to be converted to a data type supported by SQLite.
In order to support moving Swift data types into the database and back out again, SQift leverage three powerful protocols: `Bindable`, `Extractable`, and `Binding`.

#### Bindable Protocol

The `Bindable` protocol handles converting Swift data types into a `BindingValue` enumeration type which can be stored in the database.

```swift
public protocol Bindable {
    var bindingValue: BindingValue { get }
}
```

#### Extractable Protocol

While the `Bindable` protocol helps move Swift data types into the database, the `Extractable` protocol allows SQift to extract the values from the database `Connection` and convert them back to the requested Swift data type.

```swift
public protocol Extractable {
    typealias BindingType
    typealias DataType = Self
    static func fromBindingValue(_ value: Any) -> DataType?
}
```

#### Binding Protocol

To extend Swift data types to be able to be inserted into the database and also be extracted safely, the `Binding` protocol forces the data type to conform to both the `Bindable` and `Extractable` protocols.

```swift
public protocol Binding: Bindable, Extractable {}
```

In order to make it as easy as possible to use SQift, SQift extends the following Swift data types to conform to the `Binding` protocol:

- **NULL:** `NSNull`
- **INTEGER:** `Bool`, `Int8`, `Int16`, `Int32`, `Int64`, `Int`, `UInt8`, `UInt16`, `UInt32`, `UInt64`, `UInt`
- **REAL:** `Float`, `Double`
- **TEXT:** `String`, `URL`, `Date`
- **BLOB:** `Data`

> Additional Swift data types can easily add `Bindable` protocol conformance if necessary.

### Binding Parameters to a Statement

Safely binding parameters to a `Statement` is easy thanks to the `Binding` protocol.
First you need to `prepare` a `Statement` object, then `bind` the parameters and `run` it using method chaining.

```swift
let connection = try Connection(storageLocation: .onDisk("path_to_db"))

try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52_642).run()
try connection.prepare("INSERT INTO cars VALUES(:id, :name, :price)").bind([":id": 1, ":name": "Audi", ":price": 52_642]).run()
```

There are also convenience methods on the `Connection` for preparing a `Statement`, binding parameters and running it all in a single method named `run`.

```swift
let connection = try Connection(storageLocation: .onDisk("path_to_db"))

try connection.run("INSERT INTO cars VALUES(?, ?, ?)", 1, "Audi", 52_642)
try connection.run("INSERT INTO cars VALUES(:id, :name, :price)", parameters: [":id": 1, ":name": "Audi", ":price": 52_642])
```

> It is very important to properly escape all parameter values provided in a SQL statement.
> When in doubt, always use the provided bind functionality.

### Querying Data

Querying data from the database makes extensive use of the `Binding` protocol.
It extracts the original values from the database, then uses the `Binding` protocol along with generics to convert the final Swift type.

#### Single Values

Extracting a single value from the database can be done using the `query` API.

```swift
let synchronous: Int? = try db.query("PRAGMA synchronous")
let minPrice: UInt? = try db.query("SELECT avg(price) FROM cars WHERE price > ?", 40_000)
```

#### Multiple Values

You can also use the `query` API to extract multiple values through the `Row` type.

```swift
if let row = try db.query("SELECT name, type, price FROM cars WHERE type = ? LIMIT 1", "Sedan") {
    let name: String = row[0]
    let type: String = row[1]
    let price: UInt = row[2]
}
```

The values can be accessed by index or by name.

```swift
if let row = try db.query("SELECT name, type, price FROM cars WHERE type = ? LIMIT 1", "Sedan") {
    let name: String = row["name"]
    let type: String = row["type"]
    let price: UInt = row["price"]
}
```

> The `Row` type supports both optional and non-optional value extraction through index and name subscripts.
> The non-optional subscripts are certainly the safest, but not always the most convenient.
> It is up to you to decide which makes more sense to use in each situation.
> Generally, try to use the optional types where the SQL statement is decoupled from the row value extraction.
> In these cases, the `ExpressibleByRow` type can be useful to help handle optionality.

#### ExpressibleByRow Types

In many cases, you want to construct model objects from a row in a result set.
The `ExpressibleByRow` type was designed for this use case.

```swift
protocol ExpressibleByRow {
    init(row: Row) throws
}
```

To make use of the `ExpressibleByRow` protocol, first create your model object and conform to the protocol.

```swift
struct Car {
    let name: String
    let type: String
    let price: UInt
}

extension Car: ExpressibleByRow {
    init(row: Row) throws {
        guard
            let name: String = row[0],
            let type: String = row[1],
            let price: UInt = row[2]
        else {
            throw ExpressibleByRowError(type: Car.self, row: row)
        }

        self.name = name
        self.type = type
        self.price = price
    }
}
```

Then, you can use the `query` API to automatically convert the result set into a `Car`.

```swift
let car: Car? = try db.query("SELECT name, type, price FROM cars WHERE type = ? LIMIT 1", "Sedan")
```

#### Multiple Rows

The `query` APIs also support querying for result sets with multiple rows.

```swift
let names: [String] = try db.query("SELECT name FROM cars")
let cars: [Car] = try db.query("SELECT * FROM cars WHERE price > ?", [20_000])
```

In addition to array result sets, you can also create dictionary result sets.

```swift
let sql = "SELECT name, price FROM cars WHERE price > ?"
let prices: [String: UInt] = try db.query(sql, 20_000) { ($0[0], $0[1]) }
```

### Dates

SQift has full binding support for `Date` objects which allows you to easily leverage the builtin date functionality in SQLite.
You can insert dates easily into the database, run queries against them, and then extract them back out.
SQift handles this through the `Date` binding which leverages the `bindingDateFormatter`.
By default, all `Date` types are stored in the database as `TEXT`, so make sure you map your column types accordingly.

```swift
let date1975: Date!
let date1983: Date!
let date1992: Date!
let date2001: Date!

try connection.execute(
	"CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, release_date TEXT)"
)

try connection.execute("INSERT INTO cars(?, ?)", "70s car", date1975)
try connection.execute("INSERT INTO cars(?, ?)", "80s car", date1983)
try connection.execute("INSERT INTO cars(?, ?)", "90s car", date1992)
try connection.execute("INSERT INTO cars(?, ?)", "00s car", date2001)
```

Once you have your dates stored in the database, you can run date range queries to narrow down your data.

```swift
let date1980: Date!
let date2000: Date!

let carCount: Int = try connection.query(
    "SELECT count(*) FROM cars WHERE release_date >= date(?) AND release_date <= date(?)",
    date1980, 
    date2000
)

print("Total Cars from the 80s and 90s: \(carCount)") // should equal 2
```

> You can swap the default date formatting, but be careful when doing so.
> You need to make sure the new date format complies with the SQLite [requirements](https://www.sqlite.org/lang_datefunc.html) so date range queries will continue to work as expected.

You can also extract dates out of each row as an `Date`.

```swift
let sql = "SELECT release_date WHERE name = ? LIMIT 1"
let releaseDate: Date = try connection.query(sql, "80s car")
```

### Custom Bindings

SQift has support for many common primitive types, but what about when you want to store a custom type in the database?
This is where custom bindings come into play.
All you need to do to store your own custom types in the database is conform to the `Binding` protocol.

```swift
enum DownloadState: Int {
    case pending, downloading, downloaded, failed
}

extension DownloadState: Binding {
    typealias BindingType = Int64

    var bindingValue: BindingValue { return .integer(Int64(rawValue)) }

    static func fromBindingValue(_ value: Any) -> AssetType? {
        guard let value = value as? Int64, let rawValue = Int(exactly: value) else { return nil }
        return DownloadState(rawValue: rawValue)
    }
}

try connection.execute("CREATE TABLE downloads(name TEXT PRIMARY KEY, state INTEGER NOT NULL)")
try connection.run("INSERT INTO downloads VALUES(?, ?)", "image1", DownloadState.pending)

if let state: DownloadState? = try connection.query("SELECT state FROM downloads WHERE name = 'image1') {
    print(state)
}

// Output
// DownloadState.pending
```

#### Codable Bindings

SQift also supports `Codable` bindings out-of-the-box.
For example, let's say we have a `Person` object that is `Codable`.
We can store `Person` instances directly in the database without having to create a custom binding.

```swift
struct Employee {
    let id: Int64
    let firstName: String
    let lastName: String
    let age: UInt
}

let phil = Person(id: 1, firstName: "Phil", lastName: "Knight", age: 79)

try connection.execute("CREATE TABLE employees(id INTEGER PRIMARY KEY, employee BLOB NOT NULL)")
try connection.run("INSERT INTO employees(employee) VALUES(?)", phil)

if let employee1: Employee? = try connection.query("SELECT employee FROM employees WHERE id = 1) {
    print(employee.firstName)
}

// Output
// "phil"
```

> You need to think through whether it makes sense for you to use `Codable` bindings or not.
> While they are very convenient, the information inside them cannot be queried.
> In the above example, you could not run a query such as `SELECT count(1) FROM employees where firstName = 'Phil'`.
> If your use case does not require you to run such a search, then `Codable` bindings may be a useful choice.

#### Codable Collections

SQift also supports `Codable` collections through the `ArrayBinding`, `SetBinding`, and `DictionaryBinding` types.

```swift
let points: ArrayBinding = [
    CGPoint(x: 1.0, y: 2.0),
    CGPoint(x: 3.0, y: 4.0),
    CGPoint(x: 5.0, y: 6.0),
    CGPoint(x: 7.0, y: 8.0),
    CGPoint(x: 9.0, y: 10.0)
]

try connection.execute("CREATE TABLE stream(id INTEGER PRIMARY KEY, data BLOB NOT NULL)")
try connection.run("INSERT INTO stream(data) VALUES(?)", points)

let pointsQueried: ArrayBinding<CGPoint>? = try connection.query("SELECT data FROM stream WHERE id = 1")

pointsQueried?.elements.forEach { print("(\($0.x), \($0.y))") }

// Output
// (1.0, 2.0)
// (3.0, 4.0)
// (5.0, 6.0)
// (7.0, 8.0)
// (9.0, 10.0)
```

> Codable collections can be useful in situations where you are writing large streams of data that are never partially queried.
> If you only write the data in one pass, and only query the data as the entire set, codable collections might be a good option.

### Transactions

Changes cannot be made to the database except within a transaction.
By default, any command that changes the database will automatically start a transaction if one is not already in effect.
Transactions can also be started manually in SQift when multiple operations need to be run inside a single transaction.

```swift
try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")

try connection.transaction {
    try connection.prepare("INSERT INTO cars VALUES(?, ?, ?)").bind(1, "Audi", 52642).run()
    try connection.prepare("INSERT IN cars VALUES(?, ?, ?)").bind(2, "Mercedes", 57127).run()
}
```

> If any error occurs within the transaction, all the changes are automatically rolled back by SQift.

### Tracing

When debugging SQL statements, sometimes it can be helpful to be able to print out what is actually being executed by SQLite.
SQift allows you to do this through the `traceEvent` API by registering a closure to run for each statement execution.

```swift
let connection = try Connection(storageLocation: storageLocation)

connection.traceEvent { event in
    if case .statement(_, let sql) = sql {
        print(sql)
    }
}

try connection.execute("CREATE TABLE employees(id INTEGER PRIMARY KEY, name TEXT)")
try connection.prepare("INSERT INTO employees VALUES(?, ?)").bind(1, "Bill Bowerman").run()
try connection.prepare("INSERT INTO employees VALUES(?, ?)").bind(2, "Phil Knight").run()
let employees: [Employee] = try connection.query("SELECT * FROM employees")

// Output
// "CREATE TABLE employees(id INTEGER PRIMARY KEY, name TEXT)"
// "INSERT INTO employees VALUES(1, 'Bill Bowerman')"
// "INSERT INTO employees VALUES(2, 'Phil Knight')"
// "SELECT * FROM employees"
```

> The `traceEvent` API allows you to be more selective about the types of statements you want to trace.
> You can select which types of statements you want by using the trace event masks.

### Collations

SQift supports custom collation functions for cases where the three built-in collating functions are not sufficient.
A couple real-world examples of custom cases might include: diacritic aware sorting and numerical sorting.

```swift
let connection = try Connection(storageLocation: storageLocation)

connection.createCollation(named: "NUMERIC") { lhs, rhs in
    return lhs.compare(rhs, options: .numeric, locale: .autoupdatingCurrent)
}

try connection.execute("CREATE TABLE values(text TEXT COLLATE 'NUMERIC' NOT NULL)")

let values = ["string 1", "string 21", "string 12", "string 11", "string 02"]

try values.forEach { try connection.run("INSERT INTO values(text) VALUES(?)", $0) }
let extractedValues: [String] = try connection.query("SELECT * FROM values ORDER BY text")

extractedValues.forEach { print($0) }

// Output
// "string 1"
// "string 02"
// "string 11"
// "string 12"
// "string 21"
```

### Functions

While SQLite is a very robust library, sometimes you will run into cases where you need to extend the functionality of SQLite where it is limited.
For example, you may need to create a custom function to determine what month of a calendar year a particular date falls within.
SQLite cannot do this directly since it lacks calendar support.

SQift supports custom scalar and aggregate functions.
The following is a simple example of how you could extend SQLite to support a `strip_unicode` function.

```swift
try connection.addScalarFunction(named: "strip_unicode", argumentCount: 1) { _, values in
    guard
        let value = values.first, value.isText,
        let valueData = value.text.data(using: .ascii, allowLossyConversion: true),
        let asciiValue = String(data: valueData, encoding: .ascii)
    else { return .null }

    return .text(asciiValue)
}

let sql = "SELECT strip_unicode(?)"

let result1: String? = try connection.prepare(sql, "å").query()
let result2: String? = try connection.prepare(sql, "ć").query()
let result3: String? = try connection.prepare(sql, "áč").query()

// result1 = "a"
// result2 = "c"
// result3 = "ac"
```

> For more advanced examples of scalar and aggregate functions, please refer to the test suite.

---

## Advanced

### Hooks

SQift has support built in for commit, rollback, update, and authorizer hooks.
The commit hook is used to determine whether a commit should be executed or rolled back.
The rollback hook is called when a commit is rolled back.

```swift
var shouldCancelCommit = false

connection.commitHook { return shouldCancelCommit }
connection.rollbackHook { print("rollback occurred") }
```

Update hooks can be used to react to `.insert`, `.update`, or `.delete` operations.

```swift
connection.updateHook { type, databaseName, tableName, rowID in
    var message = "\(type) row \(rowID)"

    if let databaseName = databaseName { message += " on \(databaseName)" }
    if let tableName = tableName { message += ".\(tableName)" }

    print(message)
    
    // Could update the file system, invalidate a cache, send notifications, etc.
}

try connection.execute("""
    INSERT INTO employee(name) VALUES('Phil Knight');
    UPDATE person SET name = 'Bill Bowerman' WHERE id = 1;
    DELETE FROM person WHERE id = 1
    """
)

// Output
// "insert row 1 on main.person"
// "update row 1 on main.person"
// "delete row 1 on main.person"
```

The authorizer hook is the most complex of the four.
It allows you to control what statements are allowed to run on a connection.
For example, you could disable all actions on a particular connection other than select statements.

```swift
try connection.authorizer { action, p1, p2, p3, p4 in
    guard action == .select else { return .deny }
    return .ok
}
```

### Checkpoints

Databases with a `WAL` journal mode use checkpoint operations to move updates from the WAL file into the database.
SQift supports checkpoints and busy timeouts and handlers which can be useful in certain situations.
For example, you may want to use a `WAL` database for performance reasons, then transfer it to a remote server or different device.
Before doing this, it is wise to checkpoint the database and also vacuum it.

```swift
try connection.busyHandler(.timeout(1.0)) // 1 second
let checkpointResult = try connection.checkpoint(mode: .truncate)

try connection.execute("VACUUM")
```

> Checkpointing is a very complex process.
> Before using the `checkpoint` APIs, make sure to read through the SQLite [documentation](https://sqlite.org/c3ref/wal_checkpoint_v2.html).

### Thread Safety

Thread-safety is a complex topic when it comes to SQLite.
As a general rule, it is NEVER safe to access a database `Connection` from multiple threads simultaneously.
Each connection should be accessed serially to guarantee safety. 

If you wish to access the database in parallel, there are a few things you need to know.
First off, you'll need to use Write-Ahead Logging by setting the journal mode to `WAL`.
By changing the database to a `WAL` journal mode, the database can be read during a write and written during a read in parallel using multiple connections.

```swift
try connection.execute("PRAGMA journal_mode = WAL")
```

Another important note is that SQLite can only perform write operations serially, no matter how many connections you create.
Therefore, you should only ever create a single connection for writing if possible.
You can use as many reader connections as you wish.
For more information about thread-safety and WAL journal modes, please refer to the following:

- [Write-Ahead Logging](https://www.sqlite.org/wal.html)
- [SQLite and Multiple Threads](http://www.sqlite.org/threadsafe.html)
- [SQLite WAL mode with multiple transactions in multiple threads](http://stackoverflow.com/questions/14234007/sqlite-wal-mode-with-multiple-transactions-in-multiple-threads)

#### Connection Queue

The `ConnectionQueue` class in SQift was designed to help guarantee thread-safety for a database `Connection` that could be accessed from multiple threads.
It executes all operations on an internal serial dispatch queue.
This ensures all operations on the connection operation in a serial fashion.
The `ConnectionQueue` also supports executing logic inside a transaction and savepoint.

```swift
let queue = try ConnectionQueue(connection: Connection(storageLocation: .onDisk("path_to_db")))

try queue.execute { connection in
    try connection.execute("PRAGMA foreign_keys = true")
    try connection.execute("PRAGMA journal_mode = WAL")
    try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
}

try queue.executeInTransaction { connection in
    try connection.execute("INSERT INTO cars VALUES(1, 'Audi', 52642)")
    try connection.execute("INSERT INTO cars VALUES(2, 'Mercedes', 57127)")
}

try queue.executeInSavepoint("drop_cars_table") { connection in
	try connection.execute("DROP TABLE cars")
}
```

#### Connection Pool

The `ConnectionPool` class allows multiple read-only connections to access a database simultaneously in a thread-safe manner.
Internally, the pool manages two different sets of connections, ones that are available and ones that are currently busy executing SQL logic.
The pool will reuse available connections when they are available, and initializes new connections when all available connections are busy until the max connection count is reached.

```swift
let pool = try ConnectionPool(storageLocation: .onDisk("path_to_db"))

try pool.execute { connection in
    let count: Int = try connection.query("SELECT count(*) FROM cars")
}
```

Since SQLite has no limit on the maximum number of open connections to a single database, the `ConnectionPool` will initialize as many connections as needed within a small amount of time.
Each time a connection is executed, the internal drain delay timer starts up.
When the drain delay timer fires, it will drain the available connections if there are no more busy connections.
If there are still busy connections, the timer is restarted.
This allows the `ConnectionPool` to spin up as many connections as necessary for very small amounts of time.

> The thread-safety is guaranteed by the connection pool by always executing the SQL closure inside a connection queue.
> This ensures all SQL closures executed on the connection are done so in a serial fashion, thus guaranteeing the thread-safety of each connection.

#### Database

The `Database` class is a lightweight way to create a single writable connection queue and connection pool for all read statements.
The read and write APIs are designed to make it simple to execute SQL statements on the appropriate type of `Connection` in a thread-safe manner.

```swift
let database = try Database(storageLocation: .onDisk("path_to_db"))

try database.executeWrite { connection in
    try connection.execute("PRAGMA foreign_keys = true")
    try connection.execute("PRAGMA journal_mode = WAL")
    try connection.execute("CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)")
}

try database.executeRead { connection in
    let count: Int = try connection.query("SELECT count(*) FROM cars")
}
```

This is the easiest way to operate in a 100% thread-safe manner without having to deal with the underlying complexities of the `ConnectionQueue` and `ConnectionPool` classes.

Another important consideration when using the `Database` type is whether or not to use the shared cache.
If you are using a `WAL` journal mode, it is best to set the `sharedCache` parameter to `true`.
This allows the reader pool to have access to the recent changes made by the writer connection at all times.
If you don't use the shared cache, the readers will not always have access to the latest written changes.
This can happen when other long lived read operations are running while changes are being written by a different connection.

> We would like to encourage everyone to use a `Database` object rather than working directly with connection queues or connection pools.

#### Table Lock Policy

Table lock errors are `SQLITE_ERROR` types thrown by `execute`, `prepare`, and `step` operations.
These errors can occur when the database is configured with a WAL journal mode as well as a shared cache.
When one connection has obtained a lock on a table, another connection running on a different thread will receive table lock errors until the previous lock is released.
In these situations, there are a couple of ways to proceed.
The error can either be immediately thrown and handled by the client, or the calling thread can poll the operation until the lock is released.

The `TableLockPolicy` defines two different ways to handle table lock errors.
The first option is to poll on the calling thread at a specified interval until the lock is released.
The other option is to immediately fast fail by throwing the table lock error as soon as it is encountered.
`Connection`, `ConnectionPool`, and `Database` types are set to `.fastFail` by default.

In order to enable polling for table lock errors, all that needs to be done is to set the policy in the `Connection` or `Database` initializer.

```swift
let connection = try Connection(storageLocation: storageLocation, tableLockPolicy: .poll(0.01))
let database = try Database(storageLocation: .onDisk("path_to_db"), tableLockPolicy: .poll(0.01))
```

> When using a WAL journal mode and a shared cache, it is recommended to use a `.poll` table lock policy with a poll interval of `10 ms`. 

### Migrations

Production applications generally need to migrate the database schema from time-to-time.
Whether it requires some new tables or possibly alterations to a table, you need to have a way to manage the migration logic.
SQift has migration support already built-in for you through the `Migrator` class.
All you need to do is create the `Migrator` instance and tell it to run.
Everything else is handled internally by SQift.

```swift
let connection = try Connection(storageLocation: .onDisk("path_to_db"))
let migrator = Migrator(connection: connection, desiredSchemaVersion: 2)

try migrator.runMigrationsIfNecessary(
    migrationSQLForSchemaVersion: { version in
        var SQL: String = ""

        switch version {
        case 1:
            return "CREATE TABLE cars(id INTEGER PRIMARY KEY, name TEXT, price INTEGER)"

        case 2:
            return "CREATE TABLE person(id INTEGER PRIMARY KEY, name TEXT, address TEXT)"

        default:
            break
        }

        return SQL
    },
    willMigrateToSchemaVersion: { version in
        print("Will migrate to schema version: \(version)")
    },
    didMigrateToSchemaVersion: { version in
        print("Did migrate to schema version: \(version)")
    }
)
```

All migrations must start at 1 and increment by 1 with each iteration.
For example, the first time you create a `Migrator`, you want to set the `desiredSchemaVersion` to 1 and implement the `migrationSQLForSchemaVersion` closure to return your initial database schema SQL.
Then, each time you need to migrate your database, bump the `desiredSchemaVersion` by 1 and add the new case to your `migrationSQLForSchemaVersion` schema closure.
In a production application, it would be easiest to write actual SQL files, add them to your bundle and load the SQL string from the file for the required version.

### Backups

It can often be wise to run scheduled backups of your database allowing users to restore from a backup if corruption is detected.
SQift makes it extremely to backup a database safely using the SQLite backup APIs.

```swift
let sourceConnection = try Connection(storageLocation: sourceLocation)
let destinationConnection = try Connection(storageLocation: destinationLocation)

let progress = try sourceConnection.backup(to: destinationConnection) { result in
    print(result)
}
```

The `progress` instance vended by the `backup` API can be used to monitor progress as well as cancel the backup operation.

> The backup operation, by default, happens as an iterative process.
> It backs up the specified page size in each operation until it completes.
> Passing a `pageSize` of `-1` causes the backup to be performed in a single operation.
> It is recommended to use the default `pageSize` of `100` and allow the operation to iterate until complete.

---

## FAQ

### Why not use CoreData?

There are many trade-offs between CoreData and SQift.
SQift was certainly not created as a replacement for CoreData.
It was created to make working with SQLite from Swift as easy and painless as possible.
Anyone trying to decide between using CoreData and using SQift needs to consider the pros and cons carefully before making a decision.
Both have significant learning curves and require significant amounts of forethought and architectural design before being integrated to an application or framework.

### Should I use SQift in my project?

Maybe.
The most important question to ask first is whether you really need a database.
There are many other ways to store data which are much less complicated.
If you do have a large amount of data that needs to be indexed for queries, then a database is probably the best option.

Once you know you need a database, then you need to decide whether you need a key-value store, or full relational query power.
If you only need a key-value store, there are other libraries out there that are less complex and more tailored to your needs.
If you need the full power of SQLite, then SQift is going to be a good option.

### Any plans to add a Swift DSL on top of SQL in SQift?

This is something that we've considered multiple times and haven't dove into yet.
Currently, we do not have any plans to build a DSL, but it's not off the table.
If we do decide to try to add a DSL to SQift, we'll need to make sure we do not remove users too far from SQL.

The main goal of SQift is to make it as easy and convenient as possible to use SQLite with Swift.
Convenience, however, does not mean abstraction.
SQLite is very complicated, and the goal of SQift is not to simplify it, but enable it.
Anyone looking to use SQift in their project needs to have a firm understanding of SQLite and how it works.
This is absolutely by design.

---

## License

SQift is released under the New BSD License.
See LICENSE for details.

## Creators

- [Dave Camp](https://github.com/atomiccat) ([@thinbits](https://twitter.com/thinbits))
- [Christian Noon](https://github.com/cnoon) ([@Christian_Noon](https://twitter.com/Christian_Noon))
