//
//  Poolish+CoreDataProperties.swift
//  Chefbook
//
//  Created by Clint Shank on 10/9/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension Poolish {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Poolish> {
        return NSFetchRequest<Poolish>(entityName: "Poolish")
    }

    @NSManaged public var percentOfFlour: Int16
    @NSManaged public var percentOfTotal: Int16
    @NSManaged public var percentOfWater: Int16
    @NSManaged public var percentOfYeast: Int16
    @NSManaged public var weight: Int64
    @NSManaged public var recipe: Recipe?

}
