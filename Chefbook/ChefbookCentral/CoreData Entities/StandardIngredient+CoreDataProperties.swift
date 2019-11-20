//
//  StandardIngredient+CoreDataProperties.swift
//  Chefbook
//
//  Created by Clint Shank on 11/18/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension StandardIngredient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StandardIngredient> {
        return NSFetchRequest<StandardIngredient>(entityName: "StandardIngredient")
    }

    @NSManaged public var index: Int16
    @NSManaged public var name: String?
    @NSManaged public var amount: String?
    @NSManaged public var recipe: Recipe?

}
