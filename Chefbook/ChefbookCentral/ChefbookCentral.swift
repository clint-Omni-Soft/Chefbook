//
//  ChefbookCentral.swift
//  Chefbook
//
//  Created by Clint Shank on 7/26/19.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit
import CoreData



protocol ChefbookCentralDelegate: class
{
    func chefbookCentral( chefbookCentral: ChefbookCentral,
                          didOpenDatabase: Bool )
    
    func chefbookCentralDidReloadRecipeArray( chefbookCentral: ChefbookCentral )
}



class ChefbookCentral: NSObject
{
    // MARK: Public Variables
    weak var delegate:      ChefbookCentralDelegate?

    var didOpenDatabase       = false
    var recipeArray           = [Recipe].init()
    var selectedRecipeIndex   = NO_SELECTION

    
    // MARK: Private Variables
    private let DATABASE_NAME                = "RecipeDB.sqlite"
    private let ENTITY_NAME_RECIPE           = "Recipe"
    private let ENTITY_NAME_BREAD_INGREDIENT = "BreadIngredient"
    
    private var managedObjectContext : NSManagedObjectContext!
    private var selectedRecipeGuid   = ""
    private var persistentContainer  : NSPersistentContainer!

    
    
    // MARK: Our Singleton
    
    static let sharedInstance = ChefbookCentral()        // Prevents anyone else from creating an instance


    
    // MARK: Database Access Methods (Public)
    
    func openDatabase()
    {
        logTrace()
        didOpenDatabase     = false
        recipeArray         = Array.init()
        persistentContainer = NSPersistentContainer( name: "ChefbookDataModel" )
        
        persistentContainer.loadPersistentStores( completionHandler:
        { ( storeDescription, error ) in
            
            if let error = error as NSError?
            {
                logVerbose( "Unresolved error[ %@ ]", error.localizedDescription )
            }
            else
            {
                self.loadCoreData()
                
                if !self.didOpenDatabase    // This is just in case I screw up and don't properly version the data model
                {
                    self.deleteDatabase()
                    self.loadCoreData()
                }

            }
            
            DispatchQueue.main.async
            {
                logVerbose( "didOpenDatabase[ %@ ]", stringFor( self.didOpenDatabase ) )
                self.delegate?.chefbookCentral( chefbookCentral: self,
                                                didOpenDatabase: self.didOpenDatabase )
            }
            
        } )

    }
    
    
    
    // MARK: Recipe Access/Modifier Methods (Public)
    
