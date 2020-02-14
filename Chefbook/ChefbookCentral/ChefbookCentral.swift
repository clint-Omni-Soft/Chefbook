//
//  ChefbookCentral.swift
//  Chefbook
//
//  Created by Clint Shank on 7/26/19.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit
import CoreData



protocol ChefbookCentralDelegate: class {
    
    func chefbookCentral( chefbookCentral: ChefbookCentral,
                          didOpenDatabase: Bool )
    
    func chefbookCentralDidReloadProvisionArray( chefbookCentral: ChefbookCentral )
    func chefbookCentralDidReloadRecipeArray( chefbookCentral: ChefbookCentral )
}



class ChefbookCentral: NSObject {
    
    // MARK: Public Variables
    weak var delegate:      ChefbookCentralDelegate?

    var didOpenDatabase        = false
    var provisionArray         = [Provision].init()
    var recipeArray            = [Recipe].init()
    var selectedProvisionIndex = NO_SELECTION
    var selectedRecipeIndex    = NO_SELECTION

    
    // MARK: Private Variables
    private let DATABASE_NAME                   = "RecipeDB.sqlite"
    private let DATABASE_MODEL                  = "ChefbookDataModel"
    
    private let ENTITY_NAME_BREAD_INGREDIENT    = "BreadIngredient"
    private let ENTITY_NAME_POOLISH             = "Poolish"
    private let ENTITY_NAME_PRE_FERMENT         = "PreFerment"
    private let ENTITY_NAME_PROVISION           = "Provision"
    private let ENTITY_NAME_PROVISION_ELEMENT   = "ProvisionElement"
    private let ENTITY_NAME_RECIPE              = "Recipe"
    private let ENTITY_NAME_STANDARD_INGREDIENT = "StandardIngredient"

    private var managedObjectContext  : NSManagedObjectContext!
    private var selectedProvisionGuid = ""
    private var selectedRecipeGuid    = ""
    private var persistentContainer   : NSPersistentContainer!

    
    
    // MARK: Our Singleton
    
    static let sharedInstance = ChefbookCentral()        // Prevents anyone else from creating an instance


    
    // MARK: Database Access Methods (Public)
    
