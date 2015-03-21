//
//  ViewController.swift
//  sqiftSample
//
//  Created by Dave Camp on 3/15/15.
//  Copyright (c) 2015 thinbits. All rights reserved.
//

import UIKit
import sqift
import NamespaceTest

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let database = Database("/Users/dave/Desktop/sqift.db")
        if database.open() == .Success
        {
            println("opened database")
            
            let statement = Statement(database: database, table: "table1")
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
        
//        let sqiftStatement = sqift.Statement(foo: "hello")
//        println("\(sqiftStatement)")
//
//        let testStatement = NamespaceTest.Statement(foo: "hello")
//        println("\(testStatement)")
//        
//        let foo = "hello".sqiftSanitize()
//        println("\(foo)")
}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

