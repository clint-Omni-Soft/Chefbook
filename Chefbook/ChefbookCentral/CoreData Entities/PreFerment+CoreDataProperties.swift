//
//  PreFerment+CoreDataProperties.swift
//  Chefbook
//
//  Created by Clint Shank on 10/9/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension PreFerment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PreFerment> {
        return NSFetchRequest<PreFerment>(entityName: "PreFerment")
    }

    @NSManaged public var name: String?
    @NSManaged public var percentOfTotal: Int16
    @NSManaged public var type: Int16
    @NSManaged public var weight: Int64
    @NSManaged public var recipe: Recipe?

}
