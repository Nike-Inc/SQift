//
//  ViewController.swift
//  sqiftSample
//
//  Created by Dave Camp on 3/15/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import UIKit
import sqift

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let database = sqift("/Users/dave/Desktop/sqift.db")
        if database.open() == .Success
        {
            println("opened database")
            
            let statement = sqiftStatement(database: database, table: "table1")
            while statement.step() == .More
            {
                let a = statement[0] as Int
                let b = statement[1] as String?
                
                println("\(a), \(b!)")
            }
        }
        else
        {
            println("failed to opened database")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

