# README #

sqift - a lightweight swift wrapper for sqlite.

### Usage ###

There are four main classes in sqift

* `Database`: Represents a single SQLite database and provides basic methods for executing SQL statements.
* `DatabaseQueue`: Represents a serial dispatch queue for executing database transactions in a thread safe manner.
* `Statement`: Represents an SQL query statement. Provides methods for binding parameters and iterating results.
* `Column`: Represents a column in a table. Used with Statements and converting query results into objects.

### Getting Started ###

```
let database = Database("/path/to/database")
try database.open()
try database.createTable("table1", columns: [ 
		Column(name: "A", type: .Integer), 
		Column(name: "B", type: .String) ])
try database.executeSQLStatement("INSERT INTO table1(A, B) VALUES(42, 'Bob');"

let statement1 = Statement(database: database, sqlStatement: "SELECT * FROM table1")
while try!(statement1.step()) == .More
{
	// Get the first column
	let value: Int = statement1[0]
	
	// Get the second column
	let name: String = statement1[1]
}

let statement2 = Statement(database: database, table: "table1", columnNames: ["A", "B"])
while try!(statement2.step()) == .More
{
	// Get the first column
	let value: Int = statement2[0]
	
	// Get the second column
	let name: String = statement2[1]
}

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
    public static var tableName: String { get { return "people" } }
    public static var columnDefinitions: [Column] { get
        { return [
            Column(name: "firstName", type: .String),
            Column(name: "lastName", type: .String),
            Column(name: "address", type: .String),
            Column(name: "zipcode", type: .Integer) ] }
    }
    
    public var columnValues: [Any] { get 
    	{ return [ firstName, lastName, address, zipcode ] } }
    
    public static func objectFromStatement(statement: Statement) -> DatabaseConvertable? {
        // Make sure we have valid data
        guard statement.validateColumnsForObject(Person.self) else { return nil }
        guard let let firstName = statement[0] as String?, let lastName = statement[1] as String?, let address = statement[2] as String? else { return nil }

        let zipcode = statement[3] as Int
        let person = Person(firstName: firstName, lastName: lastName, address: address, zipcode: zipcode)
        
        return person
    }
}

...

let statement = Statement(database: database, objectClass: Person.self, whereExpression: "zipcode == ?", parameters: zipcode)
let people = try(statement.objectsForRows(Person))

```


### Who do I talk to? ###

* email: dave@thinbits.com
* twitter: @thinbits