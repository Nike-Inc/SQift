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
    var people: [Person] = [Person]()
    let contactManager = ContactManager()
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        do {
            try(contactManager.openDatabaseAtPath("/tmp/sample-sqift.db"))
            contactManager.insertSampleData { (result) -> Void in
                self.getContacts()
            }
        } catch {
            
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        getContacts()
    }
    
    func getContacts()
    {
        contactManager.allContacts() { people, error in
            guard error == nil, let people = people else {return}
            self.people = people
            self.tableView.reloadData()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return people.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        let person = people[indexPath.row]
        
        cell.textLabel?.text = "\(person)"
        
        return cell
    }
}

