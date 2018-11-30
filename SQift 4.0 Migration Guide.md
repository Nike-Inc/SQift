#  SQift 4.0 Migration Guide

SQift 4.0 is the latest major release of SQift, a lightweight Swift wrapper for SQLite.  As a major release following Semantic Versioning
conventions, 4.0 introduces multiple API-breaking changes that one should be aware of.

This guide is provided in order to ease the transition of existing applications using SQift 3.x to the latest APIs, as well as explain the
design and structure of new and changed functionality.

## Requirements

SQift 4.0 officially supports iOS 10.0+, macOS 10.12+, tvOS 10.0+, watchOS 3.0+, Xcode 9.3+ and Swift 4.1.

## Why a Major Bump?

With the introduction of watchOS 5.0, applications are no longer able to consumer frameworks with a deployment target of less than 3.0.
This exposes SQift's use of APIs that SQlite3 has slated for deprecation.  It seemed best at this point, to bring all deployment targets up
one major revision and fully deprecate the use older APIs.

---

## Breaking API Changes

SQift 4.0 contains a very minor breaking change with how tracing can be performed.

### Event Tracing

With SQlite3's deprecation of the `sqlite3_trace` API, so goes SQift's `Connection.trace()` method.  Instead you must leverage
the `traceEvent` API, which will require a little bit of extra code to achieve your previous results.

In SQift 3.2, you could trace the execution of SQL statements simply with code similar to the following:

```swift
let connection = try Connection(storageLocation: storageLocation)

connection.trace { sql in
    print(sql)
}
```

In SQift 4.0, you will use the `traceEvent()` API, which returns a different type of object internally.  You would write the above example as:

```swift
let connection = try Connection(storageLocation: storageLocation)

connection.traceEvent { event in
    if case .statement(_, let sql) = sql {
        print(sql)
    }
}
```

In addition to this, you can pass a mask into `traceEvent` to restrict which event types are traced.  The default mask is:

```swift
UInt32(SQLITE_TRACE_STMT | SQLITE_TRACE_PROFILE | SQLITE_TRACE_ROW | SQLITE_TRACE_CLOSE)`
```

If you wanted to only trace statements, your code would look like:

```swift
let connection = try Connection(storageLocation: storageLocation)

connection.traceEvent(mask: Connection.TraceEvent.statementMask) { event in
    if case .statement(_, let sql) = sql {
        print(sql)
    }
}
```
