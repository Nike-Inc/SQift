//
//  ViewController.swift
//  sqiftSample
//
//  Created by Dave Camp on 3/15/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import UIKit
import sqift

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    var databaseQueue: DatabaseQueue? = nil
    var people: [Person] = [Person]()

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        databaseQueue = DatabaseQueue(path: "/Users/dave/Desktop/sqift.db")
        databaseQueue?.open()
        insertSampleData()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func insertSampleData()
    {
        databaseQueue?.execute({ database in
            var addData = database.tableExists(Person.tableName) == false || database.numberOfRowsInTable(Person.tableName) == 0
            
            if addData
            {
                let people = [
                    Person(firstName: "Bob", lastName: "Smith", address: "123 Anywhere", zipcode: 79929),
                    Person(firstName: "Jane", lastName: "Doe", address: "111 Blahville", zipcode: 79006)
                ]
                
                // Perform a transaction
                database.transaction( { database in
                
                    var result = database.createTable(Person)
                    
                    if result == .Success
                    {
                        for person in people
                        {
                            result = database.insertRowIntoTable(Person.self, person)
                            if result != .Success
                            {
                                break
                            }
                        }
                    }
                    return .Commit
                })
            }
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        databaseQueue?.execute({ database in
            // Query
            let statement = Statement(database: database, table: Person.tableName, orderByColumnNames: ["lastName"], ascending: true)
            
            var people = statement.objectsForRows(Person)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.people = people
                self.tableView.reloadData()
            })
        })
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
        let person = people[indexPath.row]
        
        cell.textLabel?.text = "\(person)"
        
        return cell
    }
}

