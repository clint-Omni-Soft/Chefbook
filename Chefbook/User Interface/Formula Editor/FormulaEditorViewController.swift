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
                                   FormulaPreFermentTableViewCellDelegate,
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

    private struct CellIdentifiers {
        static let ingredients   = "FormulaIngredientTableViewCell"
        static let name          = "FormulaNameTableViewCell"
        static let preFerment    = "FormulaPreFermentTableViewCell"
        static let sectionHeader = "SectionHeaderView"
        static let yield         = "FormulaYieldTableViewCell"
    }
    
    private struct CellIndexes {
        static let name         = 0
        static let yield        = 1
        static let ingredients  = 2
    }
    
    private struct StoryboardIds {
        static let imageViewer   = "ImageViewController"
        static let poolishEditor = "PoolishEditorViewController"
    }
    
    private enum StateMachine {
        case name
        case yield
        case ingredients
    }
    
    private var     currentState                = StateMachine.name
    private var     indexPathOfCellBeingEdited  = IndexPath(item: 0, section: 0)
    private var     newIngredientForSection     = ForumlaTableSections.none
    private var     waitingForNotification      = false
    private var     weightOfFlour               = 0

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        title = NSLocalizedString( "Title.BreadFormulaEditor", comment: "Bread Formula Editor" )
        
        preferredContentSize = CGSize( width: 320, height: 460 )
        initializeStateMachine()
        initializeTableView()

        if UIDevice.current.userInterfaceIdiom == .pad {
            waitingForNotification = true
        }
        
    }
    

    override func viewWillAppear(_ animated: Bool ) {
        logTrace()
        super.viewWillAppear( animated )
        
        ChefbookCentral.sharedInstance.delegate = self

        configureBarButtonItem()
        myTableView.reloadData()
        
        NotificationCenter.default.addObserver( self,
                                                selector : #selector( self.keyboardWillHideNotification( notification: ) ),
                                                name     : UIResponder.keyboardWillHideNotification,
                                                object   : nil )
        NotificationCenter.default.addObserver( self,
                                                selector : #selector( self.keyboardWillShowNotification( notification: ) ),
                                                name     : UIResponder.keyboardWillShowNotification,
                                                object   : nil )
        NotificationCenter.default.addObserver( self,
                                                selector : #selector( self.recipeSelected( notification: ) ),
                                                name     : NSNotification.Name( rawValue: NOTIFICATION_RECIPE_SELECTED ),
                                                object   : nil )
        NotificationCenter.default.addObserver( self,
                                                selector : #selector( self.recipesUpdated( notification: ) ),
                                                name     : NSNotification.Name( rawValue: NOTIFICATION_RECIPES_UPDATED ),
                                                object   : nil )
   }
    
    
    override func viewWillDisappear(_ animated: Bool ) {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
    }
    
    
    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    

    // MARK: ChefbookCentralDelegate Methods
    
    func chefbookCentral( chefbookCentral : ChefbookCentral,
                          didOpenDatabase : Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
    }
    
    
    func chefbookCentralDidReloadRecipeArray( chefbookCentral : ChefbookCentral ) {
        logVerbose( "loaded [ %d ] recipes ... recipeIndex[ %d ]", chefbookCentral.recipeArray.count, recipeIndex )
        
        logVerbose( "recovering recipeIndex[ %d ] from chefbookCentral", chefbookCentral.selectedRecipeIndex )
        recipeIndex = chefbookCentral.selectedRecipeIndex

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            self.myTableView.reloadData()
        })

    }
    
    
    
    // MARK: FormulaIngredientTableViewCellDelegate Methods
    
    func formulaIngredientTableViewCell( formulaIngredientTableViewCell : FormulaIngredientTableViewCell,
                                         ingredientIndexPath            : IndexPath,
                                         isNew                          : Bool,
                                         editedIngredientName           : String,
                                         editedPercentage               : String ) {
        logTrace()
        processIngredientInputs( ingredientIndexPath : ingredientIndexPath,
                                 isNew               : isNew,
                                 ingredientName      : editedIngredientName,
                                 percentOfFlour      : editedPercentage )
    }
    
    
    func formulaIngredientTableViewCell( formulaIngredientTableViewCell : FormulaIngredientTableViewCell,
                                         ingredientIndexPath            : IndexPath,
                                         didStartEditing                : Bool )
    {
        logVerbose( "[ %d ][ %d ]", ingredientIndexPath.section, ingredientIndexPath.row )
        indexPathOfCellBeingEdited = ingredientIndexPath
    }

    
    
    
    // MARK: FormulaNameTableViewCellDelegate Methods
    
    func formulaNameTableViewCell( formulaNameTableViewCell : FormulaNameTableViewCell,
                                   editedName               : String ) {
        logTrace()
        processNameInput( name: editedName )
    }
    
    
    
    // MARK: FormulaPreFermentTableViewCellDelegate Methods
    
    func formulaPreFermentTableViewCell( formulaPreFermentTableViewCell : FormulaPreFermentTableViewCell,
                                         indexPath                      : IndexPath,
                                         editedName                     : String,
                                         editedPercentage               : String,
                                         editedWeight                   : String ) {
        logTrace()
        processInputsForPreFerment( name       : editedName,
                                    percentage : editedPercentage,
                                    weight     : editedWeight )
    }

    
    func formulaPreFermentTableViewCell( formulaPreFermentTableViewCell : FormulaPreFermentTableViewCell,
                                         indexPath                      : IndexPath,
                                         didStartEditing                : Bool ) {
        
        logVerbose( "[ %d ][ %d ]", indexPath.section, indexPath.row )
        indexPathOfCellBeingEdited = indexPath
    }

    
    
    // MARK: FormulaYieldTableViewCellDelegate Methods

    func formulaYieldTableViewCell( formulaYieldTableViewCell : FormulaYieldTableViewCell,
                                    editedQuantity            : String,
                                    editedWeight              : String ) {
        logTrace()
        processYieldInputs( yieldQuantity : editedQuantity,
                            yieldWeight   : editedWeight )
    }

    

    // MARK: NSNotification Methods
    
    @objc func keyboardWillHideNotification( notification: NSNotification ) {
        logTrace()
        scrollCellBeingEdited( keyboardWillShow : false,
                               topOfKeyboard    : topOfKeyboardFromNotification( notification: notification ) )
    }
    
    
    @objc func keyboardWillShowNotification( notification: NSNotification ) {
        logTrace()
        scrollCellBeingEdited( keyboardWillShow : true,
                               topOfKeyboard    : topOfKeyboardFromNotification( notification: notification ) )
    }
    
    
    @objc func recipeSelected( notification: NSNotification ) {
        logTrace()
        waitingForNotification = false
        
        configureBarButtonItem()

        myTableView.reloadData()
    }
    
    
    @objc func recipesUpdated( notification: NSNotification ) {
        let     chefbookCentral = ChefbookCentral.sharedInstance
        
        
        if waitingForNotification {
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
                            didRequestAddFor section : Int) {
        logVerbose( "[ %d ]", section )
        
        if section == ForumlaTableSections.preFerment {
            presentPreFermentOptions( sectionHeaderView : sectionHeaderView )
        }
        else {
            newIngredientForSection = section
        }
        
        myTableView.reloadData()
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func cancelBarButtonTouched( sender : UIBarButtonItem ) {
        logTrace()
        dismissView()
    }
    
    
    
    // MARK: UIPopoverPresentationControllerDelegate Methods
    
    func adaptivePresentationStyle(for controller : UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
    
    // MARK: UITableViewDataSource Methods
    
    func numberOfSections( in tableView : UITableView ) -> Int {
        var numberOfSections = 0
        
        
        if !waitingForNotification {
            numberOfSections = ( currentState == .name || currentState == .yield ) ? 1 : 4
        }
        
//        logVerbose( "[ %d ]", numberOfSections )
        
        return numberOfSections
    }
    
    
    func tableView(_ tableView                     : UITableView,
                     numberOfRowsInSection section : Int ) -> Int {
        
        let chefbookCentral = ChefbookCentral.sharedInstance
        var numberOfRows    = 0

        if !waitingForNotification {
            
            switch section {
            case ForumlaTableSections.nameAndYield:
                switch currentState {
                case .name:     numberOfRows = 1
                case .yield:    numberOfRows = 2
                default:        numberOfRows = 3    // 3rd row is the % Name Weight header for the following sections
                }
                
            case ForumlaTableSections.flour:
                let     indexOfNextFlourComponent = chefbookCentral.recipeArray[recipeIndex].flourIngredients?.count ?? 0
                
                numberOfRows = indexOfNextFlourComponent + ( newIngredientForSection == ForumlaTableSections.flour ? 1 : 0 )
                
            case ForumlaTableSections.ingredients:
                let     indexOfNextIngredient = chefbookCentral.recipeArray[recipeIndex].breadIngredients?.count ?? 0
                
                numberOfRows = indexOfNextIngredient + ( newIngredientForSection == ForumlaTableSections.ingredients ? 1 : 0 )
                
            case ForumlaTableSections.preFerment:
                if chefbookCentral.recipeArray[recipeIndex].preFerment != nil {
                    numberOfRows = 1
                }
                else if chefbookCentral.recipeArray[recipeIndex].poolish != nil {
                    numberOfRows = 1
                }
                
            default:
                numberOfRows = 0
            }
            
        }
        
//        logVerbose( "[ %d ][ %d ]", section, numberOfRows )
        
        return numberOfRows
    }
    
    
    func tableView(_ tableView              : UITableView,
                     cellForRowAt indexPath : IndexPath) -> UITableViewCell {
//        logVerbose( "row[ %d ]", indexPath.row)
        var     cell : UITableViewCell!
        
        switch indexPath.section {
            
        case ForumlaTableSections.nameAndYield:
            
            switch indexPath.row {
            case 0:     cell = loadFormulaNameCell()
            case 1:     cell = loadFormulaYieldCell()
            default:    cell = loadFormulaIngredientCellFor( indexPath: indexPath )     // Creates the % Name Weight header for the following sections
            }
            
        case ForumlaTableSections.flour:
            cell = loadFormulaIngredientCellFor( indexPath: indexPath )
            
        case ForumlaTableSections.ingredients:
            cell = loadFormulaIngredientCellFor( indexPath: indexPath )
            
        default:
            cell = loadFormulaPreFermentCellFor( indexPath: indexPath )
        }
        
        return cell
    }
    
    
    func tableView(_ tableView              : UITableView,
                     canEditRowAt indexPath : IndexPath) -> Bool {
        let canEdit = indexPath.section != ForumlaTableSections.nameAndYield
        
        return canEdit
    }
    
    
    func tableView(_ tableView           : UITableView,
                     commit editingStyle : UITableViewCell.EditingStyle,
                     forRowAt indexPath  : IndexPath) {
        
        if editingStyle == .delete {
            logVerbose( "delete ingredient at row [ %d ]", indexPath.row )
            
            DispatchQueue.main.asyncAfter(deadline: ( .now() + 0.2 ), execute: {
                let  chefbookCentral = ChefbookCentral.sharedInstance
                
                chefbookCentral.selectedRecipeIndex = self.recipeIndex
                
                switch indexPath.section {
                case ForumlaTableSections.flour:
                    chefbookCentral.deleteFormulaRecipeFlourIngredientAt( index: indexPath.row )

                case ForumlaTableSections.ingredients:
                    chefbookCentral.deleteFormulaRecipeBreadIngredientAt( index: indexPath.row )

                case ForumlaTableSections.preFerment:
                    if chefbookCentral.recipeArray[self.recipeIndex].preFerment != nil {
                        chefbookCentral.deleteFormulaRecipePreFerment()
                    }
                    else if chefbookCentral.recipeArray[self.recipeIndex].poolish != nil {
                        chefbookCentral.deleteFormulaRecipePoolish()
                    }
                
                default:
                    break
                }
                
            })
            
        }
        
    }
    

    
    // MARK: UITableViewDelegate Methods
    
    func tableView(_ tableView                : UITableView,
                     didSelectRowAt indexPath : IndexPath ) {
        
//        tableView.deselectRow( at: indexPath, animated: false )
        if indexPath.section == ForumlaTableSections.preFerment && ChefbookCentral.sharedInstance.recipeArray[self.recipeIndex].poolish != nil {
            
            if let sectionHeaderView = tableView.headerView( forSection: indexPath.section ) as? SectionHeaderView {
                loadPoolishEditorPopover( sectionHeaderView: sectionHeaderView )
            }
            
        }

    }
    
    
    func tableView(_ tableView                        : UITableView,
                     heightForHeaderInSection section : Int ) -> CGFloat {
        
        let     height = section == ForumlaTableSections.nameAndYield ? 0.0 : 44.0 as CGFloat
        
        return height
    }
    
    
    func tableView(_ tableView                      : UITableView,
                     viewForHeaderInSection section : Int ) -> UIView? {
        
        let     sectionHeaderView = tableView.dequeueReusableHeaderFooterView( withIdentifier: SectionHeaderView.reuseIdentifier ) as? SectionHeaderView
        var     hideAddButton     = false
        var     title             = ""
        
        switch section {
        case ForumlaTableSections.flour:
            title = String( format: "100     %@", NSLocalizedString( "SectionTitle.Flour", comment: "Flour" ) )
        case ForumlaTableSections.ingredients:
            title = String( format: "        %@", NSLocalizedString( "SectionTitle.Ingredients", comment: "Ingredients" ) )
        default: // ForumlaTableSections.preFerment
            title = String( format: "        %@", NSLocalizedString( "SectionTitle.PreFerment", comment: "PreFerment" ) )
            
            hideAddButton = ( ChefbookCentral.sharedInstance.recipeArray[recipeIndex].poolish != nil ) || ( ChefbookCentral.sharedInstance.recipeArray[recipeIndex].preFerment != nil )
        }
        
        sectionHeaderView?.initWith( title          : title,
                                     for            : section,
                                     hideAddButton  : hideAddButton,
                                     with           : self )
        return sectionHeaderView
    }
    
    
    
    // MARK: Utility Methods
    
    private func configureBarButtonItem() {
        
        let     launchedFromMasterView = UIDevice.current.userInterfaceIdiom == .pad
        let     title                  = launchedFromMasterView ? NSLocalizedString( "ButtonTitle.Done", comment: "Done" ) : NSLocalizedString( "ButtonTitle.Back",   comment: "Back"   )
        
        navigationItem.leftBarButtonItem  = ( waitingForNotification ? nil : UIBarButtonItem.init( title: title,
                                                                                                   style: .plain,
                                                                                                   target: self,
                                                                                                   action: #selector( cancelBarButtonTouched ) ) )
    }
    
    
    private func dismissView() {
        
        logTrace()
        if UIDevice.current.userInterfaceIdiom == .pad {
            let detailNavigationViewController = ( ( (self.splitViewController?.viewControllers.count)! > 1 ) ? self.splitViewController?.viewControllers[1] : nil ) as? UINavigationController
            
            // Move the visible viewController off the screen
            detailNavigationViewController?.visibleViewController?.view.frame = CGRect( x: 0, y: 0, width: 0, height: 0 )
            navigationItem.leftBarButtonItem = nil
        }
        else {
            navigationController?.popViewController( animated: true )
        }
        
    }
    
    
    private func ingredientAt( indexPath: IndexPath ) -> BreadIngredient {
        
        let     recipe           = ChefbookCentral.sharedInstance.recipeArray[self.recipeIndex]
        let     dataSource       = ( indexPath.section == ForumlaTableSections.flour ) ? recipe.flourIngredients : recipe.breadIngredients
        let     ingredientsArray = dataSource?.allObjects as! [BreadIngredient]
        var     breadIngredient  : BreadIngredient!
        
        
        for ingredient in ingredientsArray {
            
            if ingredient.index == indexPath.row {
                breadIngredient = ingredient
                break
            }
            
        }
        
        return breadIngredient
    }
    
    
    private func initializeStateMachine() {
        
        logTrace()
        if recipeIndex == NEW_RECIPE {
            currentState = StateMachine.name
        }
        else {
            let recipe = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
            
            
            currentState = ( recipe.formulaYieldQuantity == 0 || recipe.formulaYieldWeight == 0 ) ? .yield : .ingredients
        }
        
    }
    
    
    private func initializeTableView() {
        logTrace()
        var         frame = CGRect.zero
        
        frame.size.height = .leastNormalMagnitude

        myTableView.contentInsetAdjustmentBehavior = .never
        myTableView.separatorStyle                 = .none
        myTableView.tableHeaderView                = UIView( frame: frame )
        myTableView.tableFooterView                = UIView( frame: frame )
        
        myTableView.register( SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderView.reuseIdentifier )   // this form is required for programmatic header construction
    }
    
    
    private func isFormulaUnique( name: String ) -> Bool {
        
        let     chefbookCentral   = ChefbookCentral.sharedInstance
        var     numberOfInstances = 0
        
        for recipe in chefbookCentral.recipeArray {
            
            if ( name.uppercased() == recipe.name?.uppercased() ) {
                
                if recipeIndex == NEW_RECIPE {
                    
                    logTrace( "Found a duplicate! [New]." )
                    numberOfInstances += 1
                }
                else {
                    let     recipeBeingEdited = chefbookCentral.recipeArray[recipeIndex]
                   
                    if recipe.guid != recipeBeingEdited.guid {
                        
                        logTrace( "Found a duplicate! [Existing]." )
                        numberOfInstances += 1
                    }
                    
                }
                
            }
            
        }
        
        return ( numberOfInstances == 0 )
    }
    
    
    private func isIngredientUniqueAt( indexPath : IndexPath,
                                       name      : String ) -> Bool {
        
        let     chefbookCentral  = ChefbookCentral.sharedInstance
        var     isUnique         = true
        let     recipe           = chefbookCentral.recipeArray[recipeIndex]
        let     ingredientsArray = indexPath.section == 1 ? recipe.flourIngredients?.allObjects as! [BreadIngredient] : recipe.breadIngredients?.allObjects as! [BreadIngredient]
        
        for ingredient in ingredientsArray {
            
            if ( ingredient.name == name ) && ( indexPath.row != ingredient.index ) {
                isUnique = false
                break
            }
            
        }
        
        return isUnique
    }
    
    
    private func loadFormulaIngredientCellFor( indexPath: IndexPath ) -> UITableViewCell {
        
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.ingredients ) else {
            
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
//        logVerbose( "section[ %d ] row[ %d ]", indexPath.section, indexPath.row )
        let     formulaIngredientCell = cell as! FormulaIngredientTableViewCell
        
        if indexPath.section == ForumlaTableSections.nameAndYield {
            
            formulaIngredientCell.setupAsHeader()
        }
        else {
            let     recipe             = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
            let     dataSource         = indexPath.section == ForumlaTableSections.flour ? recipe.flourIngredients : recipe.breadIngredients
            let     lastIngredientRow  = dataSource?.count ?? 0
            let     isNewIngredientRow = newIngredientForSection == indexPath.section && lastIngredientRow == indexPath.row
            
            formulaIngredientCell.initializeWithRecipeAt( recipeIndex         : recipeIndex,
                                                          ingredientIndexPath : indexPath,
                                                          isNew               : isNewIngredientRow,
                                                          delegate            : self )
        }
        
        return cell
    }
    
    
    private func loadFormulaNameCell() -> UITableViewCell {
        
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.name ) else {
            
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
    
    
    private func loadFormulaPreFermentCellFor(indexPath : IndexPath) -> UITableViewCell {
        
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.preFerment ) else {
            
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
//        logTrace()
        let     formulaPreFermentCell = cell as! FormulaPreFermentTableViewCell
        
        formulaPreFermentCell.initializeWithRecipeAt( recipeIndex : recipeIndex,
                                                      indexPath   : indexPath,
                                                      delegate    : self )
        return cell
    }
    
    
    private func loadFormulaYieldCell() -> UITableViewCell {
        
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.yield ) else {
            
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
//        logTrace()
        let     formulaYieldCell = cell as! FormulaYieldTableViewCell
        var     loafWeight       = 0
        var     numberOfLoaves   = 0

        if recipeIndex != NEW_RECIPE {
            
            let recipe = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]

            numberOfLoaves = Int( recipe.formulaYieldQuantity )
            loafWeight     = Int( recipe.formulaYieldWeight   )
        }
        
        formulaYieldCell.initializeWith( quantity : numberOfLoaves,
                                         weight   : loafWeight,
                                         delegate : self)
        
        return cell
    }
    
    
    private func loadPoolishEditorPopover( sectionHeaderView : SectionHeaderView ) {
        logTrace()
        if let poolishEditorViewController: PoolishEditorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.poolishEditor ) as? PoolishEditorViewController {
            
            let     chefbookCentral         = ChefbookCentral.sharedInstance
            let     recipe                  = chefbookCentral.recipeArray[recipeIndex]
            
            poolishEditorViewController.recipe = recipe

            poolishEditorViewController.modalPresentationStyle = .formSheet
            poolishEditorViewController.preferredContentSize   = CGSize( width: 300.0, height: 440.0 )
            
            poolishEditorViewController.popoverPresentationController?.delegate                 = self
            poolishEditorViewController.popoverPresentationController?.permittedArrowDirections = .any
            poolishEditorViewController.popoverPresentationController?.sourceRect               = sectionHeaderView.frame
            poolishEditorViewController.popoverPresentationController?.sourceView               = view

            // WTF??? I discovered that when this method is invoked from tableView:didSelectRowAt indexPath,
            //        we are not on the main thread!  Looks like a bug to me.
            DispatchQueue.main.async {
                self.present( poolishEditorViewController,
                              animated: true,
                              completion: nil )
            }

        }
        else {
            logTrace( "ERROR: Could NOT load PoolishEditorViewController!" )
        }
        
    }

    
    private func presentPreFermentOptions( sectionHeaderView : SectionHeaderView ) {
        logTrace()
        let     chefbookCentral = ChefbookCentral.sharedInstance
        let     alert           = UIAlertController.init( title          : NSLocalizedString( "AlertTitle.PreFermentOptions", comment: "Pre-Ferment Options" ),
                                                          message        : nil,
                                                          preferredStyle : ( UIDevice.current.userInterfaceIdiom == .phone ? .actionSheet : .alert ) )
        
        let     bigaAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Biga", comment: "Biga" ), style: .default )
        { ( alertAction ) in
            logTrace( "Biga Action" )
            chefbookCentral.selectedRecipeIndex = self.recipeIndex
            
            chefbookCentral.addPreFermentToFormulaRecipeWith( name : NSLocalizedString( "ButtonTitle.Biga", comment: "Biga" ),
                                                              type : PreFermentTypes.biga )
        }
            
        let     poolishAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Poolish", comment: "Poolish" ), style: .default )
        { ( alertAction ) in
            logTrace( "Poolish Action" )
            chefbookCentral.selectedRecipeIndex = self.recipeIndex
            
            self.loadPoolishEditorPopover( sectionHeaderView : sectionHeaderView )
        }
        
        let     sourAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Sour", comment: "Sour" ), style: .default )
        { ( alertAction ) in
            logTrace( "Sour Action" )
            chefbookCentral.selectedRecipeIndex = self.recipeIndex
            
            chefbookCentral.addPreFermentToFormulaRecipeWith( name : NSLocalizedString( "ButtonTitle.Sour", comment: "Sour" ),
                                                              type : PreFermentTypes.sour )
       }
        

        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        alert.addAction( bigaAction    )
        alert.addAction( poolishAction )
        alert.addAction( sourAction    )
        alert.addAction( cancelAction  )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func processIngredientInputs( ingredientIndexPath : IndexPath,
                                          isNew               : Bool,
                                          ingredientName      : String,
                                          percentOfFlour      : String ) {
        logTrace()
        let     newName = ingredientName.trimmingCharacters( in: .whitespacesAndNewlines )
        
        if !newName.isEmpty {
            
            let     chefbookCentral = ChefbookCentral.sharedInstance
            
      
            if self.isIngredientUniqueAt( indexPath: ingredientIndexPath, name: newName ) {
                
                let     myPercentOfFlour = Float( percentOfFlour.trimmingCharacters( in: .whitespacesAndNewlines ) ) ?? 100
                
                chefbookCentral.selectedRecipeIndex = recipeIndex
                
                if isNew {

                    if ingredientIndexPath.section == ForumlaTableSections.flour {
                        
                        chefbookCentral.addBreadIngredientToFormulaRecipeAt( index      : ( chefbookCentral.recipeArray[self.recipeIndex].flourIngredients?.count ?? 0 ),
                                                                             isFlour    : true,
                                                                             name       : newName,
                                                                             percentage : Int( myPercentOfFlour ) )
                    }
                    else {
                        chefbookCentral.addBreadIngredientToFormulaRecipeAt( index      : ( chefbookCentral.recipeArray[self.recipeIndex].breadIngredients?.count ?? 0 ),
                                                                             isFlour    : false,
                                                                             name       : newName,
                                                                             percentage : Int( myPercentOfFlour ) )
                    }

                    newIngredientForSection = ForumlaTableSections.none
                }
                else {
                    let     ingredient        = ingredientAt( indexPath: ingredientIndexPath )
                    let     recipe            = chefbookCentral.recipeArray[recipeIndex]
                    let     updatePercentages = ingredient.percentOfFlour != Int16( myPercentOfFlour )
                    
                    ingredient.name           = newName
                    ingredient.percentOfFlour = Int16( myPercentOfFlour )
                    
                    if updatePercentages {
                        chefbookCentral.adjustFlourIngredientsPercentagesIn( recipe             : recipe,
                                                                             aroundIngredientAt : ingredientIndexPath.row )
                    }
                    
                    chefbookCentral.updateIngredientsIn( recipe: recipe )
                    chefbookCentral.saveUpdatedRecipe(   recipe: recipe )
                }
                
            }
            else {
                logTrace( "ERROR:  Duplicate ingredient name!" )
                presentAlert( title   : NSLocalizedString( "AlertTitle.Error",                     comment: "Error!" ),
                              message : NSLocalizedString( "AlertMessage.DuplicateIngredientName", comment: "The ingredient name you choose already exists.  Please try again." ) )
            }
            
        }
        else {
            logTrace( "ERROR:  Name field cannot be left blank!" )
            presentAlert( title   : NSLocalizedString( "AlertTitle.Error",               comment: "Error!" ),
                          message : NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank." ) )
        }
        
    }
    
    
   private func processNameInput( name : String ) {
    
        logTrace()
        let     myName = name.trimmingCharacters( in: .whitespacesAndNewlines )
        
        if !myName.isEmpty {
            
            if self.isFormulaUnique( name: myName ) {
                
                let     chefbookCentral = ChefbookCentral.sharedInstance
 
                if self.recipeIndex == NEW_RECIPE {
                    
                    currentState = StateMachine.yield
                    
                    chefbookCentral.addFormulaRecipe( name          : myName,
                                                      yieldQuantity : 0,
                                                      yieldWeight   : 0 )
                }
                else {
                    let     recipe = chefbookCentral.recipeArray[recipeIndex]

                    recipe.name = myName
                    
                    chefbookCentral.saveUpdatedRecipe( recipe: recipe )
                }
                
            }
            else {
                logTrace( "ERROR:  Duplicate formula name!" )
                presentAlert( title   : NSLocalizedString( "AlertTitle.Error",                  comment: "Error!" ),
                              message : NSLocalizedString( "AlertMessage.DuplicateFormulaName", comment: "The recipe name you choose already exists.  Please try again." ) )
            }
            
        }
        else {
            logTrace( "ERROR:  Name field cannot be left blank!" )
            presentAlert( title   : NSLocalizedString( "AlertTitle.Error",               comment: "Error!" ),
                          message : NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank." ) )
        }
        
    }
    
    
    private func processInputsForPreFerment( name       : String,
                                             percentage : String,
                                             weight     : String ) {
        logTrace()
        let     chefbookCentral  = ChefbookCentral.sharedInstance
        let     myName           = name.trimmingCharacters( in: .whitespaces )
        let     myPercentage     = Int( percentage ) ?? 0
        let     myWeight         = Int( weight ) ?? 0
        let     recipe           = chefbookCentral.recipeArray[recipeIndex]

        
        if let preFerment = recipe.preFerment {
            
            preFerment.name           = myName
            preFerment.percentOfTotal = Int16( myPercentage )
            preFerment.weight         = Int64( myWeight )
            
            chefbookCentral.saveUpdatedRecipe( recipe : recipe )
        }

    }


    private func processYieldInputs( yieldQuantity : String,
                                     yieldWeight   : String ) {
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
    
    private var originalViewOffset : CGFloat = 0.0
    
    private func scrollCellBeingEdited( keyboardWillShow : Bool,     // false == willHide
                                        topOfKeyboard    : CGFloat ) {
        
        if indexPathOfCellBeingEdited.section == 0 {
            return
        }
        
        let     frame  = myTableView.frame
        var     origin = frame.origin

//        logVerbose( "[ %d ][ %d ] willShow[ %@ ] topOfKeyboard[ %f ]", indexPathOfCellBeingEdited.section, indexPathOfCellBeingEdited.row, stringFor( keyboardWillShow ), topOfKeyboard )
        if !keyboardWillShow {
            origin.y = ( originalViewOffset == 0.0 ) ? origin.y : originalViewOffset
        }
        else {
            originalViewOffset = origin.y
            
            if let cellBeingEdited = myTableView.cellForRow( at: indexPathOfCellBeingEdited ) {
                let     cellBottomY     = ( cellBeingEdited.frame.origin.y + cellBeingEdited.frame.size.height ) + originalViewOffset
                let     keyboardOverlap = topOfKeyboard - cellBottomY

//                logVerbose( "cellBottomY[ %f ]  keyboardOverlap[ %f ]", cellBottomY, keyboardOverlap )
                if keyboardOverlap < 0.0 {
                    origin.y = origin.y + keyboardOverlap
                }
                
            }
            
        }
        
//        logVerbose( "originalViewOffset[ %f ]", originalViewOffset )
        myTableView.frame = CGRect( origin: origin, size: frame.size )
    }


    private func topOfKeyboardFromNotification( notification : NSNotification ) -> CGFloat {
        
        var     topOfKeyboard : CGFloat = 1000.0
        
        if let userInfo = notification.userInfo {
            let     endFrame = ( userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue )?.cgRectValue
            
            topOfKeyboard = endFrame?.origin.y ?? 1000.0 as CGFloat
        }
        
//        logVerbose( "topOfKeyboard[ %f ]", topOfKeyboard )
        return topOfKeyboard
    }
    
    
}
