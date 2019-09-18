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
                                   SectionHeaderViewDelegate,
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
        static let ingredients   = "FormulaIngredientTableViewCell"
        static let name          = "FormulaNameTableViewCell"
        static let sectionHeader = "SectionHeaderView"
        static let yield         = "FormulaYieldTableViewCell"
    }
    
    private struct CellIndexes
    {
        static let name         = 0
        static let yield        = 1
        static let ingredients  = 2
    }
    
    private struct StoryboardIds
    {
        static let imageViewer   = "ImageViewController"
        static let sectionHeader = "SectionHeaderViewController"
    }
    
    private enum StateMachine
    {
        case name
        case yield
        case ingredients
    }
    
    private struct TableSections
    {
        static let nameAndYield = 0
        static let flour        = 1
        static let ingredients  = 2
        static let none         = 3
    }
    
    private var     newIngredientForSection = TableSections.none
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
                                         ingredientIndexPath            : IndexPath,
                                         isNew                          : Bool,
                                         editedIngredientName           : String,
                                         editedPercentage               : String )
    {
        logTrace()
        processIngredientInputs( ingredientIndexPath : ingredientIndexPath,
                                 isNew               : isNew,
                                 ingredientName      : editedIngredientName,
                                 percentOfFlour      : editedPercentage )
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
    
    
    
    // MARK: SectionHeaderViewDelegate Methods
    
    func sectionHeaderView( sectionHeaderView        : SectionHeaderView,
                            didRequestAddFor section : Int)
    {
        logVerbose( "[ %d ]", section )
        newIngredientForSection = section
        
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
    
    func numberOfSections( in tableView: UITableView ) -> Int
    {
        var numberOfSections = 0
        
        if !waitingForNotification
        {
            switch currentState
            {
            case .name:
                numberOfSections = 1
                
            case .yield:
                numberOfSections = 1
                
            default:
                numberOfSections = 3
            }
            
        }
        
//        logVerbose( "[ %d ]", numberOfSections )
        
        return numberOfSections
    }
    
    
    func tableView(_ tableView                     : UITableView,
                     numberOfRowsInSection section : Int ) -> Int
    {
        var numberOfRows = 0
        
        if !waitingForNotification
        {
            if section == TableSections.nameAndYield
            {
                switch currentState
                {
                case .name:
                    numberOfRows = 1
                    
                case .yield:
                    numberOfRows = 2
                    
                default:
                    numberOfRows = 3    // 3rd row is the % Name Weight header for the following sections
                }

            }
            else if section == TableSections.flour
            {
                let     indexOfNextFlourIngredient = ChefbookCentral.sharedInstance.recipeArray[recipeIndex].flourIngredients?.count ?? 0
                
                numberOfRows = indexOfNextFlourIngredient + ( newIngredientForSection == TableSections.flour ? 1 : 0 )
            }
            else // section 2 ... TableSections.ingredients
            {
                let     indexOfNextBreadIngredient = ChefbookCentral.sharedInstance.recipeArray[recipeIndex].breadIngredients?.count ?? 0
                
                numberOfRows = indexOfNextBreadIngredient + ( newIngredientForSection == TableSections.ingredients ? 1 : 0 )
            }

        }
        
//        logVerbose( "[ %d ][ %d ]", section, numberOfRows )
        
        return numberOfRows
    }
    
    
    func tableView(_ tableView              : UITableView,
                     cellForRowAt indexPath : IndexPath) -> UITableViewCell
    {
//        logVerbose( "row[ %d ]", indexPath.row)
        var     cell : UITableViewCell!
        
        
        if indexPath.section == TableSections.nameAndYield
        {
            switch indexPath.row
            {
            case 0:
                cell = loadFormulaNameCell()
            case 1:
                cell = loadFormulaYieldCell()
            default:
                cell = loadFormulaIngredientCellFor( indexPath: indexPath )
            }
            
        }
        else
        {
            cell = loadFormulaIngredientCellFor( indexPath: indexPath )
        }
        
        return cell
    }
    
    
    func tableView(_ tableView              : UITableView,
                     canEditRowAt indexPath : IndexPath) -> Bool
    {
        let canEdit = indexPath.section != TableSections.nameAndYield
        
        return canEdit
    }
    
    
    func tableView(_ tableView           : UITableView,
                     commit editingStyle : UITableViewCell.EditingStyle,
                     forRowAt indexPath  : IndexPath)
    {
        if editingStyle == .delete
        {
            logVerbose( "delete ingredient at row [ %d ]", indexPath.row )
            
            DispatchQueue.main.asyncAfter(deadline: ( .now() + 0.2 ), execute:
            {
                let  chefbookCentral = ChefbookCentral.sharedInstance
                
                chefbookCentral.selectedRecipeIndex = self.recipeIndex
                
                if indexPath.section == TableSections.flour
                {
                    chefbookCentral.deleteFormulaRecipeFlourIngredientAt( index: indexPath.row )
                }
                else    // TableSections.ingredients
                {
                    chefbookCentral.deleteFormulaRecipeBreadIngredientAt( index: indexPath.row )
                }
                
            })
            
        }
        
    }
    

    
    // MARK: UITableViewDelegate Methods
    
    func tableView(_ tableView                : UITableView,
                     didSelectRowAt indexPath : IndexPath )
    {
        tableView.deselectRow( at: indexPath, animated: false )
    }
    
    
    func tableView(_ tableView                        : UITableView,
                     heightForHeaderInSection section : Int ) -> CGFloat
    {
        let     height = section == 0 ? 0.0 : 44.0 as CGFloat
        
        return height
    }
    
    
    func tableView(_ tableView                      : UITableView,
                     viewForHeaderInSection section : Int ) -> UIView?
    {
        let     sectionHeaderView = tableView.dequeueReusableHeaderFooterView( withIdentifier: SectionHeaderView.reuseIdentifier ) as? SectionHeaderView
        let     flourHeaderText   = String( format: "100     %@", NSLocalizedString( "CellTitle.Flour", comment: "Flour" ) )
        let     title             = section == TableSections.flour ? flourHeaderText : NSLocalizedString( "CellTitle.Ingredients", comment: "Ingredients" )

        sectionHeaderView?.initWith( title : title,
                                     for   : section,
                                     with  : self )
        return sectionHeaderView
    }
    
    
    
    // MARK: Utility Methods
    
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
    
    
    private func ingredientAt( indexPath: IndexPath ) -> BreadIngredient
    {
        let     recipe           = ChefbookCentral.sharedInstance.recipeArray[self.recipeIndex]
        let     ingredientsArray = indexPath.section == 1 ? recipe.flourIngredients?.allObjects as! [BreadIngredient] : recipe.breadIngredients?.allObjects as! [BreadIngredient]
        var     breadIngredient  : BreadIngredient!
        
        
        for ingredient in ingredientsArray
        {
            if ingredient.index == indexPath.row
            {
                breadIngredient = ingredient
                break
            }
            
        }
        
        return breadIngredient
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
                currentState = StateMachine.ingredients
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
        
        myTableView.register( SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderView.reuseIdentifier )   // programmatic
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
    
    
    private func isIngredientUniqueAt( indexPath : IndexPath,
                                       name      : String ) -> Bool
    {
        let     chefbookCentral  = ChefbookCentral.sharedInstance
        var     isUnique         = true
        let     recipe           = chefbookCentral.recipeArray[recipeIndex]
        let     ingredientsArray = indexPath.section == 1 ? recipe.flourIngredients?.allObjects as! [BreadIngredient] : recipe.breadIngredients?.allObjects as! [BreadIngredient]
        
        
        for ingredient in ingredientsArray
        {
            if ( ingredient.name == name ) && ( indexPath.row != ingredient.index )
            {
                isUnique = false
                break
            }
            
        }
        
        return isUnique
    }
    
    
    private func loadFormulaIngredientCellFor( indexPath: IndexPath ) -> UITableViewCell
    {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.ingredients ) else
        {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        
//        logVerbose( "section[ %d ] row[ %d ]", indexPath.section, indexPath.row )
        let     formulaIngredientCell = cell as! FormulaIngredientTableViewCell
        
        if indexPath.section == TableSections.nameAndYield
        {
            formulaIngredientCell.setupAsHeader()
        }
        else
        {
            let     recipe             = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
            let     dataSource         = indexPath.section == TableSections.flour ? recipe.flourIngredients : recipe.breadIngredients
            let     lastIngredientRow  = dataSource?.count ?? 0
            let     isNewIngredientRow = newIngredientForSection == indexPath.section && lastIngredientRow == indexPath.row
            
            formulaIngredientCell.initializeWithRecipeAt( recipeIndex         : recipeIndex,
                                                          ingredientIndexPath : indexPath,
                                                          isNew               : isNewIngredientRow,
                                                          delegate            : self )
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
        
        
//        logTrace()
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
        
        
//        logTrace()
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
    
    
    private func processIngredientInputs( ingredientIndexPath : IndexPath,
                                          isNew               : Bool,
                                          ingredientName      : String,
                                          percentOfFlour      : String )
    {
        logTrace()
        let     newName = ingredientName.trimmingCharacters( in: .whitespacesAndNewlines )

        
        if !newName.isEmpty
        {
            let     chefbookCentral = ChefbookCentral.sharedInstance
            
      
            if self.isIngredientUniqueAt( indexPath: ingredientIndexPath, name: newName )
            {
                let     myPercentOfFlour = Float( percentOfFlour.trimmingCharacters( in: .whitespacesAndNewlines ) ) ?? 100
                
                
                chefbookCentral.selectedRecipeIndex = recipeIndex
                
                if isNew
                {
                    if ingredientIndexPath.section == TableSections.flour
                    {
                        chefbookCentral.addFlourIngredientToFormulaRecipeAt( ingredientIndex : ( chefbookCentral.recipeArray[self.recipeIndex].flourIngredients?.count ?? 0 ),
                                                                             name            : newName,
                                                                             percentage      : Int( myPercentOfFlour ) )
                    }
                    else
                    {
                        chefbookCentral.addBreadIngredientToFormulaRecipeAt( ingredientIndex : ( chefbookCentral.recipeArray[self.recipeIndex].breadIngredients?.count ?? 0 ),
                                                                             name            : newName,
                                                                             percentage      : Int( myPercentOfFlour ) )
                    }

                    newIngredientForSection = TableSections.none
                }
                else
                {
                    let     ingredient = ingredientAt( indexPath: ingredientIndexPath )
                    let     recipe     = chefbookCentral.recipeArray[recipeIndex]
                    let     updatePercentages =  ingredient.percentOfFlour != Int16( myPercentOfFlour )
                    
                    
                    
                    ingredient.name           = newName
                    ingredient.percentOfFlour = Int16( myPercentOfFlour )
                    
                    if updatePercentages
                    {
                        chefbookCentral.adjustFlourIngredientsPercentagesIn( recipe                  : recipe,
                                                                             forChangeInIngredientAt : ingredientIndexPath.row )
                    }
                    
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
        recipe.formulaYieldWeight   = Int64( myYieldWeight   ) ?? 0
        
        currentState = StateMachine.ingredients
        
        chefbookCentral.selectedRecipeIndex = recipeIndex
        chefbookCentral.updateIngredientsIn( recipe: recipe )
        chefbookCentral.saveUpdatedRecipe(   recipe: recipe )
    }
    
    
}