    func openDatabase() {
        
        logTrace()
        didOpenDatabase     = false
        recipeArray         = Array.init()
        persistentContainer = NSPersistentContainer( name: DATABASE_MODEL )
        
        persistentContainer.loadPersistentStores( completionHandler:
        { ( storeDescription, error ) in
            
            if let error = error as NSError? {
                logVerbose( "Unresolved error[ %@ ]", error.localizedDescription )
            }
            else {
                self.loadCoreData()
                
                if !self.didOpenDatabase  {  // This is just in case I screw up and don't properly version the data model

                    self.deleteDatabase()
                    self.loadCoreData()
                }

                self.loadExampleRecipesOnFirstTimeIn()
            }
            
            DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.2 ), execute:  {
                
                logVerbose( "didOpenDatabase[ %@ ]", stringFor( self.didOpenDatabase ) )
                self.delegate?.chefbookCentral( chefbookCentral: self,
                                                didOpenDatabase: self.didOpenDatabase )
            } )
            
        } )

    }
    
    
    
    // MARK: Recipe Access/Modifier Methods (Public)
    
    func addBreadIngredientToFormulaRecipeAt( index      : Int,
                                              isFlour    : Bool,
                                              name       : String,
                                              percentage : Int ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %@ ]  index[ %d ]  isFlour[ %@ ]  percentage[ %d ]", name, index, stringFor( isFlour ), percentage )
        
        persistentContainer.viewContext.perform {
            let     recipe          = self.recipeArray[self.selectedRecipeIndex]
            let     breadIngredient = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_BREAD_INGREDIENT, into: self.managedObjectContext ) as! BreadIngredient
            
            breadIngredient.index           = Int16( index )
            breadIngredient.ingredientType  = isFlour ? BreadIngredientTypes.flour : self.typeForIngredientNamed( name )
            breadIngredient.name            = name
            breadIngredient.percentOfFlour  = Int16( percentage )
            breadIngredient.weight          = 0
            
            self.removePoolishFrom( recipe )

            if breadIngredient.ingredientType == BreadIngredientTypes.flour {
                recipe.addToFlourIngredients( breadIngredient )
                
                self.adjustFlourIngredientsPercentagesIn( recipe             : recipe,
                                                          aroundIngredientAt : index )
            }
            else {
                recipe.addToBreadIngredients( breadIngredient )
            }
            
            self.updateBreadFormulaIngredientsIn( recipe )
            self.adjustIngredientsForPoolishIn(   recipe )

            self.saveUpdated( recipe )
        }
        
    }
    
    
    func addFormulaRecipe(_ name : String ) {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %@ ][ %d ][ %d ]", name )
        
        persistentContainer.viewContext.perform {
            let     recipe = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_RECIPE, into: self.managedObjectContext ) as! Recipe
            
            recipe.guid                 = UUID().uuidString
            recipe.isFormulaType        = true
            recipe.lastModified         = NSDate.init()
            recipe.name                 = name
            recipe.formulaYieldQuantity = Int16( 0 )
            recipe.formulaYieldWeight   = Int64( 0 )
            
            self.selectedRecipeGuid = recipe.guid!          // We know this will always be set
            
            self.saveContext()
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func addPoolishToFormulaRecipe( recipe         : Recipe,
                                    percentOfTotal : Int16,
                                    percentOfFlour : Int16,
                                    percentOfWater : Int16,
                                    percentOfYeast : Int16 ) {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        
        persistentContainer.viewContext.perform {
            let     poolish = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_POOLISH, into: self.managedObjectContext ) as! Poolish
            
            poolish.percentOfFlour = percentOfFlour
            poolish.percentOfTotal = percentOfTotal
            poolish.percentOfWater = percentOfWater
            poolish.percentOfYeast = percentOfYeast
            poolish.weight         = Int64( ( Float( recipe.formulaYieldWeight ) * Float( recipe.formulaYieldQuantity ) ) * ( Float( percentOfTotal ) / 100.0 ) )

            recipe.poolish = poolish
            
            self.selectedRecipeGuid = recipe.guid!          // We know this will always be set
            
            self.adjustIngredientsForPoolishIn( recipe )
            
            self.saveContext()
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }


    func addPreFermentToFormulaRecipeWith( name  : String,
                                           type  : Int ) {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %@ ]", name )
        
        persistentContainer.viewContext.perform {
            let     recipe     = self.recipeArray[self.selectedRecipeIndex]
            let     preFerment = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_PRE_FERMENT, into: self.managedObjectContext ) as! PreFerment
            
            preFerment.name  = name
            preFerment.type  = Int16( type )
            
            recipe.preFerment = preFerment
            
            self.selectedRecipeGuid = recipe.guid!          // We know this will always be set
            
            self.saveContext()
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func addProvisionWith(_ name : String ) {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %@ ]", name )
        
        persistentContainer.viewContext.perform {
            let     provision = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_PROVISION, into: self.managedObjectContext ) as! Provision
            
            provision.name  = name
            provision.guid  = UUID().uuidString
            
            self.selectedProvisionGuid = provision.guid!
            
            self.saveContext()
            self.refetchProvisionsAndNotifyDelegate()
        }
        
    }
    
    
    func addProvisionElementTo( provision : Provision,
                                recipe    : Recipe,
                                quantity  : Int ) {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %d ][ %@ ]", quantity, recipe.name ?? "Unknown" )
        
        persistentContainer.viewContext.perform {
            let     element = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_PROVISION_ELEMENT, into: self.managedObjectContext ) as! ProvisionElement
            
            element.guid     = UUID().uuidString
            element.quantity = Int16( quantity )
            element.recipe   = recipe
            
            provision.addToElements( element )
            
            self.saveContext()
            self.refetchProvisionsAndNotifyDelegate()
        }
        
    }
    
    
    func addStandardIngredientTo( recipe : Recipe,
                                  index  : Int,
                                  name   : String,
                                  amount : String ) {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %@ ][ %@ ]", name, amount )
        
        persistentContainer.viewContext.perform {
            let     ingredient = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_STANDARD_INGREDIENT, into: self.managedObjectContext ) as! StandardIngredient
            
            ingredient.index  = Int16( index )
            ingredient.name   = name
            ingredient.amount = amount
            
            recipe.addToStandardIngredients( ingredient )
            
            self.selectedRecipeGuid = recipe.guid!
            
            self.saveContext()
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func addStandardRecipe(_ name : String ) {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %@ ]", name )
        
        persistentContainer.viewContext.perform {
            let     recipe = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_RECIPE, into: self.managedObjectContext ) as! Recipe
            
            recipe.guid             = UUID().uuidString
            recipe.isFormulaType    = false
            recipe.lastModified     = NSDate.init()
            recipe.name             = name
            
            self.selectedRecipeGuid = recipe.guid!          // We know this will always be set
            
            self.saveContext()
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func adjustFlourIngredientsPercentagesIn( recipe                   : Recipe,
                                              aroundIngredientAt index : Int ) {
        logTrace()
        var     existingPercentageTotal = 0
        let     flourIngredientsArray   = recipe.flourIngredients?.allObjects as! [BreadIngredient]
        var     updatedPercentOfFlour   = 0
        
        // Populate our variables
        for ingredient in flourIngredientsArray {
            
            if ingredient.index == index {
                updatedPercentOfFlour = Int( ingredient.percentOfFlour )
            }
            else {
                existingPercentageTotal += Int( ingredient.percentOfFlour )
            }
            
        }
        
        var     totalAdjustedPercentage = 100 - updatedPercentOfFlour
        let     scalingFactor           = ( Float( totalAdjustedPercentage ) / Float( existingPercentageTotal ) )
        
        // Now we remove each ingredient, adjust its percentage and then add it back to the recipe
        for ingredient in flourIngredientsArray {
            
            if ingredient.index != index  {      // We want to change the percentage of the everything except the one we just updated

                ingredient.percentOfFlour = Int16( round( Float( ingredient.percentOfFlour ) * scalingFactor ) )
                totalAdjustedPercentage  -= Int( ingredient.percentOfFlour )
                
                recipe.removeFromFlourIngredients( ingredient )
                recipe.addToFlourIngredients( ingredient )
            }
            
        }
        
        // Now we guarantee that the total will always be 100
        if totalAdjustedPercentage != 0 && flourIngredientsArray.count != 0 {
            
            let ingredient = flourIngredientsArray[0]
            
            recipe.removeFromFlourIngredients( ingredient )
            
            ingredient.percentOfFlour += Int16( totalAdjustedPercentage )
            recipe.addToFlourIngredients( ingredient )
        }
        
    }
    
    
    func deleteFormulaRecipeBreadIngredientAt(_ index : Int ) {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %d ]", index )
        
        persistentContainer.viewContext.perform {
            let     recipe                = self.recipeArray[self.selectedRecipeIndex]
            let     breadIngredientsArray = recipe.breadIngredients?.allObjects as! [BreadIngredient]
            
                // First we sort the ingredients by their index value
            var sortedBreadIngredientsArray = breadIngredientsArray.sorted( by:
                { (ingredient1, ingredient2) -> Bool in
                
                    ingredient1.index < ingredient2.index
                })

            self.removePoolishFrom( recipe )
            
            recipe.removeFromBreadIngredients( sortedBreadIngredientsArray[index] )
            sortedBreadIngredientsArray.remove( at: index )
            
            // Now we need to renumber all the indexes and update the store with our sorted & renumbered array
            for i in 0..<sortedBreadIngredientsArray.count {
                
                recipe.removeFromBreadIngredients( sortedBreadIngredientsArray[i] )

                sortedBreadIngredientsArray[i].index = Int16( i )
                recipe.addToBreadIngredients(sortedBreadIngredientsArray[i] )
            }
            
            self.updateBreadFormulaIngredientsIn( recipe )
            self.adjustIngredientsForPoolishIn(   recipe )
            
            self.saveUpdated( recipe )
        }

    }
    
    
    func deleteFormulaRecipeFlourIngredientAt(_ index : Int ) {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %d ]", index )
        
        persistentContainer.viewContext.perform {
            let     recipe                = self.recipeArray[self.selectedRecipeIndex]
            let     flourIngredientsArray = recipe.flourIngredients?.allObjects as! [BreadIngredient]
            
            // First we sort the ingredients by their index value
            var sortedFlourIngredientsArray = flourIngredientsArray.sorted( by:
            { (ingredient1, ingredient2) -> Bool in
                
                ingredient1.index < ingredient2.index
            })
            
            self.removePoolishFrom( recipe )
            
            recipe.removeFromFlourIngredients( sortedFlourIngredientsArray[index] )
            sortedFlourIngredientsArray.remove( at: index )
            
            // Now we need to renumber all the indexes and update the store with our sorted & renumbered array
            for i in 0..<sortedFlourIngredientsArray.count {
                
                recipe.removeFromFlourIngredients( sortedFlourIngredientsArray[i] )
                
                sortedFlourIngredientsArray[i].index = Int16( i )
                recipe.addToFlourIngredients( sortedFlourIngredientsArray[i] )
            }
            
            self.updateBreadFormulaIngredientsIn( recipe )
            self.adjustIngredientsForPoolishIn(   recipe )
            
            self.saveUpdated( recipe )
        }
        
    }
    
    
    func deleteFormulaRecipePoolish() {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        
        persistentContainer.viewContext.perform {
            let     recipe = self.recipeArray[self.selectedRecipeIndex]
            
            self.removePoolishFrom( recipe )
            recipe.poolish = nil

            self.saveUpdated( recipe )
        }
        
    }
    
    
    func deleteFormulaRecipePreFerment() {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        
        persistentContainer.viewContext.perform {
            let     recipe = self.recipeArray[self.selectedRecipeIndex]
            
            recipe.preFerment = nil
            
            self.saveUpdated( recipe )
        }
        
    }
    
    
    func deleteProvisionAtIndex(_ index: Int ) {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        persistentContainer.viewContext.perform {
            logVerbose( "deleting provision at [ %d ]", index )
            let     provision = self.provisionArray[index]
            
            self.managedObjectContext.delete( provision )
            
            self.saveContext()
            self.refetchProvisionsAndNotifyDelegate()
        }
        
    }
    
    
    func deleteProvisionElementFrom( provision : Provision,
                                     with guid : String ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        
        persistentContainer.viewContext.perform {
            let     provisionElements = provision.elements?.allObjects as! [ProvisionElement]
            
            for element in provisionElements {
                if element.guid == guid {
                    provision.removeFromElements( element )
                    break
                }
                
            }
            
            self.saveUpdatedProvision( provision )
        }
        
    }
    
    
    func deleteRecipeAtIndex(_ index: Int ) {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        persistentContainer.viewContext.perform {
            logVerbose( "deleting recipe at [ %d ]", index )
            let     recipe = self.recipeArray[index]
            
            self.managedObjectContext.delete( recipe )
            
            self.saveContext()
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func deleteStandardIngredientFrom( recipe     : Recipe,
                                       with index : Int ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        
        persistentContainer.viewContext.perform {
            var     standardIngredients = self.sortedStandardIngredientsFrom( recipe )
            var     indexOfDeletedItem  = 0
            var     newIndex : Int16    = 0

            // First we iterate through the array and remove the requested item
            for ingredient in standardIngredients {
                
                if ingredient.index == index {
                    recipe.removeFromStandardIngredients( ingredient )
                    break
                }
                
                indexOfDeletedItem += 1
            }
            
            standardIngredients.remove( at: indexOfDeletedItem )
            
            // Then we renumber their indexes to ensure they are sequential
            for ingredient in standardIngredients {
                
                ingredient.index = newIndex
                newIndex += 1
            }
            
            self.saveUpdated( recipe )
        }
        
    }
    
    
    private func sortedStandardIngredientsFrom(_ recipe : Recipe ) -> [StandardIngredient] {
        let     standardIngredients = recipe.standardIngredients?.allObjects as! [StandardIngredient]
        let     sortedIngredientArray = standardIngredients.sorted( by:
            { (ingredient1, ingredient2) -> Bool in
                
                ingredient1.name! < ingredient2.name!     // We can do this because the name is a required field that must be unique
        } )
        
        return sortedIngredientArray
    }
    
    
    func fetchProvisions() {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        
        persistentContainer.viewContext.perform {
            self.refetchProvisionsAndNotifyDelegate()
        }
        
    }
    
    
    func fetchRecipes() {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        
        persistentContainer.viewContext.perform {
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func saveUpdatedProvision(_ provision: Provision ) {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        
        selectedProvisionGuid = provision.guid!       // We know this will always have been set
        
        persistentContainer.viewContext.perform {
            self.saveContext()
            self.refetchProvisionsAndNotifyDelegate()
        }
        
    }
    
    
    func saveUpdated(_ recipe: Recipe ) {
        
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()

        selectedRecipeGuid = recipe.guid!       // We know this will always have been set
        
        persistentContainer.viewContext.perform {
            self.saveContext()
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func updateBreadFormulaIngredientsIn(_ recipe: Recipe ) {
        
        logTrace()
        let     breadIngredientsArray = recipe.breadIngredients?.allObjects as! [BreadIngredient]
        let     flourIngredientsArray = recipe.flourIngredients?.allObjects as! [BreadIngredient]
        var     totalPercentage       = 100 // We start with the fixed percentage of flour

        // Add all of the bread percentages to the flour percentage
        for ingredient in breadIngredientsArray {
            totalPercentage += Int( ingredient.percentOfFlour )
        }
        
        let     totalYieldWeight = Float( recipe.formulaYieldQuantity ) * Float( recipe.formulaYieldWeight )
        let     onePercent       = totalYieldWeight / Float( totalPercentage )
        
        // Now we assign new computed weights for the current yield for all of the ingredients
        for flourIngredient in flourIngredientsArray {
            
            recipe.removeFromFlourIngredients( flourIngredient )
            
            flourIngredient.weight = Int64( round( Float( flourIngredient.percentOfFlour ) * onePercent ) )
            recipe.addToFlourIngredients( flourIngredient )
        }
        
        for breadIngredient in breadIngredientsArray {
            
            recipe.removeFromBreadIngredients( breadIngredient )
            
            breadIngredient.weight = Int64( round( Float( breadIngredient.percentOfFlour ) * onePercent ) )
            recipe.addToBreadIngredients( breadIngredient )
        }
        
    }
    
    

    // MARK: Image Convenience Methods (Public)
    
    func deleteImageWith(_ name: String ) -> Bool {
//        logTrace()
        let         directoryPath = pictureDirectoryPath()
        
        if !directoryPath.isEmpty {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )


            do {
                try FileManager.default.removeItem( at: imageFileURL )
                
                logVerbose( "deleted image named [ %@ ]", name )
                return true
            }
                
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to delete image named [ %@ ] ... Error[ %@ ]", name, error.localizedDescription )
            }
            
        }
        
        return false
    }
    
    
    func imageWith(_ name: String ) -> UIImage {
        
//        logTrace()
        let         directoryPath = pictureDirectoryPath()
        
        if !directoryPath.isEmpty {
            
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )
            let     imageFileData        = FileManager.default.contents( atPath: imageFileURL.path )
            
            
            if let imageData = imageFileData {
                
                if let image = UIImage.init( data: imageData ) {
//                    logVerbose( "Loaded image named [ %@ ]", name )
                    return image
                }
                
            }
            else {
                logVerbose( "ERROR!  Failed to load data for image [ %@ ]", name )
            }
            
        }
        else {
            logVerbose( "ERROR!  directoryPath is Empty!" )
        }
        
        return UIImage.init()
    }
    
    
    func saveImage(_ image: UIImage ) -> String {
        
//        logTrace()
        let         directoryPath = pictureDirectoryPath()
        
        if directoryPath.isEmpty {
            return String.init()
        }
        
        let     imageFilename        = UUID().uuidString
        let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
        let     pictureFileURL       = picturesDirectoryURL.appendingPathComponent( imageFilename )
        
        guard let imageData = image.jpegData( compressionQuality: 1 ) ?? image.pngData() else {
            logTrace( "ERROR!  Could NOT convert UIImage to Data!" )
            return String.init()
        }
        
        do {
            try imageData.write( to: pictureFileURL, options: .atomic )
            
            logVerbose( "Saved image to file named[ %@ ]", imageFilename )
            return imageFilename
        }
            
        catch let error as NSError {
            logVerbose( "ERROR!  Failed to save image for [ %@ ] ... Error[ %@ ]", imageFilename, error.localizedDescription )
        }
        
        return String.init()
    }
    
    

    // MARK: Utility Methods
    
    private func adjustIngredientsForPoolishIn(_ recipe : Recipe ) {
        
        if recipe.poolish == nil {
            logTrace( "No poolish in this recipe ... do nothing" )
            return
        }
        
        logTrace()
        let reductionPercentage = 100 - ( recipe.poolish?.percentOfTotal ?? 1 )

        if recipe.flourIngredients != nil {
            let flourIngredients = recipe.flourIngredients?.allObjects  as! [BreadIngredient]

            for ingredient in flourIngredients {
                ingredient.weight = Int64( round( ( Float( ingredient.weight) * Float( reductionPercentage ) ) / 100.0 ) )
            }
            
        }
        
        if recipe.breadIngredients != nil {
            let breadIngredients = recipe.breadIngredients?.allObjects as! [BreadIngredient]
            
            for ingredient in breadIngredients {
                
                if ingredient.ingredientType == BreadIngredientTypes.water {
                    ingredient.weight = Int64( round( ( Float( ingredient.weight) * Float( reductionPercentage ) ) / 100.0 ) )
                }
                else if ingredient.ingredientType == BreadIngredientTypes.yeast {
                    ingredient.weight = Int64( round( ( Float( ingredient.weight) * Float( reductionPercentage ) ) / 100.0 ) )
                }
                
            }
            
        }

    }
    
    
    private func deleteDatabase() {
        
        guard let docURL = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).last else {
            logTrace( "Error!  Unable to resolve document directory" )
            return
        }
        
        let     storeURL = docURL.appendingPathComponent( DATABASE_NAME )
        
        do {
            try FileManager.default.removeItem( at: storeURL )
            logVerbose( "deleted database @ [ %@ ]", storeURL.path )
        }
        
        catch {
            let     nsError = error as NSError
            
            logVerbose( "Error!  Unable delete store! ... Error[ %@ ]", nsError.localizedDescription )
        }
        
    }
    
    
    private func fetchAllProvisionObjects() {   // Must be called from within persistentContainer.viewContext
        
        selectedProvisionIndex = NO_SELECTION

        do {
            let     request : NSFetchRequest<Provision> = Provision.fetchRequest()
            let     fetchedProvisions = try managedObjectContext.fetch( request )
            
            provisionArray = fetchedProvisions.sorted( by:
                { (provision1, provision2) -> Bool in
                    
                    provision1.name! < provision2.name!     // We can do this because the name is a required field that must be unique
            } )
            
            for index in 0 ..< self.provisionArray.count {
                
                if provisionArray[index].guid == selectedProvisionGuid {
                    selectedProvisionIndex = index
                    break
                }
                
            }
            
        }
            
        catch {
            provisionArray = [Provision]()
            logTrace( "Error!  Fetch failed!" )
        }

    }
    
    
    private func fetchAllRecipeObjects() {      // Must be called from within persistentContainer.viewContext

        selectedRecipeIndex = NO_SELECTION

        do {
            let     request : NSFetchRequest<Recipe> = Recipe.fetchRequest()
            let     fetchedRecipes = try managedObjectContext.fetch( request )
            
            recipeArray = fetchedRecipes.sorted( by:
                        { (recipe1, recipe2) -> Bool in
                    
                            recipe1.name! < recipe2.name!     // We can do this because the name is a required field that must be unique
                        } )
            
            for index in 0 ..< self.recipeArray.count {
                
                if recipeArray[index].guid == selectedRecipeGuid {
                    selectedRecipeIndex = index
                    break
                }
                
            }
            
        }
            
        catch {
            recipeArray = [Recipe]()
            logTrace( "Error!  Fetch failed!" )
        }
        
    }
    
    
    private func loadCoreData() {
        
        guard let modelURL = Bundle.main.url( forResource: DATABASE_MODEL, withExtension: "momd" ) else {
            logTrace( "Error!  Could NOT load model from bundle!" )
            return
        }
        
        logVerbose( "modelURL[ %@ ]", modelURL.path )

        guard let managedObjectModel = NSManagedObjectModel( contentsOf: modelURL ) else {
            logVerbose( "Error!  Could NOT initialize managedObjectModel from URL[ %@ ]", modelURL.path )
            return
        }
        
        let     persistentStoreCoordinator = NSPersistentStoreCoordinator( managedObjectModel: managedObjectModel )
    
        managedObjectContext = NSManagedObjectContext( concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType )
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        guard let docURL = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).last else {
            logTrace( "Error!  Unable to resolve document directory!" )
            return
        }
        
        let     storeURL = docURL.appendingPathComponent( DATABASE_NAME )
        
        logVerbose( "storeURL[ %@ ]", storeURL.path )

        do {
            try persistentStoreCoordinator.addPersistentStore( ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil )
            
            self.didOpenDatabase = true
//            logTrace( "added Recipes store to coordinator" )
        }
            
        catch {
            let     nsError = error as NSError
            
            logVerbose( "Error!  Unable migrate store[ %@ ]", nsError.localizedDescription )
        }
        
    }
    
    
    private func loadExampleRecipesOnFirstTimeIn() {
        
        let userDefaults = UserDefaults.standard
        let dirtyFlag    = userDefaults.bool( forKey: "Dirty" )
        
        logVerbose( "dirtyFlag[ %@ ]", stringFor( dirtyFlag ) )
        
        if !dirtyFlag {
            
            userDefaults.set( true, forKey: "Dirty" )
            
            if recipeArray.count > 0 {
                return
            }
            
            self.persistentContainer.viewContext.perform {
                let     recipe = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_RECIPE, into: self.managedObjectContext ) as! Recipe
                
                recipe.guid          = UUID().uuidString
                recipe.isFormulaType = false
                recipe.lastModified  = NSDate.init()
                recipe.name          = "Crispy Bacon"
                recipe.steps         = "Fry until crispy\nDrain on paper towels\nSprinkle with Parmesan"
                recipe.yield         = Int16( 12 )
                recipe.yieldWeight   = Int64( 25 )
                
                self.selectedRecipeGuid = recipe.guid!          // We know this will always be set
                
                let     ingredient = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_STANDARD_INGREDIENT, into: self.managedObjectContext ) as! StandardIngredient
                
                ingredient.index  = 0
                ingredient.name   = "Smoked Bacon"
                ingredient.amount = "1 lb."
                
                recipe.addToStandardIngredients( ingredient )
                
                self.saveContext()
            }
            
        }
        
    }
    
    
    private func pictureDirectoryPath() -> String {
        
        let         fileManager = FileManager.default
        
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            
            let     picturesDirectoryURL = documentDirectoryURL.appendingPathComponent( "RecipePictures" )
            
            if !fileManager.fileExists( atPath: picturesDirectoryURL.path ) {
                
                do {
                    try fileManager.createDirectory( atPath: picturesDirectoryURL.path, withIntermediateDirectories: true, attributes: nil )
                }
                    
                catch let error as NSError {
                    logVerbose( "ERROR!  Failed to create photos directory ... Error[ %@ ]", error.localizedDescription )
                    return String.init()
                }
                
            }
            
            if !fileManager.fileExists( atPath: picturesDirectoryURL.path ) {
                logTrace( "ERROR!  photos directory does NOT exist!" )
                return String.init()
            }
            
//            logVerbose( "picturesDirectory[ %@ ]", picturesDirectoryURL.path )
            return picturesDirectoryURL.path
        }
        
