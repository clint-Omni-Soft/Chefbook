//
//  Recipe+CoreDataProperties.swift
//  Chefbook
//
//  Created by Clint Shank on 9/4/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension Recipe {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Recipe> {
        return NSFetchRequest<Recipe>(entityName: "Recipe")
    }

    @NSManaged public var guid: String?
    @NSManaged public var imageName: String?
    @NSManaged public var ingredients: String?
    @NSManaged public var isFormulaType: Bool
    @NSManaged public var lastModified: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var steps: String?
    @NSManaged public var yield: String?
    @NSManaged public var yieldOptions: String?
    @NSManaged public var formulaYieldQuantity: Int16
    @NSManaged public var formulaYieldWeight: Int16
    @NSManaged public var breadIngredients: NSSet?

}

// MARK: Generated accessors for breadIngredients
extension Recipe {

    @objc(addBreadIngredientsObject:)
    @NSManaged public func addToBreadIngredients(_ value: BreadIngredient)

    @objc(removeBreadIngredientsObject:)
    @NSManaged public func removeFromBreadIngredients(_ value: BreadIngredient)

    @objc(addBreadIngredients:)
    @NSManaged public func addToBreadIngredients(_ values: NSSet)

    @objc(removeBreadIngredients:)
    @NSManaged public func removeFromBreadIngredients(_ values: NSSet)

}