    func addRecipe( name            : String,
                    imageName       : String,
                    ingredients     : String,
                    isFormulaType   : Bool,
                    steps           : String,
                    yield           : String,
                    yieldOptions    : String )
    {
        if !self.didOpenDatabase
        {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %@ ][ %@ ][ %@ ]", name, ingredients, steps )

        persistentContainer.viewContext.perform
        {
            let     recipe = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_RECIPE, into: self.managedObjectContext ) as! Recipe
            
            
            recipe.guid             = UUID().uuidString
            recipe.imageName        = imageName
            recipe.ingredients      = ingredients
            recipe.isFormulaType    = isFormulaType
            recipe.lastModified     = NSDate.init()
            recipe.name             = name
            recipe.steps            = steps
            recipe.yield            = yield
            recipe.yieldOptions     = yieldOptions

            self.selectedRecipeGuid = recipe.guid!          // We know this will always be set
            
            self.saveContext()
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func addFormulaRecipe( name          : String,
                           yieldQuantity : Int,
                           yieldWeight   : Int )
    {
        if !self.didOpenDatabase
        {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %@ ][ %d ][ %d ]", name, yieldQuantity, yieldWeight )

        persistentContainer.viewContext.perform
        {
            let     recipe = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_RECIPE, into: self.managedObjectContext ) as! Recipe
            
            
            recipe.guid                 = UUID().uuidString
            recipe.isFormulaType        = true
            recipe.lastModified         = NSDate.init()
            recipe.name                 = name
            recipe.formulaYieldQuantity = Int16( yieldQuantity )
            recipe.formulaYieldWeight   = Int16( yieldWeight   )
            
            self.selectedRecipeGuid = recipe.guid!          // We know this will always be set

            self.saveContext()
            self.refetchRecipesAndNotifyDelegate()
        }

    }
    
    
    func addIngredientToFormulaRecipeWith( index      : Int,
                                           name       : String,
                                           isFlour    : Bool,
                                           percentage : Int,
                                           weight     : Int )
    {
        if !self.didOpenDatabase
        {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %@ ] @[ %d ] p[ %d ] w[ %d ] isFlour[ %@ ]", name, index, percentage, weight, stringFor( isFlour ) )
        
        persistentContainer.viewContext.perform
        {
            let     recipe          = self.recipeArray[self.selectedRecipeIndex]
            let     breadIngredient = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_BREAD_INGREDIENT, into: self.managedObjectContext ) as! BreadIngredient
            
            
            breadIngredient.index           = Int16( index )
            breadIngredient.isFlour         = isFlour
            breadIngredient.name            = name
            breadIngredient.percentOfFlour  = Int16( percentage )
            breadIngredient.weight          = Int16( weight     )
            
            recipe.addToBreadIngredients( breadIngredient )
            
            self.saveUpdatedRecipe( recipe: recipe )
        }
        
    }
    
    
    func deleteFormulaRecipeIngredientAt( index : Int )
    {
        if !self.didOpenDatabase
        {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %d ]", index )
        
        persistentContainer.viewContext.perform
        {
            let     recipe           = self.recipeArray[self.selectedRecipeIndex]
            let     ingredientsArray = recipe.breadIngredients?.allObjects as! [BreadIngredient]
            
            
                // First we sort the ingredients by their index value
            var sortedIngredientsArray = ingredientsArray.sorted( by:
                { (ingredient1, ingredient2) -> Bool in
                
                    ingredient1.index < ingredient2.index
                })
            

            recipe.removeFromBreadIngredients( sortedIngredientsArray[index] )
            sortedIngredientsArray.remove( at: index )
            
            if recipe.breadIngredients?.count != 0
            {
                // Now we need to renumber all the indexes and update the store with our sorted & renumbered array
                for i in 0..<sortedIngredientsArray.count
                {
                    sortedIngredientsArray[i].index = Int16( i )
                    recipe.removeFromBreadIngredients( sortedIngredientsArray[i] )
                    recipe.addToBreadIngredients(      sortedIngredientsArray[i] )
                }

            }
            
            self.saveUpdatedRecipe( recipe: recipe )
        }

    }
    
    
    func deleteRecipeAtIndex( index: Int )
    {
        if !self.didOpenDatabase
        {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        persistentContainer.viewContext.perform
        {
            logVerbose( "deleting recipe at [ %d ]", index )
            let     recipe = self.recipeArray[index]
            
            
            self.managedObjectContext.delete( recipe )
            
            self.saveContext()
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func fetchRecipes()
    {
        if !self.didOpenDatabase
        {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        
        persistentContainer.viewContext.perform
        {
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    
    
    func saveUpdatedRecipe( recipe: Recipe )
    {
        if !self.didOpenDatabase
        {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()

        selectedRecipeGuid = recipe.guid!       // We know this will always have been set
        
        persistentContainer.viewContext.perform
        {
            self.saveContext()
            self.refetchRecipesAndNotifyDelegate()
        }
        
    }
    
    
    
    // MARK: Image Convenience Methods (Public)
    
    func deleteImageWith( name: String ) -> Bool
    {
//        logTrace()
        let         directoryPath = pictureDirectoryPath()
        
        
        if !directoryPath.isEmpty
        {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )


            do
            {
                try FileManager.default.removeItem( at: imageFileURL )
                
                logVerbose( "deleted image named [ %@ ]", name )
                return true
            }
                
            catch let error as NSError
            {
                logVerbose( "ERROR!  Failed to delete image named [ %@ ] ... Error[ %@ ]", name, error.localizedDescription )
            }
            
        }
        
        return false
    }
    
    
    func imageWith( name: String ) -> UIImage
    {
//        logTrace()
        let         directoryPath = pictureDirectoryPath()

        
        if !directoryPath.isEmpty
        {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )
            let     imageFileData        = FileManager.default.contents( atPath: imageFileURL.path )
            
            
            if let imageData = imageFileData
            {
                if let image = UIImage.init( data: imageData )
                {
//                    logVerbose( "Loaded image named [ %@ ]", name )
                    return image
                }
                
            }
            else
            {
                logVerbose( "ERROR!  Failed to load data for image [ %@ ]", name )
            }
            
        }
        else
        {
            logVerbose( "ERROR!  directoryPath is Empty!" )
        }
        
        return UIImage.init()
    }
    
    
    func saveImage( image: UIImage ) -> String
    {
//        logTrace()
        let         directoryPath = pictureDirectoryPath()
        
        
        if directoryPath.isEmpty
        {
            return String.init()
        }
        
        
        let     imageFilename        = UUID().uuidString
        let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
        let     pictureFileURL       = picturesDirectoryURL.appendingPathComponent( imageFilename )
        
        
        guard let imageData = image.jpegData( compressionQuality: 1 ) ?? image.pngData() else
        {
            logTrace( "ERROR!  Could NOT convert UIImage to Data!" )
            return String.init()
        }
        
        do
        {
            try imageData.write( to: pictureFileURL, options: .atomic )
            
            logVerbose( "Saved image to file named[ %@ ]", imageFilename )
            return imageFilename
        }
            
        catch let error as NSError
        {
            logVerbose( "ERROR!  Failed to save image for [ %@ ] ... Error[ %@ ]", imageFilename, error.localizedDescription )
        }
        
        return String.init()
    }
    
    

    // MARK: Utility Methods
    
    private func deleteDatabase()
    {
        guard let docURL = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).last else
        {
            logTrace( "Error!  Unable to resolve document directory" )
            return
        }
        
        
        let     storeURL = docURL.appendingPathComponent( DATABASE_NAME )
        
        
        do
        {
            try FileManager.default.removeItem( at: storeURL )
            logVerbose( "deleted database @ [ %@ ]", storeURL.path )
        }
        
        catch
        {
            let     nsError = error as NSError
            
            
            logVerbose( "Error!  Unable delete store! ... Error[ %@ ]", nsError.localizedDescription )
        }
        
    }
    
    
    private func description() -> String
    {
        return "ChefbookCentral"
    }
    
    
    private func fetchAllRecipeObjects()     // Must be called from within persistentContainer.viewContext
    {
        selectedRecipeIndex = NO_SELECTION

        do
        {
            let     request : NSFetchRequest<Recipe> = Recipe.fetchRequest()
            let     fetchedRecipes = try managedObjectContext.fetch( request )
        
            
            recipeArray = fetchedRecipes.sorted( by:
                        { (recipe1, recipe2) -> Bool in
                    
                            recipe1.name! < recipe2.name!     // We can do this because the name is a required field that must be unique
                        } )
            
            for index in 0 ..< self.recipeArray.count
            {
                if recipeArray[index].guid == selectedRecipeGuid
                {
                    selectedRecipeIndex = index
                    break
                }
                
            }
            
        }
            
        catch
        {
            recipeArray = [Recipe]()
            logTrace( "Error!  Fetch failed!" )
        }
        
    }
    
    
    private func loadCoreData()
    {
        guard let modelURL = Bundle.main.url( forResource: "ChefbookDataModel", withExtension: "momd" ) else
        {
            logTrace( "Error!  Could NOT load model from bundle!" )
            return
        }
        
        logVerbose( "modelURL[ %@ ]", modelURL.path )

        guard let managedObjectModel = NSManagedObjectModel( contentsOf: modelURL ) else
        {
            logVerbose( "Error!  Could NOT initialize managedObjectModel from URL[ %@ ]", modelURL.path )
            return
        }
        
        
        let     persistentStoreCoordinator = NSPersistentStoreCoordinator( managedObjectModel: managedObjectModel )

    
        managedObjectContext = NSManagedObjectContext( concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType )
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        guard let docURL = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).last else
        {
            logTrace( "Error!  Unable to resolve document directory!" )
            return
        }
        
        
        let     storeURL = docURL.appendingPathComponent( DATABASE_NAME )
        
        
        logVerbose( "storeURL[ %@ ]", storeURL.path )

        do
        {
            try persistentStoreCoordinator.addPersistentStore( ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil )
            
            self.didOpenDatabase = true
//            logTrace( "added Recipes store to coordinator" )
        }
            
        catch
        {
            let     nsError = error as NSError
            
            
            logVerbose( "Error!  Unable migrate store[ %@ ]", nsError.localizedDescription )
        }
        
    }
    
    
    private func pictureDirectoryPath() -> String
    {
        let         fileManager = FileManager.default
        
        
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first
        {
            let     picturesDirectoryURL = documentDirectoryURL.appendingPathComponent( "RecipePictures" )
            
            
            if !fileManager.fileExists( atPath: picturesDirectoryURL.path )
            {
                do
                {
                    try fileManager.createDirectory( atPath: picturesDirectoryURL.path, withIntermediateDirectories: true, attributes: nil )
                }
                catch let error as NSError
                {
                    logVerbose( "ERROR!  Failed to create photos directory ... Error[ %@ ]", error.localizedDescription )
                    return String.init()
                }
                
            }
            
            if !fileManager.fileExists( atPath: picturesDirectoryURL.path )
            {
                logTrace( "ERROR!  photos directory does NOT exist!" )
                return String.init()
            }
            
//            logVerbose( "picturesDirectory[ %@ ]", picturesDirectoryURL.path )
            return picturesDirectoryURL.path
        }
        
//        logTrace( "ERROR!  Could NOT find the documentDirectory!" )
        return String.init()
    }
    
    
    private func refetchRecipesAndNotifyDelegate()       // Must be called from within a persistentContainer.viewContext
    {
        fetchAllRecipeObjects()
        
        DispatchQueue.main.async
        {
            self.delegate?.chefbookCentralDidReloadRecipeArray( chefbookCentral: self )
        }

        if .pad == UIDevice.current.userInterfaceIdiom
        {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: NOTIFICATION_RECIPES_UPDATED ), object: self )
        }

    }
    

    private func saveContext()
    {
        if managedObjectContext.hasChanges
        {
            do
            {
                try managedObjectContext.save()
            }
            catch
            {
                let     nsError = error as NSError
                
                
                logVerbose( "Unresolved error[ %@ ]", nsError.localizedDescription )
            }
            
        }
        
    }
    
    
}