//        logTrace( "ERROR!  Could NOT find the documentDirectory!" )
        return String.init()
    }
    
    
    private func refetchProvisionsAndNotifyDelegate() {     // Must be called from within a persistentContainer.viewContext
        
        fetchAllProvisionObjects()
        
        DispatchQueue.main.async {
            self.delegate?.chefbookCentralDidReloadProvisionArray( chefbookCentral: self )
        }
        
    }
    
    
    private func refetchRecipesAndNotifyDelegate() {        // Must be called from within a persistentContainer.viewContext
    
        fetchAllRecipeObjects()
        
        DispatchQueue.main.async {
            self.delegate?.chefbookCentralDidReloadRecipeArray( chefbookCentral: self )
        }

        if .pad == UIDevice.current.userInterfaceIdiom {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: NOTIFICATION_RECIPES_UPDATED ), object: self )
        }

    }
    

    private func removePoolishFrom(_ recipe : Recipe ) {
        if recipe.poolish == nil {
            logTrace( "No poolish in this recipe ... do nothing" )
            return
        }
        
        logTrace()

        let reductionPercentage = 100 - ( recipe.poolish?.percentOfTotal ?? 1 )

        if recipe.flourIngredients != nil {
            let flourIngredients = recipe.flourIngredients?.allObjects  as! [BreadIngredient]
            
            for ingredient in flourIngredients {
                ingredient.weight = Int64( round( 100.0 * ( Float( ingredient.weight ) / Float( reductionPercentage ) ) ) )
            }
            
        }
        
        if recipe.breadIngredients != nil {
            let breadIngredients = recipe.breadIngredients?.allObjects as! [BreadIngredient]
            
            for ingredient in breadIngredients {
                
                if ingredient.ingredientType == BreadIngredientTypes.water {
                    ingredient.weight = Int64( round( 100.0 * ( Float( ingredient.weight ) / Float( reductionPercentage ) ) ) )
                }
                else if ingredient.ingredientType == BreadIngredientTypes.yeast {
                    ingredient.weight = Int64( round( 100.0 * ( Float( ingredient.weight ) / Float( reductionPercentage ) ) ) )
                }
                
            }
            
        }
        
    }
    
    
    private func typeForIngredientNamed(_ name : String ) -> Int16 {
        var     ingredientType = BreadIngredientTypes.other
        let     myName         = name.uppercased().trimmingCharacters(in: .whitespaces )
        
        // We don't check for flour because we know coming in whether or not it is a flour
        if myName.contains( NSLocalizedString( "IngredientType.Water", comment: "Water" ).uppercased() ) || myName.contains( "H2O" ) {
            ingredientType = BreadIngredientTypes.water
        }
        else if myName.contains( NSLocalizedString( "IngredientType.Yeast", comment: "Yeast" ).uppercased() ) {
            ingredientType = BreadIngredientTypes.yeast
        }

        return ingredientType
    }
    
    
    private func saveContext() {
        
        if managedObjectContext.hasChanges {
            
            do {
                try managedObjectContext.save()
            }
                
            catch {
                let     nsError = error as NSError
                
                logVerbose( "Unresolved error[ %@ ]", nsError.localizedDescription )
            }
            
        }
        
    }
    
    
}



