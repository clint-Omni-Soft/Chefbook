//
//  ProvisionElement+CoreDataProperties.swift
//  Chefbook
//
//  Created by Clint Shank on 10/29/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension ProvisionElement {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProvisionElement> {
        return NSFetchRequest<ProvisionElement>(entityName: "ProvisionElement")
    }

    @NSManaged public var quantity: Int16
    @NSManaged public var guid: String?
    @NSManaged public var provision: Provision?
    @NSManaged public var recipe: Recipe?

}