// MARK: Public Definitions & Utility Methods

struct PinColors
{
    static let pinBlack     = Int16( 0 )
    static let pinBlue      = Int16( 1 )
    static let pinBrown     = Int16( 2 )
    static let pinCyan      = Int16( 3 )
    static let pinDarkGray  = Int16( 4 )
    static let pinGray      = Int16( 5 )
    static let pinGreen     = Int16( 6 )
    static let pinLightGray = Int16( 7 )
    static let pinMagenta   = Int16( 8 )
    static let pinOrange    = Int16( 9 )
    static let pinPurple    = Int16( 10 )
    static let pinRed       = Int16( 11 )
    static let pinWhite     = Int16( 12 )
    static let pinYellow    = Int16( 13 )
};


let pinColorArray: [UIColor] = [ .black,
                                 .blue,
                                 .brown,
                                 .cyan,
                                 .darkGray,
                                 .gray,
                                 .green,
                                 .lightGray,
                                 .magenta,
                                 .orange,
                                 .purple,
                                 .red,
                                 .white,
                                 .yellow ]


let pinColorNameArray = [ NSLocalizedString( "PinColor.Black"    , comment:  "Black"      ),
                          NSLocalizedString( "PinColor.Blue"     , comment:  "Blue"       ),
                          NSLocalizedString( "PinColor.Brown"    , comment:  "Brown"      ),
                          NSLocalizedString( "PinColor.Cyan"     , comment:  "Cyan"       ),
                          NSLocalizedString( "PinColor.DarkGray" , comment:  "Dark Gray"  ),
                          NSLocalizedString( "PinColor.Gray"     , comment:  "Gray"       ),
                          NSLocalizedString( "PinColor.Green"    , comment:  "Green"      ),
                          NSLocalizedString( "PinColor.LightGray", comment:  "Light Gray" ),
                          NSLocalizedString( "PinColor.Magenta"  , comment:  "Magenta"    ),
                          NSLocalizedString( "PinColor.Orange"   , comment:  "Orange"     ),
                          NSLocalizedString( "PinColor.Purple"   , comment:  "Purple"     ),
                          NSLocalizedString( "PinColor.Red"      , comment:  "Red"        ),
                          NSLocalizedString( "PinColor.White"    , comment:  "White"      ),
                          NSLocalizedString( "PinColor.Yellow"   , comment:  "Yellow"     )]


let NEW_INGREDIENT                  = -3
let NEW_RECIPE                      = -2
let NO_SELECTION                    = -1
let NOTIFICATION_RECIPE_SELECTED    = "RecipeSelected"
let NOTIFICATION_RECIPES_UPDATED    = "RecipesUpdated"



func viewControllerWithStoryboardId( storyboardId: String ) -> UIViewController
{
    logVerbose( "[ %@ ]", storyboardId )
    let     storyboardName = ( ( .pad == UIDevice.current.userInterfaceIdiom ) ? "Main_iPad" : "Main_iPhone" )
    let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
    let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
    
    
    return viewController
}


func iPhoneViewControllerWithStoryboardId( storyboardId: String ) -> UIViewController
{
    logVerbose( "[ %@ ]", storyboardId )
    let     storyboardName = "Main_iPhone"
    let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
    let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
    
    
    return viewController
}


