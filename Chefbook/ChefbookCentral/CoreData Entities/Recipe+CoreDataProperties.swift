//
//  Recipe+CoreDataProperties.swift
//  Chefbook
//
//  Created by Clint Shank on 8/2/19.
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
    @NSManaged public var lastModified: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var steps: String?
    @NSManaged public var yield: String?
    @NSManaged public var yieldOptions: String?

}