// MARK: Public Definitions & Utility Methods

struct BreadIngredientTypes {
    static let flour = Int16( 0 )
    static let water = Int16( 1 )
    static let yeast = Int16( 2 )
    static let other = Int16( 3 )
}

struct ForumlaTableSections {
    static let nameAndYield = 0
    static let flour        = 1
    static let ingredients  = 2
    static let preFerment   = 3
    static let none         = 4
}

struct PreFermentTypes {
    static let biga    = 0
    static let poolish = 1
    static let sour    = 2
}


let     NEW_INGREDIENT                  = -4
let     NEW_PROVISION                   = -3
let     NEW_RECIPE                      = -2
let     NO_SELECTION                    = -1
let     NOTIFICATION_RECIPE_SELECTED    = "RecipeSelected"
let     NOTIFICATION_RECIPES_UPDATED    = "RecipesUpdated"
let     groupedTableViewBackgroundColor = UIColor.init( red: 239/255, green: 239/255, blue: 244/255, alpha: 1.0 )



func viewControllerWithStoryboardId( storyboardId: String ) -> UIViewController {
    
    logVerbose( "[ %@ ]", storyboardId )
    let     storyboardName = ( ( .pad == UIDevice.current.userInterfaceIdiom ) ? "Main_iPad" : "Main_iPhone" )
    let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
    let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
    
    
    return viewController
}


func iPhoneViewControllerWithStoryboardId( storyboardId: String ) -> UIViewController {
    
    logVerbose( "[ %@ ]", storyboardId )
    let     storyboardName = "Main_iPhone"
    let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
    let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
    
    
    return viewController
}


