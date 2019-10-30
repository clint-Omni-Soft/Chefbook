//
//  Provision+CoreDataProperties.swift
//  Chefbook
//
//  Created by Clint Shank on 10/29/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension Provision {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Provision> {
        return NSFetchRequest<Provision>(entityName: "Provision")
    }

    @NSManaged public var name: String?
    @NSManaged public var guid: String?
    @NSManaged public var elements: NSSet?

}

// MARK: Generated accessors for elements
extension Provision {

    @objc(addElementsObject:)
    @NSManaged public func addToElements(_ value: ProvisionElement)

    @objc(removeElementsObject:)
    @NSManaged public func removeFromElements(_ value: ProvisionElement)

    @objc(addElements:)
    @NSManaged public func addToElements(_ values: NSSet)

    @objc(removeElements:)
    @NSManaged public func removeFromElements(_ values: NSSet)

}
