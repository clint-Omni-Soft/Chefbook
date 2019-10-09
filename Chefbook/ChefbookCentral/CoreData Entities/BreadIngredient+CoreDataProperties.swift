//
//  BreadIngredient+CoreDataProperties.swift
//  Chefbook
//
//  Created by Clint Shank on 10/8/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension BreadIngredient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BreadIngredient> {
        return NSFetchRequest<BreadIngredient>(entityName: "BreadIngredient")
    }

    @NSManaged public var index: Int16
    @NSManaged public var ingredientType: Int16
    @NSManaged public var name: String?
    @NSManaged public var percentOfFlour: Int16
    @NSManaged public var weight: Int64
    @NSManaged public var recipe: Recipe?
    @NSManaged public var recipeParent: Recipe?

}
