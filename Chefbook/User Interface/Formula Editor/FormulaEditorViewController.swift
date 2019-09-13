//
//  FormulaEditorViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 9/3/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


class FormulaEditorViewController: UIViewController,
                                   ChefbookCentralDelegate,
                                   FormulaIngredientTableViewCellDelegate,
                                   FormulaNameTableViewCellDelegate,
                                   FormulaYieldTableViewCellDelegate,
                                   UIImagePickerControllerDelegate,
                                   UINavigationControllerDelegate,  // Required for UIImagePickerControllerDelegate
                                   UIPopoverPresentationControllerDelegate,
                                   UITableViewDataSource,
                                   UITableViewDelegate
{
    // MARK: Public Variables

    var     recipeIndex : Int!                        // Set by caller

    
    @IBOutlet weak var myTableView: UITableView!
    

    // MARK: Private Variables

    private struct CellIdentifiers
    {
        static let ingredients  = "FormulaIngredientTableViewCell"
        static let name         = "FormulaNameTableViewCell"
        static let yield        = "FormulaYieldTableViewCell"
    }
    
    private struct CellIndexes
    {
        static let name         = 0
        static let yield        = 1
        static let ingredients  = 2
    }
    
    private struct StoryboardIds
    {
        static let imageViewer = "ImageViewController"
    }
    
    private enum StateMachine
    {
        case name
        case yield
        case ingredientHeader
        case ingredients
    }
    
    private var     newIngredientRequested  = false
    private var     currentState            = StateMachine.name
    private var     waitingForNotification  = false
    private var     weightOfFlour           = 0

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        logTrace()
        super.viewDidLoad()

        title = NSLocalizedString( "Title.BreadFormulaEditor", comment: "Bread Formula Editor" )
        
        preferredContentSize = CGSize( width: 320, height: 460 )
        initializeStateMachine()
        initializeTableView()
        
        if UIDevice.current.userInterfaceIdiom == .pad
        {
            waitingForNotification = true
        }
        
    }
    

    override func viewWillAppear(_ animated: Bool)
    {
        logTrace()
        super.viewWillAppear( animated )
        
        ChefbookCentral.sharedInstance.delegate = self

        configureBarButtonItem()
        myTableView.reloadData()
        
        NotificationCenter.default.addObserver( self,
                                                selector: #selector( FormulaEditorViewController.recipesUpdated( notification: ) ),
                                                name:     NSNotification.Name( rawValue: NOTIFICATION_RECIPES_UPDATED ),
                                                object:   nil )
        NotificationCenter.default.addObserver( self,
                                                selector: #selector( FormulaEditorViewController.recipeSelected( notification: ) ),
                                                name:     NSNotification.Name( rawValue: NOTIFICATION_RECIPE_SELECTED ),
                                                object:   nil )
   }
    
    
    override func viewWillDisappear(_ animated: Bool)
    {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
    }
    
    
    override func didReceiveMemoryWarning()
    {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    

    // MARK: ChefbookCentralDelegate Methods
    
    func chefbookCentral( chefbookCentral : ChefbookCentral,
                          didOpenDatabase : Bool )
    {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
    }
    
    
    func chefbookCentralDidReloadRecipeArray( chefbookCentral : ChefbookCentral )
    {
        logVerbose( "loaded [ %d ] recipes ... recipeIndex[ %d ]", chefbookCentral.recipeArray.count, recipeIndex )
        
        logVerbose( "recovering recipeIndex[ %d ] from chefbookCentral", chefbookCentral.selectedRecipeIndex )
        recipeIndex = chefbookCentral.selectedRecipeIndex

        self.myTableView.reloadData()
    }
    
    
    
    // MARK: FormulaIngredientTableViewCellDelegate Methods
    
    func formulaIngredientTableViewCell( formulaIngredientTableViewCell : FormulaIngredientTableViewCell,
                                         requestingAdd                  : Bool )
    {
        logTrace()
        newIngredientRequested = true
        
        myTableView.reloadData()
    }
    
    
    func formulaIngredientTableViewCell( formulaIngredientTableViewCell : FormulaIngredientTableViewCell,
                                         ingredientIndex                : Int,
                                         editedIngredientName           : String,
                                         editedPercentage               : String )
    {
        logTrace()
        var index = ingredientIndex
        
        if newIngredientRequested
        {
            newIngredientRequested = false
            index = NEW_INGREDIENT
        }

        processIngredientInputs( ingredientIndex : index,
                                 ingredientName  : editedIngredientName,
                                 percentOfFlour  : editedPercentage )
    }

    
    
    // MARK: FormulaNameTableViewCellDelegate Methods
    
    func formulaNameTableViewCell( formulaNameTableViewCell: FormulaNameTableViewCell,
                                   editedName              : String )
    {
        logTrace()
        processNameInput( name: editedName )
    }
    
    
    
    // MARK: FormulaYieldTableViewCellDelegate Methods

    func formulaYieldTableViewCell( formulaYieldTableViewCell: FormulaYieldTableViewCell,
                                    editedQuantity           : String,
                                    editedWeight             : String )
    {
        logTrace()
        processYieldInputs( yieldQuantity : editedQuantity,
                            yieldWeight   : editedWeight )
    }

    

    // MARK: NSNotification Methods
    
    @objc func recipeSelected( notification: NSNotification )
    {
        logTrace()
        waitingForNotification = false
        
        configureBarButtonItem()

        myTableView.reloadData()
    }
    
    
    @objc func recipesUpdated( notification: NSNotification )
    {
        let     chefbookCentral = ChefbookCentral.sharedInstance
        
        
        if waitingForNotification
        {
            logTrace( "ignorning ... waitingForNotification" )
            return
        }
        
        logVerbose( "recovering selectedRecipeIndex[ %d ] from chefbookCentral", chefbookCentral.selectedRecipeIndex )
        recipeIndex = chefbookCentral.selectedRecipeIndex
        
        // The reason we are using Notifications is because this view can be up in two different places on the iPad at the same time.
        // This approach allows a change in one to immediately be reflected in the other.
        
        myTableView.reloadData()
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func cancelBarButtonTouched( sender: UIBarButtonItem )
    {
        logTrace()
        dismissView()
    }
    
    
    
    // MARK: UIPopoverPresentationControllerDelegate Methods
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    
    
    // MARK: UITableViewDataSource Methods
    
    func tableView(_ tableView: UITableView,
                     numberOfRowsInSection section: Int) -> Int
    {
        var numberOfRows = 0
        
        if !waitingForNotification
        {
            switch currentState
            {
            case .name:
                numberOfRows = 1
                
            case .yield:
                numberOfRows = 2
                
            case .ingredientHeader:
                let     indexOfNextIngredient = ChefbookCentral.sharedInstance.recipeArray[recipeIndex].breadIngredients?.count ?? 0
                
                currentState           = .ingredients
                newIngredientRequested = indexOfNextIngredient == 0
                numberOfRows           = indexOfNextIngredient + ( newIngredientRequested ? 4 : 3 )

            default:
                let     indexOfNextIngredient = ChefbookCentral.sharedInstance.recipeArray[recipeIndex].breadIngredients?.count ?? 0
                
                numberOfRows = indexOfNextIngredient + ( newIngredientRequested ? 4 : 3 )
            }

        }
        
        logVerbose( "[ %d ]", numberOfRows )
        return numberOfRows
    }
    
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
//        logVerbose( "row[ %d ]", indexPath.row)
        var     cell : UITableViewCell!
        
        
        switch indexPath.row
        {
        case CellIndexes.name:
            cell = loadFormulaNameCell()
            
        case CellIndexes.ingredients:   // Header
            cell = loadFormulaIngredientCellFor( index: indexPath.row )
            
        case CellIndexes.yield:
            cell = loadFormulaYieldCell()
            
        default:       // All other ingredients
            cell = loadFormulaIngredientCellFor( index: indexPath.row )
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView,
                     canEditRowAt indexPath: IndexPath) -> Bool
    {
        return ( indexPath.row > 3 )        // Prevents deleting the flour ingredient which we always put first and must be present to compute weights of other ingredients
    }
    
    
    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            logVerbose( "delete ingredient at row [ %d ]", indexPath.row )
            
            DispatchQueue.main.asyncAfter(deadline: ( .now() + 0.2 ), execute:
            {
                let  chefbookCentral = ChefbookCentral.sharedInstance
                
                chefbookCentral.selectedRecipeIndex = self.recipeIndex
                chefbookCentral.deleteFormulaRecipeIngredientAt( index: indexPath.row - 3 )  // Skips past the header
            })
            
        }
        
    }
    

    
    // MARK: UITableViewDelegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath )
    {
        tableView.deselectRow( at: indexPath, animated: false )
    }
    
    
    
    // MARK: Utility Methods
    
    private func breadIngredientAt( index: Int ) -> BreadIngredient
    {
        let     recipe           = ChefbookCentral.sharedInstance.recipeArray[self.recipeIndex]
        let     ingredientsArray = recipe.breadIngredients?.allObjects as! [BreadIngredient]
        var     breadIngredient : BreadIngredient!
        
        
        for ingredient in ingredientsArray
        {
            if ingredient.index == index
            {
                breadIngredient = ingredient
                break
            }
            
        }
        
        return breadIngredient
    }
    
    
    private func configureBarButtonItem()
    {
        let launchedFromMasterView = UIDevice.current.userInterfaceIdiom == .pad
        
        navigationItem.leftBarButtonItem  = ( waitingForNotification ? nil : UIBarButtonItem.init( title: ( launchedFromMasterView ? NSLocalizedString( "ButtonTitle.Done", comment: "Done" ) : NSLocalizedString( "ButtonTitle.Back",   comment: "Back"   ) ),
                                                                                                   style: .plain,
                                                                                                   target: self,
                                                                                                   action: #selector( cancelBarButtonTouched ) ) )
    }
    
    
    private func dismissView()
    {
        logTrace()
        if UIDevice.current.userInterfaceIdiom == .pad
        {
            let detailNavigationViewController = ( ( (self.splitViewController?.viewControllers.count)! > 1 ) ? self.splitViewController?.viewControllers[1] : nil ) as? UINavigationController
            
            
            detailNavigationViewController?.visibleViewController?.view.frame = CGRect( x: 0, y: 0, width: 0, height: 0 )
            navigationItem.leftBarButtonItem = nil
        }
        else
        {
            navigationController?.popViewController( animated: true )
        }
        
    }
    
    
    private func flourIngredientPresentIn( recipe : Recipe ) -> Bool
    {
        var     flourIsPresent = false
        
        if recipe.breadIngredients?.count != 0
        {
            for case let ingredient as BreadIngredient in recipe.breadIngredients!
            {
                if ingredient.isFlour
                {
                    flourIsPresent = true
                    weightOfFlour = Int( ingredient.weight )
                    break
                }
                
            }
            
        }
        
        return flourIsPresent
    }
    
    
    private func initializeStateMachine()
    {
        logTrace()
        if recipeIndex == NEW_RECIPE
        {
            currentState = StateMachine.name
        }
        else
        {
            let recipe = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
            
            if recipe.formulaYieldQuantity == 0 || recipe.formulaYieldWeight == 0
            {
                currentState = StateMachine.yield
            }
            else
            {
                currentState = ( recipe.breadIngredients?.count == 0 ) ? StateMachine.ingredientHeader : StateMachine.ingredients
            }
            
        }
        
    }
    
    
    private func initializeTableView()
    {
        logTrace()
        var         frame           = CGRect.zero
        
        
        frame.size.height = .leastNormalMagnitude

        myTableView.contentInsetAdjustmentBehavior = .never
        myTableView.separatorStyle  = .none
        myTableView.tableHeaderView = UIView( frame: frame )
        myTableView.tableFooterView = UIView( frame: frame )
    }
    
    
    private func isFlourIngredient() -> Bool
    {
        let     chefbookCentral   = ChefbookCentral.sharedInstance
        var     isFlourIngredient = false
        
        
        if chefbookCentral.recipeArray[recipeIndex].breadIngredients?.count != 0
        {
            let     ingredientsArray = chefbookCentral.recipeArray[recipeIndex].breadIngredients?.allObjects as! [BreadIngredient]
            
            for ingredient in ingredientsArray
            {
                if ingredient.isFlour
                {
                    isFlourIngredient = true
                    break
                }
                
            }
            
        }
        
        return isFlourIngredient
    }


    private func isFormulaUnique( name: String ) -> Bool
    {
        let     chefbookCentral   = ChefbookCentral.sharedInstance
        var     numberOfInstances = 0
        
        
        for recipe in chefbookCentral.recipeArray
        {
            if ( name.uppercased() == recipe.name?.uppercased() )
            {
                if recipeIndex == NEW_RECIPE
                {
                    logTrace( "Found a duplicate! [New]." )
                    numberOfInstances += 1
                }
                else
                {
                    let     recipeBeingEdited = chefbookCentral.recipeArray[recipeIndex]
                    
                    
                    if recipe.guid != recipeBeingEdited.guid
                    {
                        logTrace( "Found a duplicate! [Existing]." )
                        numberOfInstances += 1
                    }
                    
                }
                
            }
            
        }
        
        return ( numberOfInstances == 0 )
    }
    
    
    private func isIngredientUniqueAt( index : Int,
                                       name  : String ) -> Bool
    {
        let     chefbookCentral = ChefbookCentral.sharedInstance
        var     isUnique        = true
        
        
        if chefbookCentral.recipeArray[recipeIndex].breadIngredients?.count != 0
        {
            let     ingredientsArray = chefbookCentral.recipeArray[recipeIndex].breadIngredients?.allObjects as! [BreadIngredient]
            
            for ingredient in ingredientsArray
            {
                if ( ingredient.name == name ) && ( index != ingredient.index )
                {
                    isUnique = false
                    break
                }
                
            }
            
        }
        
        return isUnique
    }
    
    
    private func loadFormulaIngredientCellFor( index: Int ) -> UITableViewCell
    {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.ingredients ) else
        {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        
        logTrace()
        let formulaIngredientCell = cell as! FormulaIngredientTableViewCell
        
        
        if index == 2
        {
            formulaIngredientCell.setupAsHeaderWith( delegate: self )
        }
        else
        {
            let lastIngredientRow  = 3 + ( ChefbookCentral.sharedInstance.recipeArray[recipeIndex].breadIngredients?.count ?? 0 )
            let isNewIngredientRow = newIngredientRequested && lastIngredientRow == index
            
            formulaIngredientCell.initializeWithRecipeAt( recipeIndex     : recipeIndex,
                                                          ingredientIndex : ( index - 3 ),
                                                          isNew           : isNewIngredientRow,
                                                          delegate        : self )
        }
        
        return cell
    }
    
    
    private func loadFormulaNameCell() -> UITableViewCell
    {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.name ) else
        {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        
        logTrace()
        let     formulaNameCell = cell as! FormulaNameTableViewCell
        let     recipeName      = ( ( recipeIndex == NEW_RECIPE ) ? "" : ChefbookCentral.sharedInstance.recipeArray[recipeIndex].name! )

        
        formulaNameCell.initializeWith( formulaName : recipeName,
                                        delegate    : self )
        
        return cell
    }
    
    
    private func loadFormulaYieldCell() -> UITableViewCell
    {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.yield ) else
        {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        
        logTrace()
        let     formulaYieldCell = cell as! FormulaYieldTableViewCell
        var     loafWeight       = 0
        var     numberOfLoaves   = 0
        

        if recipeIndex != NEW_RECIPE
        {
            let recipe = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]

            numberOfLoaves = Int( recipe.formulaYieldQuantity )
            loafWeight     = Int( recipe.formulaYieldWeight   )
        }
        
        
        formulaYieldCell.initializeWith( quantity : numberOfLoaves,
                                         weight   : loafWeight,
                                         delegate : self)
        
        return cell
    }
    
    
    private func processIngredientInputs( ingredientIndex : Int,
                                          ingredientName  : String,
                                          percentOfFlour  : String )
    {
        logTrace()
        let     newName = ingredientName.trimmingCharacters( in: .whitespacesAndNewlines )
        
        
        if !newName.isEmpty
        {
            let     chefbookCentral = ChefbookCentral.sharedInstance
            
            
            if self.isIngredientUniqueAt( index: ingredientIndex, name: newName )
            {
                let     myPercentOfFlour = Float( percentOfFlour.trimmingCharacters( in: .whitespacesAndNewlines ) ) ?? 100
                
                
                chefbookCentral.selectedRecipeIndex = recipeIndex
                
                if ingredientIndex == NEW_INGREDIENT
                {
                    chefbookCentral.addIngredientToFormulaRecipeAt( ingredientIndex : ( chefbookCentral.recipeArray[self.recipeIndex].breadIngredients?.count ?? 0 ),
                                                                    name            : newName,
                                                                    percentage      : Int( myPercentOfFlour ) )
                }
                else
                {
                    let     breadIngredient = breadIngredientAt( index: ingredientIndex )
                    let     recipe          = chefbookCentral.recipeArray[recipeIndex]
                    
                    
                    breadIngredient.name           = newName
                    breadIngredient.percentOfFlour = Int16( myPercentOfFlour )
                    
                    chefbookCentral.updateIngredientsIn( recipe: recipe )
                    chefbookCentral.saveUpdatedRecipe(   recipe: recipe )
                }
                
            }
            else
            {
                logTrace( "ERROR:  Duplicate ingredient name!" )
                presentAlert( title   : NSLocalizedString( "AlertTitle.Error",                     comment: "Error!" ),
                              message : NSLocalizedString( "AlertMessage.DuplicateIngredientName", comment: "The ingredient name you choose already exists.  Please try again." ) )
            }
            
        }
        else
        {
            logTrace( "ERROR:  Name field cannot be left blank!" )
            presentAlert( title   : NSLocalizedString( "AlertTitle.Error",               comment: "Error!" ),
                          message : NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank." ) )
        }
        
    }
    
    
   private func processNameInput( name : String )
    {
        logTrace()
        let     myName = name.trimmingCharacters( in: .whitespacesAndNewlines )
        
        
        if !myName.isEmpty
        {
            if self.isFormulaUnique( name: myName )
            {
                let     chefbookCentral = ChefbookCentral.sharedInstance
 
                if self.recipeIndex == NEW_RECIPE
                {
                    currentState = StateMachine.yield
                    
                    chefbookCentral.addFormulaRecipe( name          : myName,
                                                      yieldQuantity : 0,
                                                      yieldWeight   : 0 )
                }
                else
                {
                    let     recipe = chefbookCentral.recipeArray[recipeIndex]

                    recipe.name  = myName
                    
                    chefbookCentral.saveUpdatedRecipe( recipe: recipe )
                }
                
            }
            else
            {
                logTrace( "ERROR:  Duplicate formula name!" )
                presentAlert( title   : NSLocalizedString( "AlertTitle.Error",                  comment: "Error!" ),
                              message : NSLocalizedString( "AlertMessage.DuplicateFormulaName", comment: "The recipe name you choose already exists.  Please try again." ) )
            }
            
        }
        else
        {
            logTrace( "ERROR:  Name field cannot be left blank!" )
            presentAlert( title   : NSLocalizedString( "AlertTitle.Error",               comment: "Error!" ),
                          message : NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank." ) )
        }
        
    }
    
    
    private func processYieldInputs( yieldQuantity : String,
                                     yieldWeight   : String )
    {
        logTrace()
        let     chefbookCentral  = ChefbookCentral.sharedInstance
        let     myYieldQuantity  = yieldQuantity.trimmingCharacters( in: .whitespacesAndNewlines )
        let     myYieldWeight    = yieldWeight  .trimmingCharacters( in: .whitespacesAndNewlines )
        let     recipe           = chefbookCentral.recipeArray[recipeIndex]
        
        
        recipe.formulaYieldQuantity = Int16( myYieldQuantity ) ?? 0
        recipe.formulaYieldWeight   = Int16( myYieldWeight   ) ?? 0
        
        currentState = StateMachine.ingredientHeader
        
        chefbookCentral.selectedRecipeIndex = recipeIndex
        chefbookCentral.updateIngredientsIn( recipe: recipe )
        chefbookCentral.saveUpdatedRecipe(   recipe: recipe )
    }
    
    
}
