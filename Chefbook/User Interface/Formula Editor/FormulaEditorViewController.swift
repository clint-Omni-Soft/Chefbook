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
                                   UIImagePickerControllerDelegate,
                                   UINavigationControllerDelegate,  // Required for UIImagePickerControllerDelegate
                                   UIPopoverPresentationControllerDelegate,
                                   UITableViewDataSource,
                                   UITableViewDelegate
{
    // MARK: Public Variables
    var     indexOfItemBeingEdited:     Int!                        // Set by caller

    
    @IBOutlet weak var myTableView: UITableView!
    

    // MARK: Private Variables
    private struct StoryboardIds
    {
        static let imageViewer = "ImageViewController"
    }
    
    private struct CellHeights
    {
        static let ingredients  : CGFloat =   0.0       // Calculated
        static let name         : CGFloat =  44.0
        static let yield        : CGFloat =  44.0
    }
    
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
        
        static let numberOfCells = 3
    }
    
    private var     firstTimeIn             = true
    private var     waitingForNotification  = false
    private var     weightOfFlour           = 0

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        logTrace()
        super.viewDidLoad()

        title = NSLocalizedString( "Title.BreadFormulaEditor", comment: "Bread Formula Editor" )
        
        preferredContentSize = CGSize( width: 320, height: 460 )
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
    
    func chefbookCentral( chefbookCentral: ChefbookCentral,
                          didOpenDatabase: Bool )
    {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
    }
    
    
    func chefbookCentralDidReloadRecipeArray( chefbookCentral: ChefbookCentral )
    {
        logVerbose( "loaded [ %d ] recipes ... indexOfItemBeingEdited[ %d ]", chefbookCentral.recipeArray.count, indexOfItemBeingEdited )
        
        logVerbose( "recovering recipeIndex[ %d ] from chefbookCentral", chefbookCentral.selectedRecipeIndex )
        indexOfItemBeingEdited = chefbookCentral.selectedRecipeIndex

        self.myTableView.reloadData()
    }
    
    
    
    // MARK: FormulaIngredientTableViewCellDelegate Methods
    
    func formulaIngredientTableViewCell( FormulaIngredientTableViewCell: FormulaIngredientTableViewCell,
                                         requestingAdd: Bool )
    {
        logTrace()
        editFormulaIngredientAt( index: NEW_INGREDIENT )
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
        indexOfItemBeingEdited = chefbookCentral.selectedRecipeIndex
        
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
        
        
        if  !waitingForNotification
        {
            numberOfRows = ( ( indexOfItemBeingEdited == NEW_RECIPE ) ? 1 : ( 3 + ( ChefbookCentral.sharedInstance.recipeArray[indexOfItemBeingEdited].breadIngredients?.count ?? 0 ) ) )
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
                
                chefbookCentral.selectedRecipeIndex = self.indexOfItemBeingEdited
                chefbookCentral.deleteFormulaRecipeIngredientAt( index: indexPath.row - 3 )  // Skips past the header
            })
            
        }
        
    }
    

    
    // MARK: UITableViewDelegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath )
    {
        tableView.deselectRow( at: indexPath, animated: false )
        
        switch indexPath.row
        {
        case CellIndexes.ingredients:   break   // Header

        case CellIndexes.name:
            editFormulaNameAndYield()
            
        case CellIndexes.yield:
            editFormulaNameAndYield()

        default:    // All other ingredients
            editFormulaIngredientAt( index: indexPath.row - 3 )     // Adjusting for first row of ingredients list
            break
        }
        
    }
    
    
    
    // MARK: Utility Methods
    
    private func breadIngredientAt( index: Int ) -> BreadIngredient
    {
        let     recipe           = ChefbookCentral.sharedInstance.recipeArray[self.indexOfItemBeingEdited]
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
    
    
    @objc private func editFormulaIngredientAt( index: Int )
    {
        logTrace()
        let     flourIngredient = index == 0 || ( ChefbookCentral.sharedInstance.recipeArray[indexOfItemBeingEdited].breadIngredients?.count == 0 )     // If this is the zeroth item or if there aren't any items
        let     alertTitle      = ( flourIngredient ? NSLocalizedString( "AlertTitle.EditFormulaFlourIngredient", comment: "Edit formula flour ingredient" ) :
                                                      NSLocalizedString( "AlertTitle.EditFormulaIngredient",      comment: "Edit formula ingredient"       ) )
        let     alert           = UIAlertController.init( title: alertTitle,
                                                          message: nil,
                                                          preferredStyle: .alert)
        
        let     saveAction      = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let     nameTextField = alert.textFields![0] as UITextField
            let     textField2    = alert.textFields![1] as UITextField
            
            
            self.processIngredientInputs( name           : ( nameTextField.text ?? "" ),
                                          percentOfFlour : ( flourIngredient ? "" : (textField2.text ?? "") ),
                                          weight         : ( flourIngredient ? (textField2.text ?? "") : "" ),
                                          index          : index,
                                          isFlour        : flourIngredient )
        }
        
        let     cancelAction    = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        
        alert.addTextField
        { ( textField ) in
                
            if index == NEW_INGREDIENT
            {
                textField.placeholder = NSLocalizedString( "LabelText.Name", comment: "Name" )
            }
            else
            {
                textField.text = self.breadIngredientAt( index: index ).name
            }
            
            textField.autocapitalizationType = .words
        }
        
        alert.addTextField
        { ( textField ) in
            
            if index == NEW_INGREDIENT
            {
                textField.placeholder = ( flourIngredient ? NSLocalizedString( "LabelText.Weight", comment: "Weight" ) : NSLocalizedString( "LabelText.PercentOfFlour", comment: "Percent of flour" ) )
            }
            else
            {
                textField.text = ( flourIngredient ? String( format: "%d", self.breadIngredientAt( index: index ).weight ) : String( format: "%d", self.breadIngredientAt( index: index ).percentOfFlour ) )
            }
            
            textField.keyboardType = .numberPad
        }
        
        alert.addAction( saveAction   )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    @objc private func editFormulaNameAndYield()
    {
        logTrace()
        let     alert  = UIAlertController.init( title: NSLocalizedString( "AlertTitle.EditFormulaNameAndYield", comment: "Edit formula name and " ),
                                                 message: nil,
                                                 preferredStyle: .alert)
        
        let     saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let     nameTextField     = alert.textFields![0] as UITextField
            let     quantityTextField = alert.textFields![1] as UITextField
            let     weightTextField   = alert.textFields![2] as UITextField

            
            self.processNameAndYieldInputs( name            : nameTextField    .text ?? "",
                                            yieldQuantity   : quantityTextField.text ?? "",
                                            yieldWeight     : weightTextField  .text ?? "" )
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        
        alert.addTextField
        { ( textField ) in
                
            if self.indexOfItemBeingEdited == NEW_RECIPE
            {
                textField.placeholder = NSLocalizedString( "LabelText.Name", comment: "Name" )
            }
            else
            {
                let     recipe = ChefbookCentral.sharedInstance.recipeArray[self.indexOfItemBeingEdited]
                
                textField.text = recipe.name
            }
            
            textField.autocapitalizationType = .words
        }
        
        alert.addTextField
        { ( textField ) in
            
            if self.indexOfItemBeingEdited == NEW_RECIPE
            {
                textField.placeholder = NSLocalizedString( "LabelText.YieldQuantity", comment: "Yield Quantity" )
            }
            else
            {
                let     recipe = ChefbookCentral.sharedInstance.recipeArray[self.indexOfItemBeingEdited]
                
                textField.text = String( format: "%d", recipe.formulaYieldQuantity )
            }
            
            textField.keyboardType = .numberPad
        }
        
        alert.addTextField
        { ( textField ) in
            
            if self.indexOfItemBeingEdited == NEW_RECIPE
            {
                textField.placeholder = NSLocalizedString( "LabelText.YieldWeight", comment: "Yield Weight" )
            }
            else
            {
                let     recipe = ChefbookCentral.sharedInstance.recipeArray[self.indexOfItemBeingEdited]
                
                textField.text = String( format: "%d", recipe.formulaYieldWeight )
            }
            
            textField.keyboardType = .numberPad
        }
        
        alert.addAction( saveAction   )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
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
        
        
        if chefbookCentral.recipeArray[indexOfItemBeingEdited].breadIngredients?.count != 0
        {
            let     ingredientsArray = chefbookCentral.recipeArray[indexOfItemBeingEdited].breadIngredients?.allObjects as! [BreadIngredient]
            
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
                if indexOfItemBeingEdited == NEW_RECIPE
                {
                    logTrace( "Found a duplicate! [New]." )
                    numberOfInstances += 1
                }
                else
                {
                    let     recipeBeingEdited = chefbookCentral.recipeArray[indexOfItemBeingEdited]
                    
                    
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
        
        
        if chefbookCentral.recipeArray[indexOfItemBeingEdited].breadIngredients?.count != 0
        {
            let     ingredientsArray = chefbookCentral.recipeArray[indexOfItemBeingEdited].breadIngredients?.allObjects as! [BreadIngredient]
            
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
            formulaIngredientCell.initializeWithRecipeAt( index: indexOfItemBeingEdited,
                                                          ingredientIndex: ( index - 3 ) )
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
        let     recipeName      = ( ( indexOfItemBeingEdited == NEW_RECIPE ) ? "" : ChefbookCentral.sharedInstance.recipeArray[indexOfItemBeingEdited].name! )

        
        formulaNameCell.initializeWith( formulaName: recipeName )
        
        if firstTimeIn && ( NEW_RECIPE == indexOfItemBeingEdited )
        {
            firstTimeIn = false
            
            DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.2 ) )
            {
                self.editFormulaNameAndYield()
            }
            
        }
        
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
        

        if indexOfItemBeingEdited != NEW_RECIPE
        {
            let recipe = ChefbookCentral.sharedInstance.recipeArray[indexOfItemBeingEdited]

            numberOfLoaves = Int( recipe.formulaYieldQuantity )
            loafWeight     = Int( recipe.formulaYieldWeight )
        }
        
        
        formulaYieldCell.initializeWith( numberOfLoaves: numberOfLoaves,
                                         loafWeight:     loafWeight )
        
        return cell
    }
    
    
    private func processIngredientInputs( name           : String,
                                          percentOfFlour : String,
                                          weight         : String,
                                          index          : Int,
                                          isFlour        : Bool )
    {
        logTrace()
        let     newName = name.trimmingCharacters( in: .whitespacesAndNewlines )
        
        
        if !newName.isEmpty
        {
            let     chefbookCentral = ChefbookCentral.sharedInstance


            if self.isIngredientUniqueAt( index: index, name: newName )
            {
                let     myPercentOfFlour = Float( percentOfFlour.trimmingCharacters( in: .whitespacesAndNewlines ) ) ?? 100
                var     myWeight         = Float( weight        .trimmingCharacters( in: .whitespacesAndNewlines ) ) ?? 1
                let     recipe           = chefbookCentral.recipeArray[indexOfItemBeingEdited]
                
                
                
                if !isFlour && flourIngredientPresentIn( recipe: recipe )
                {
                    myWeight = Float( weightOfFlour ) * ( myPercentOfFlour / 100 )
                }
                
                chefbookCentral.selectedRecipeIndex = indexOfItemBeingEdited

                if index == NEW_INGREDIENT
                {
                    chefbookCentral.addIngredientToFormulaRecipeWith( index      : ( chefbookCentral.recipeArray[self.indexOfItemBeingEdited].breadIngredients?.count ?? 0 ),
                                                                      name       : newName,
                                                                      isFlour    : isFlour,
                                                                      percentage : Int( myPercentOfFlour ),
                                                                      weight     : Int( myWeight         ) )
                }
                else
                {
                    let     breadIngredient = breadIngredientAt( index: index )
                    let     recipe          = chefbookCentral.recipeArray[indexOfItemBeingEdited]

                    
                    breadIngredient.name           = newName
                    breadIngredient.percentOfFlour = Int16( myPercentOfFlour )
                    breadIngredient.weight         = Int16( myWeight         )
                    
                    chefbookCentral.saveUpdatedRecipe( recipe: recipe )
                }
                
            }
            else
            {
                logTrace( "ERROR:  Duplicate ingredient name!" )
                let     alert    = UIAlertController.init( title          : NSLocalizedString( "AlertTitle.Error",                     comment: "Error!" ),
                                                           message        : NSLocalizedString( "AlertMessage.DuplicateIngredientName", comment: "The ingredient name you choose already exists.  Please try again." ),
                                                           preferredStyle : .alert)
                let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
                { ( alertAction ) in
                    logTrace( "OK Action" )
                    
                    self.editFormulaIngredientAt( index: index )
                }

                alert.addAction( okAction )
                
                present( alert, animated: true, completion: nil )
            }
            
        }
        else
        {
            logTrace( "ERROR:  Name field cannot be left blank!" )
            let     alert    = UIAlertController.init( title          : NSLocalizedString( "AlertTitle.Error",               comment: "Error!" ),
                                                       message        : NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank." ),
                                                       preferredStyle : .alert)
            let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
            { ( alertAction ) in
                logTrace( "OK Action" )
                
                self.editFormulaIngredientAt( index: index )
            }
            
            alert.addAction( okAction )
            
            present( alert, animated: true, completion: nil )
        }
        
    }
    
    
    private func processNameAndYieldInputs( name            : String,
                                            yieldQuantity   : String,
                                            yieldWeight     : String )
    {
        logTrace()
        let     myName = name.trimmingCharacters( in: .whitespacesAndNewlines )
        
        
        if !myName.isEmpty
        {
            if self.isFormulaUnique( name: myName )
            {
                let     chefbookCentral  = ChefbookCentral.sharedInstance
                let     myYieldQuantity  = yieldQuantity.trimmingCharacters( in: .whitespacesAndNewlines )
                let     myYieldWeight    = yieldWeight  .trimmingCharacters( in: .whitespacesAndNewlines )
 
                if self.indexOfItemBeingEdited == NEW_RECIPE
                {
                    chefbookCentral.addFormulaRecipe( name           : myName,
                                                      yieldQuantity  : Int( myYieldQuantity ) ?? 0,
                                                      yieldWeight    : Int( myYieldWeight   ) ?? 0 )
                }
                else
                {
                    let     recipe = chefbookCentral.recipeArray[indexOfItemBeingEdited]

                    recipe.name                 = myName
                    recipe.formulaYieldQuantity = Int16( myYieldQuantity ) ?? 0
                    recipe.formulaYieldWeight   = Int16( myYieldWeight   ) ?? 0
                    
                    chefbookCentral.saveUpdatedRecipe( recipe: recipe )
                }
                
            }
            else
            {
                logTrace( "ERROR:  Duplicate formula name!" )
                let     alert    = UIAlertController.init( title          : NSLocalizedString( "AlertTitle.Error",                  comment: "Error!" ),
                                                           message        : NSLocalizedString( "AlertMessage.DuplicateFormulaName", comment: "The recipe name you choose already exists.  Please try again." ),
                                                           preferredStyle : .alert)
                let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
                { ( alertAction ) in
                    logTrace( "OK Action" )
                    
                    self.editFormulaNameAndYield()
                }
                
                alert.addAction( okAction )
                
                present( alert, animated: true, completion: nil )
            }
            
        }
        else
        {
            logTrace( "ERROR:  Name field cannot be left blank!" )
            let     alert    = UIAlertController.init( title          : NSLocalizedString( "AlertTitle.Error",               comment: "Error!" ),
                                                       message        : NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank." ),
                                                       preferredStyle : .alert)
            let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
            { ( alertAction ) in
                logTrace( "OK Action" )
                
                self.editFormulaNameAndYield()
            }
            
            alert.addAction( okAction )
            
            present( alert, animated: true, completion: nil )
        }
        
    }
    
    
}
