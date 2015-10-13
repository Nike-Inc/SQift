//
//  WeakSet.swift
//  sqift
//
//  Created by Dave Camp on 3/17/15.
//  Copyright (c) 2015 Nike. All rights reserved.
//

import Foundation

private class Weak<T: AnyObject>
{
    weak var value: T?
    
    init(value: T)
    {
        self.value = value
    }
}

public class WeakSet<T: AnyObject>
{
    private var weakObjects = Array<Weak<T>>()
    
    public init()
    {
        
    }

    public func addObject(object: T!)
    {
        compact()
        weakObjects.append(Weak(value: object))
    }
    
    public func removeObject(object: T!)
    {
        weakObjects = weakObjects.filter( { $0.value != nil && $0.value! !== object } )
    }
    
    private func compact()
    {
        weakObjects = weakObjects.filter( { $0.value != nil } )
    }
    
    public func dump()
    {
        print("---")
        if weakObjects.isEmpty
        {
            print("WeakSet is empty")
        }
        else
        {
            for weakObject in weakObjects
            {
                print("\(weakObject.value)")
            }
        }
    }
    
    public func containsObject(object: T!) -> Bool
    {
        compact()

        var result = false
        for weakObject in weakObjects
        {
            if weakObject.value === object
            {
                result = true
                break
            }
        }
        
        return result
    }
    
    public var isEmpty: Bool
    {
        get
        {
            compact()
            return weakObjects.isEmpty
        }
    }
}