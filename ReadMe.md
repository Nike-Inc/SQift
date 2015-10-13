# README #

## sqift - a lightweight Swift wrapper for SQLite. ##

sqift provides a series of easy to use Swift classes on top of the SQLite C interface, where each layer adds more abstraction from the SQL language and SQLite itself.

There are four main classes in sqift

* `Database`: Represents a single SQLite database and provides basic methods for executing SQL statements. This is the most basic interface to SQLite.
* `Statement`: Represents an SQL query statement. Provides methods for binding parameters and iterating results.
* `Column`: Represents a column in a table. Used with Statements and converting query results into Swift structs or classes.
* `DatabaseQueue`: Represents a serial dispatch queue for executing database transactions in a thread safe manner. Each queue has it's own database instance which is separate from all other instances.

### Usage ###

`import sqift`

### Getting Started ###

```
// Open a database
let database = Database("/path/to/database")
try database.open()

// Create a table
try database.createTable("table1", columns: [ 
		Column(name: "A", type: .Integer), 
		Column(name: "B", type: .String) ])
		
// Execute a simple SQL statement
try database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(42, 'Bob');"

// Execute a custom SQL select and step the results
let statement1 = Statement(database: database, sqlStatement: "SELECT * FROM table1")
while try!(statement1.step()) == .More
{
	// Get the first column
	let value: Int = statement1[0]
	
	// Get the second column
	let name: String = statement1[1]
}

// Execute a basic select statement with no SQL and step the results
let statement2 = Statement(database: database, table: "table1", columnNames: ["A", "B"])
while try!(statement2.step()) == .More
{
	// Get the first column
	let value: Int = statement2[0]
	
	// Get the second column
	let name: String = statement2[1]
}

// Execute a statement that uses parameter binding
let statement3 = Statement(database: database, sqlStatement: "SELECT * FROM table1 WHERE A = ?;")
try statement3.bindParameters(42)
while try!(statement3.step()) == .More
{
	// Get the first column
	let value: Int = statement3[0]
	
	// Get the second column
	let name: String = statement3[1]
}

```

### Interfacing with classes and structs

Types implementing the `DatabaseConvertable` protocol can be directly instantiated from Statement results.

```
extension Person : DatabaseConvertable
{
	// Table name this struct corresponds to
    public static var tableName: String { get { return "people" } }
    
	// Columns in the table this struct will access and their expected types
    public static var columnDefinitions: [Column] { get
        { return [
            Column(name: "firstName", type: .String),
            Column(name: "lastName", type: .String),
            Column(name: "address", type: .String),
            Column(name: "zipcode", type: .Integer) ] }
    }
    
	// Return an array of values in column order. Used when inserting into the table.
    public var columnValues: [Any] { get 
    	{ return [ firstName, lastName, address, zipcode ] } }
    
	// Return an object based on the contents of the current row in the passed statement (or nil).
    public static func objectFromStatement(statement: Statement) -> DatabaseConvertable? {
        // Make sure we have valid data
        guard statement.validateColumnsForObject(Person.self) else { return nil }
        guard let let firstName = statement[0] as String?, let lastName = statement[1] as String?, let address = statement[2] as String? else { return nil }

        let zipcode = statement[3] as Int
        let person = Person(firstName: firstName, lastName: lastName, address: address, zipcode: zipcode)
        
        return person
    }
}
```
With the above extension, you can execute a statement and get back an array of objects.

```
let statement = Statement(database: database, objectClass: Person.self, whereExpression: "zipcode == ?", parameters: zipcode)
let people = try(statement.objectsForRows(Person))

```
Note that there doesn't have to be a 1:1 mapping of object fields to table columns. You could, for example, have a table with 50 columns and define multiple structs that represent various subsets of columns.

### Future Plans ###
At present, sqift's functionality approximates that of FMDB, but with a tasty Swift flavor.

Once sqift's functionality has been expanded and the code proven in Nike applications, the goal is to release it back to the community as Open Source.

Work is being done on the `dsl-wip` branch to turn the full set of SQL expressions used by SQLite into a DSL with full autocompletion in Xcode, thus relieving the user from having to construct SQL expression by hand.

Additional work is needed to improve the marshaling of SQL results into Swift structs and classes.

If you have any great ideas for improving sqift, please let me know. Or, feel free to open pull requests as needed.


### Who do I talk to? ###

* email: dave.camp@nike.com
