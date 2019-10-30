//
//  Recipe+CoreDataProperties.swift
//  Chefbook
//
//  Created by Clint Shank on 10/29/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension Recipe {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Recipe> {
        return NSFetchRequest<Recipe>(entityName: "Recipe")
    }

    @NSManaged public var formulaYieldQuantity: Int16
    @NSManaged public var formulaYieldWeight: Int64
    @NSManaged public var guid: String?
    @NSManaged public var imageName: String?
    @NSManaged public var ingredients: String?
    @NSManaged public var isFormulaType: Bool
    @NSManaged public var lastModified: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var steps: String?
    @NSManaged public var yield: String?
    @NSManaged public var yieldOptions: String?
    @NSManaged public var breadIngredients: NSSet?
    @NSManaged public var flourIngredients: NSSet?
    @NSManaged public var poolish: Poolish?
    @NSManaged public var preFerment: PreFerment?
    @NSManaged public var provisionElement: NSSet?

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

// MARK: Generated accessors for flourIngredients
extension Recipe {

    @objc(addFlourIngredientsObject:)
    @NSManaged public func addToFlourIngredients(_ value: BreadIngredient)

    @objc(removeFlourIngredientsObject:)
    @NSManaged public func removeFromFlourIngredients(_ value: BreadIngredient)

    @objc(addFlourIngredients:)
    @NSManaged public func addToFlourIngredients(_ values: NSSet)

    @objc(removeFlourIngredients:)
    @NSManaged public func removeFromFlourIngredients(_ values: NSSet)

}

// MARK: Generated accessors for provisionElement
extension Recipe {

    @objc(addProvisionElementObject:)
    @NSManaged public func addToProvisionElement(_ value: ProvisionElement)

    @objc(removeProvisionElementObject:)
    @NSManaged public func removeFromProvisionElement(_ value: ProvisionElement)

    @objc(addProvisionElement:)
    @NSManaged public func addToProvisionElement(_ values: NSSet)

    @objc(removeProvisionElement:)
    @NSManaged public func removeFromProvisionElement(_ values: NSSet)

}
