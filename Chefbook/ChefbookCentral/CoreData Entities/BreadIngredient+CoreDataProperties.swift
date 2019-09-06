//
//  BreadIngredient+CoreDataProperties.swift
//  Chefbook
//
//  Created by Clint Shank on 9/4/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension BreadIngredient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BreadIngredient> {
        return NSFetchRequest<BreadIngredient>(entityName: "BreadIngredient")
    }

    @NSManaged public var weight: Int16
    @NSManaged public var name: String?
    @NSManaged public var isFlour: Bool
    @NSManaged public var percentOfFlour: Int16
    @NSManaged public var index: Int16
    @NSManaged public var recipe: Recipe?

}
