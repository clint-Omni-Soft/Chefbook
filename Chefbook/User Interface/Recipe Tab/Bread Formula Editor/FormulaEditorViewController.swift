//
//  FormulaEditorViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 9/3/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


class FormulaEditorViewController: UIViewController
{
    
    // MARK: Public Variables

    var     recipeIndex : Int!                        // Set by caller

    
    @IBOutlet weak var myTableView: UITableView!
    

    // MARK: Private Variables

    private struct CellIdentifiers {
        static let image         = "FormulaImageTableViewCell"
        static let ingredients   = "FormulaIngredientTableViewCell"
        static let name          = "FormulaNameTableViewCell"
        static let preFerment    = "FormulaPreFermentTableViewCell"
        static let sectionHeader = "SectionHeaderView"
        static let yield         = "FormulaYieldTableViewCell"
    }
    
    private struct CellIndexes {
        static let name         = 0
        static let yield        = 1
        static let image        = 2
        static let ingredients  = 3
    }
    
    private enum StateMachine {
        case name
        case yield
        case ingredients
    }
    
    private struct StoryboardIds {
        static let imageViewer         = "ImageViewController"
        static let poolishEditor       = "PoolishEditorViewController"
        static let provisioningSummary = "ProvisioningSummaryViewController"
    }
    
    private var     currentState                    = StateMachine.name
    private var     imageCell                       : FormulaImageTableViewCell!     // Set in FormulaImageTableViewCellDelegate Method
    private var     indexPathOfCellBeingEdited      = IndexPath(item: 0, section: 0)
    private var     loadingImageView                = false
    private var     newIngredientForSection         = ForumlaTableSections.none
    private var     originalViewOffset : CGFloat    = 0.0
    private var     waitingForDidHideNotification   = false
    private var     waitingForNotification          = false
    private var     weightOfFlour                   = 0

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        self.navigationItem.title = NSLocalizedString( "Title.BreadFormulaEditor", comment: "Bread Formula Editor" )
        
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

        loadBarButtonItems()
        myTableView.reloadData()
        
        NotificationCenter.default.addObserver( self,
                                                selector : #selector( self.keyboardWillHideNotification( notification: ) ),
                                                name     : UIResponder.keyboardWillHideNotification,
                                                object   : nil )
        NotificationCenter.default.addObserver( self,
                                                selector : #selector( self.keyboardDidShowNotification( notification: ) ),
                                                name     : UIResponder.keyboardDidShowNotification,
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
    
    
    

    // MARK: NSNotification Methods
    
    @objc func keyboardWillHideNotification( notification: NSNotification ) {
        logTrace()
        scrollCellBeingEdited( keyboardDidShow : false,
                               topOfKeyboard   : topOfKeyboardFromNotification( notification ) )
        waitingForDidHideNotification = false
    }
    
    
    @objc func keyboardDidShowNotification( notification: NSNotification ) {
        logVerbose( "waitingForDidHideNotification[ %@ ]", stringFor( waitingForDidHideNotification ) )
        if !waitingForDidHideNotification {
            scrollCellBeingEdited( keyboardDidShow : true,
                                   topOfKeyboard   : topOfKeyboardFromNotification( notification ) )
            waitingForDidHideNotification = true
        }

    }
    
    
    @objc func recipeSelected( notification: NSNotification ) {
        logTrace()
        waitingForNotification = false
        
        loadBarButtonItems()

        myTableView.reloadData()
    }
    
    
    @objc func recipesUpdated( notification: NSNotification ) {
        let     chefbookCentral = ChefbookCentral.sharedInstance
        
        if waitingForNotification {
            logTrace( "ignorning ... waitingForNotification" )
            return
        }
        
        logVerbose( "recovering selectedRecipeIndex[ %@ ] from chefbookCentral", String( chefbookCentral.selectedRecipeIndex ) )
        recipeIndex = chefbookCentral.selectedRecipeIndex
        
        // The reason we are using Notifications is because this view can be up in two different places on the iPad at the same time.
        // This approach allows a change in one to immediately be reflected in the other.
        
        myTableView.reloadData()
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func cancelBarButtonTouched( sender : UIBarButtonItem ) {
        logTrace()
        dismissView()
    }
    
    
    @IBAction @objc func provisionBarButtonItemTouched( barButtonItem: UIBarButtonItem ) {
        logTrace()
        launchProvisioningSummaryViewController()
    }
    
    
    
    // MARK: Utility Methods
    
    private func ensureCellBeingEditedIsVisible() {
        
        let  cellIsVisible = myTableView.indexPathsForVisibleRows?.contains( indexPathOfCellBeingEdited ) ?? false
        
//        logVerbose( "[ %@ ][ %@ ] cellIsVisible[ %@ ]", String( indexPathOfCellBeingEdited.section ), String( indexPathOfCellBeingEdited.row ), stringFor( cellIsVisible ) )
        
        if !cellIsVisible {
            myTableView.scrollToRow(at: indexPathOfCellBeingEdited, at: .middle, animated: true )
        }
        
    }
    
    
    private func deleteImage() {
        
        let     chefbookCentral = ChefbookCentral.sharedInstance
        let     recipe          = chefbookCentral.recipeArray[recipeIndex]

        if let name = recipe.imageName {
            
            if !chefbookCentral.deleteImageWith( name ) {
                
                logVerbose( "ERROR: Unable to delete image[ %@ ]!", name )
                presentAlert( title  : NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                              message: NSLocalizedString( "AlertMessage.UnableToDeleteImage", comment: "We were unable to delete the image you created." ) )
            }
            else {
                recipe.imageName = ""
                
                chefbookCentral.saveUpdated( recipe )
            }

        }
        else {
            logTrace( "ERROR: Could NOT unwrap recipe.imageName!" )
        }

    }
    
    
    private func dismissView() {
        
        logTrace()
        if UIDevice.current.userInterfaceIdiom == .pad {
            let detailNavigationViewController = ( ( (self.splitViewController?.viewControllers.count)! > 1 ) ? self.splitViewController?.viewControllers[1] : nil ) as? UINavigationController
            
            // Move the visible viewController off the screen by shrinking it to zero
            detailNavigationViewController?.visibleViewController?.view.frame = CGRect( x: 0, y: 0, width: 0, height: 0 )
            
            navigationItem.leftBarButtonItem  = nil
            navigationItem.rightBarButtonItem = nil
            navigationItem.title              = ""
        }
        else {
            navigationController?.popViewController( animated: true )
        }
        
    }
    
    
    private func ingredientAt(_ indexPath: IndexPath ) -> BreadIngredient {
        
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
    
    
    private func isIngredientUniqueAt(_ indexPath : IndexPath,
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
    
    
    private func launchImageViewController() {
        
        let     chefbookCentral = ChefbookCentral.sharedInstance
        let     recipe          = chefbookCentral.recipeArray[recipeIndex]
        
        if let name = recipe.imageName {
            
            logVerbose( "imageName[ %@ ]", name )
            if let imageViewController: ImageViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.imageViewer ) as? ImageViewController {
                imageViewController.imageName = name
                
                navigationController?.pushViewController( imageViewController, animated: true )
            }
            else {
                logTrace( "ERROR: Could NOT load ImageViewController!" )
            }

        }
        else {
            logTrace( "ERROR: Could NOT unwrap recipe.imageName!" )
        }

    }
    
    
    private func launchProvisioningSummaryViewController() {
        
        logTrace()
        
        if let summaryVC : ProvisioningSummaryViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.provisioningSummary ) as? ProvisioningSummaryViewController {
            
            summaryVC.myRecipe  = ChefbookCentral.sharedInstance.recipeArray[self.recipeIndex]
            summaryVC.useRecipe = true
            
            let backItem = UIBarButtonItem()
            
            backItem.title = NSLocalizedString( "ButtonTitle.Back", comment: "Back" )
            navigationItem.backBarButtonItem = backItem
            
            navigationController?.pushViewController( summaryVC, animated: true )
        }
        else {
            logTrace( "ERROR: Could NOT load ProvisioningSelectItemsViewController!" )
        }
        
    }
    
    
    
    private func loadBarButtonItems() {
        logTrace()
        let     launchedFromMasterView = UIDevice.current.userInterfaceIdiom == .pad
        let     title                  = launchedFromMasterView ? NSLocalizedString( "ButtonTitle.Done", comment: "Done" ) : NSLocalizedString( "ButtonTitle.Back",   comment: "Back"   )
        
        navigationItem.leftBarButtonItem  = ( waitingForNotification ? nil : UIBarButtonItem.init( title: title,
                                                                                                   style: .plain,
                                                                                                   target: self,
                                                                                                   action: #selector( cancelBarButtonTouched ) ) )
        
        navigationItem.rightBarButtonItem = ( waitingForNotification ? nil : UIBarButtonItem.init( title: NSLocalizedString( "ButtonTitle.Summary", comment: "Summary" ),
                                                                                                   style: .plain,
                                                                                                   target: self,
                                                                                                   action: #selector( provisionBarButtonItemTouched ) ) )
    }
    
    
    private func loadPoolishEditorPopoverFrom(_ sectionHeaderView : SectionHeaderView ) {
        logTrace()
        if let poolishEditorViewController: PoolishEditorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.poolishEditor ) as? PoolishEditorViewController {
            
            let     chefbookCentral         = ChefbookCentral.sharedInstance
            let     recipe                  = chefbookCentral.recipeArray[recipeIndex]
            
            poolishEditorViewController.recipe = recipe

            poolishEditorViewController.modalPresentationStyle = .formSheet
            poolishEditorViewController.preferredContentSize   = CGSize( width: 320.0, height: 440.0 )
            
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
            
            self.loadPoolishEditorPopoverFrom( sectionHeaderView )
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
            
      
            if self.isIngredientUniqueAt( ingredientIndexPath, name: newName ) {
                
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
                    let     ingredient        = ingredientAt( ingredientIndexPath )
                    let     recipe            = chefbookCentral.recipeArray[recipeIndex]
                    let     updatePercentages = ingredient.percentOfFlour != Int16( myPercentOfFlour )
                    
                    ingredient.name           = newName
                    ingredient.percentOfFlour = Int16( myPercentOfFlour )
                    
                    if updatePercentages {
                        chefbookCentral.adjustFlourIngredientsPercentagesIn( recipe             : recipe,
                                                                             aroundIngredientAt : ingredientIndexPath.row )
                    }
                    
                    chefbookCentral.updateBreadFormulaIngredientsIn( recipe )
                    chefbookCentral.saveUpdated( recipe )
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
            
            chefbookCentral.saveUpdated( recipe )
        }

    }


    private func processNameInput(_ name : String ) {
        logTrace()
        let     myName = name.trimmingCharacters( in: .whitespacesAndNewlines )
        
        if !myName.isEmpty {
            
            if self.unique( myName ) {
                
                let     chefbookCentral = ChefbookCentral.sharedInstance
                
                if self.recipeIndex == NEW_RECIPE {
                    currentState = .yield
                    
                    chefbookCentral.addFormulaRecipe( myName )
                }
                else {
                    let     recipe = chefbookCentral.recipeArray[recipeIndex]
                    
                    recipe.name = myName
                    chefbookCentral.saveUpdated( recipe )
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
        
        chefbookCentral.updateBreadFormulaIngredientsIn( recipe )
        chefbookCentral.saveUpdated( recipe )
    }
    
    
    private func scrollCellBeingEdited( keyboardDidShow : Bool,     // false == willHide
                                        topOfKeyboard   : CGFloat ) {
        
        if indexPathOfCellBeingEdited.section == 0 {
            return
        }
        
        let     frame  = myTableView.frame
        var     origin = frame.origin

//        logVerbose( "[ %@ ][ %@ ] willShow[ %@ ] topOfKeyboard[ %@ ]", String( indexPathOfCellBeingEdited.section ), String( indexPathOfCellBeingEdited.row ), stringFor( keyboardWillShow ), String( topOfKeyboard ) )
        if !keyboardDidShow {
            origin.y = ( originalViewOffset == 0.0 ) ? origin.y : originalViewOffset
        }
        else {
            originalViewOffset = origin.y
            
            if let cellBeingEdited = myTableView.cellForRow( at: indexPathOfCellBeingEdited ) {
                let     cellBottomY     = ( cellBeingEdited.frame.origin.y + cellBeingEdited.frame.size.height ) + originalViewOffset
                let     keyboardOverlap = topOfKeyboard - cellBottomY

//                logVerbose( "cellBottomY[ %@ ]  keyboardOverlap[ %@ ]", String( cellBottomY ), String( keyboardOverlap ) )
                if keyboardOverlap < 0.0 {
                    origin.y = origin.y + keyboardOverlap
                }
                
            }
            
        }
        
//        logVerbose( "keyboardDidShow[ %@ ]  originalViewOffset[ %@ ]", stringFor( keyboardDidShow ), String( originalViewOffset ) )
        myTableView.frame = CGRect( origin: origin, size: frame.size )
    }


    private func topOfKeyboardFromNotification(_ notification : NSNotification ) -> CGFloat {
        
        var     topOfKeyboard : CGFloat = 1000.0
        
        if let userInfo = notification.userInfo {
            let     endFrame = ( userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue )?.cgRectValue
            
            topOfKeyboard = endFrame?.origin.y ?? 1000.0 as CGFloat
        }
        
//        logVerbose( "topOfKeyboard[ %@ ]", String( topOfKeyboard ) )
        return topOfKeyboard
    }
    
    
    private func unique(_ name: String ) -> Bool {
        
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
    
    
}



// MARK: ChefbookCentralDelegate Methods

extension FormulaEditorViewController : ChefbookCentralDelegate {
    
    func chefbookCentral( chefbookCentral : ChefbookCentral,
                          didOpenDatabase : Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
    }
    
    
    func chefbookCentralDidReloadProvisionArray(chefbookCentral: ChefbookCentral) {
        logVerbose( "loaded [ %@ ] provisions", String( chefbookCentral.provisionArray.count ) )
    }
    
    
    func chefbookCentralDidReloadRecipeArray( chefbookCentral : ChefbookCentral ) {
//        logVerbose( "loaded [ %@ ] recipes ... current recipeIndex[ %@ ] ... recovering [ %@ ] from chefbookCentral", String( chefbookCentral.recipeArray.count ), String( recipeIndex ), String( chefbookCentral.selectedRecipeIndex ) )
        recipeIndex = chefbookCentral.selectedRecipeIndex
        
        if loadingImageView {
            
            loadingImageView = false
            launchImageViewController()
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self.myTableView.reloadData()
            })
            
        }
        
    }
    
    
}



// MARK: FormulaIngredientTableViewCellDelegate Methods

extension FormulaEditorViewController : FormulaImageTableViewCellDelegate {
    
    func formulaImageTableViewCell( formulaImageTableViewCell: FormulaImageTableViewCell,
                                    cameraButtonTouched: Bool) {
        logTrace()
        imageCell = formulaImageTableViewCell
        
        let     recipe = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
        
        if recipe.imageName?.isEmpty ?? true {
            promptForImageSource()
        }
        else {
            promptForImageDispostion()
        }
        
    }
    

    private func openImagePickerFor( sourceType: UIImagePickerController.SourceType ) {
        
        logVerbose( "[ %@ ]", ( ( .camera == sourceType ) ? "Camera" : "Photo Album" ) )
        let     imagePickerVC = UIImagePickerController.init()
        
        imagePickerVC.allowsEditing = false
        imagePickerVC.delegate      = self
        imagePickerVC.sourceType    = sourceType
        
        imagePickerVC.modalPresentationStyle = ( ( .camera == sourceType ) ? .overFullScreen : .popover )
        
        present( imagePickerVC, animated: true, completion: nil )
        
        imagePickerVC.popoverPresentationController?.permittedArrowDirections = .any
        imagePickerVC.popoverPresentationController?.sourceRect               = myTableView.frame
        imagePickerVC.popoverPresentationController?.sourceView               = myTableView
    }
    
    
    private func promptForImageDispostion() {
        logTrace()
        let     recipe = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
        let     alert  = UIAlertController.init( title: NSLocalizedString( "AlertTitle.ImageDisposition", comment: "What would you like to do with this image?" ),
                                                 message: nil,
                                                 preferredStyle: .alert)
        
        let     deleteAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Delete", comment: "Delete" ), style: .default )
        { ( alertAction ) in
            logTrace( "Delete Action" )
            
            self.deleteImage()
            
            self.imageCell.initializeWith( recipe.imageName! )
        }
        
        let     replaceAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Replace", comment: "Replace" ), style: .default )
        { ( alertAction ) in
            logTrace( "Replace Action" )
            
            self.deleteImage()
            
            self.imageCell.initializeWith( recipe.imageName! )
            
            self.promptForImageSource()
        }
        
        let     zoomAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.ZoomIn", comment: "Zoom In" ), style: .default )
        { ( alertAction ) in
            logTrace( "Zoom In Action" )
            
            self.launchImageViewController()
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        
        alert.addAction( deleteAction  )
        alert.addAction( replaceAction )
        alert.addAction( zoomAction    )
        alert.addAction( cancelAction  )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func promptForImageSource()
    {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.SelectMediaSource", comment: "Select Media Source for Image" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     albumAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.PhotoAlbum", comment: "Photo Album" ), style: .default )
        { ( alertAction ) in
            logTrace( "Photo Album Action" )
            
            self.openImagePickerFor( sourceType: .photoLibrary )
        }
        
        let     cameraAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Camera", comment: "Camera" ), style: .default )
        { ( alertAction ) in
            logTrace( "Camera Action" )
            
            self.openImagePickerFor( sourceType: .camera )
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        if UIImagePickerController.isSourceTypeAvailable( .camera ) {
            alert.addAction( cameraAction )
        }
        
        alert.addAction( albumAction  )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
}
    


// MARK: FormulaIngredientTableViewCellDelegate Methods

extension FormulaEditorViewController : FormulaIngredientTableViewCellDelegate {

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
        logVerbose( "[ %@ ][ %@ ]", String( ingredientIndexPath.section ), String( ingredientIndexPath.row ) )
        indexPathOfCellBeingEdited = ingredientIndexPath
        ensureCellBeingEditedIsVisible()
    }
    
    
}



// MARK: FormulaNameTableViewCellDelegate Methods

extension FormulaEditorViewController : FormulaNameTableViewCellDelegate {
    
    func formulaNameTableViewCell( formulaNameTableViewCell : FormulaNameTableViewCell,
                                   editedName               : String ) {
        logTrace()
        processNameInput( editedName )
    }
    
    
}



// MARK: FormulaPreFermentTableViewCellDelegate Methods

extension FormulaEditorViewController : FormulaPreFermentTableViewCellDelegate {
    
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
        
        indexPathOfCellBeingEdited = indexPath
        ensureCellBeingEditedIsVisible()
    }
    
    
}



// MARK: FormulaYieldTableViewCellDelegate Methods

extension FormulaEditorViewController : FormulaYieldTableViewCellDelegate {
    
    func formulaYieldTableViewCell( formulaYieldTableViewCell : FormulaYieldTableViewCell,
                                    editedQuantity            : String,
                                    editedWeight              : String ) {
        logTrace()
        processYieldInputs( yieldQuantity : editedQuantity,
                            yieldWeight   : editedWeight )
    }
    
    
}



// MARK: SectionHeaderViewDelegate Methods

extension FormulaEditorViewController : SectionHeaderViewDelegate {
    
    func sectionHeaderView( sectionHeaderView        : SectionHeaderView,
                            didRequestAddFor section : Int) {
        logVerbose( "[ %@ ]", String( section ) )
        
        if section == ForumlaTableSections.preFerment {
            presentPreFermentOptions( sectionHeaderView : sectionHeaderView )
        }
        else {
            newIngredientForSection = section
        }
        
        myTableView.reloadData()
    }
    
    
}



// MARK: UIImagePickerControllerDelegate Methods

extension FormulaEditorViewController : UIImagePickerControllerDelegate,
                                        UINavigationControllerDelegate      // Required for UIImagePickerControllerDelegate
{
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController ) {
        logTrace()
        if nil != presentedViewController {
            dismiss( animated: true, completion: nil )
        }
        
    }
    
    
    func imagePickerController(_ picker                             : UIImagePickerController,
                                 didFinishPickingMediaWithInfo info : [UIImagePickerController.InfoKey : Any] ) {
        logTrace()
        if nil != presentedViewController {
            dismiss( animated: true, completion: nil )
        }
        
        DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.01 ) ) {
            
            if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String
            {
                if "public.image" == mediaType {
                    var     imageToSave: UIImage? = nil
                    
                    if let originalImage: UIImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                        imageToSave = originalImage
                    }
                    else if let editedImage: UIImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
                        imageToSave = editedImage
                    }
                    
                    if let myImageToSave = imageToSave {
                        
                        if .camera == picker.sourceType {
                            UIImageWriteToSavedPhotosAlbum( myImageToSave, self, #selector( FormulaEditorViewController.image(_ :didFinishSavingWithError:contextInfo: ) ), nil )
                        }
                        
                        let     imageName = ChefbookCentral.sharedInstance.saveImage( myImageToSave )
                        
                        if imageName.isEmpty {
                            logTrace( "ERROR:  Image save FAILED!" )
                            self.presentAlert( title   : NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                               message : NSLocalizedString( "AlertMessage.ImageSaveFailed", comment: "We were unable to save the image you selected." ) )
                        }
                        else {
                            logVerbose( "Saved image as [ %@ ]", imageName )
                            
                            self.imageCell.initializeWith( imageName )
                            
                            let     chefbookCentral = ChefbookCentral.sharedInstance
                            let     recipe          = chefbookCentral.recipeArray[self.recipeIndex]
                            
                            recipe.imageName = imageName
                            
                            chefbookCentral.saveUpdated( recipe )
                        }
                        
                    }
                    else {
                        logTrace( "ERROR:  Unable to unwrap imageToSave!" )
                    }
                    
                }
                else {
                    logVerbose( "ERROR:  Invalid media type[ %@ ]", mediaType )
                    self.presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                       message: NSLocalizedString( "AlertMessage.InvalidMediaType", comment: "We can't save the item you selected.  We can only save photos." ) )
                }
                
            }
            else {
                logTrace( "ERROR:  Unable to convert info[UIImagePickerControllerMediaType] to String" )
            }
            
        }
        
    }
    
    
    // MARK: UIImageWrite Completion Methods
    
    @objc func image(_ image                          : UIImage,
                       didFinishSavingWithError error : NSError?,
                       contextInfo                    : UnsafeRawPointer )
    {
        guard error == nil else {
            
            if let myError = error {
                logVerbose( "ERROR:  Save to photo album failed!  Error[ %@ ]", myError.localizedDescription )
            }
            else {
                logTrace( "ERROR:  Save to photo album failed!  Error[ Unknown ]" )
            }
            
            return
        }
        
        logTrace( "Image successfully saved to photo album" )
    }
    
    
}



// MARK: UIPopoverPresentationControllerDelegate Methods

extension FormulaEditorViewController : UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle( for controller : UIPresentationController ) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    

}



// MARK: UITableViewDataSource Methods

extension FormulaEditorViewController : UITableViewDataSource {
    
    // MARK: UITableViewDataSource Methods
    
    func numberOfSections( in tableView : UITableView ) -> Int {
        var numberOfSections = 0
        
        
        if !waitingForNotification {
            numberOfSections = ( currentState == .name || currentState == .yield ) ? 1 : 4
        }
        
//        logVerbose( "[ %@ ]", String( numberOfSections ) )
        
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
                default:        numberOfRows = 4    // 3rd row - image ... 4th row - % Name Weight header for the following sections
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
        
//        logVerbose( "[ %@ ][ %@ ]", String( section), String( numberOfRows ) )
        
        return numberOfRows
    }
    
    
    func tableView(_ tableView              : UITableView,
                     cellForRowAt indexPath : IndexPath ) -> UITableViewCell {
//        logVerbose( "row[ %@ ]", String( indexPath.row ) )
        var     cell : UITableViewCell!
        
        switch indexPath.section {
            
        case ForumlaTableSections.nameAndYield:
            
            switch indexPath.row {
            case CellIndexes.name:      cell = loadFormulaNameCell()
            case CellIndexes.yield:     cell = loadFormulaYieldCell()
            case CellIndexes.image:     cell = loadImageViewCell()
            default:                    cell = loadFormulaIngredientCellAt( indexPath )     // Creates the % Name Weight header for the following sections
            }
            
        case ForumlaTableSections.flour:
            cell = loadFormulaIngredientCellAt( indexPath )
            
        case ForumlaTableSections.ingredients:
            cell = loadFormulaIngredientCellAt( indexPath )
            
        default:
            cell = loadFormulaPreFermentCellAt( indexPath )
        }
        
        return cell
    }
    
    
    func tableView(_ tableView              : UITableView,
                     canEditRowAt indexPath : IndexPath) -> Bool {
        var canEdit = true
        
        if indexPath.section == newIngredientForSection &&
           indexPath.row + 1 == tableView.numberOfRows( inSection: newIngredientForSection ) {
            
//            logVerbose( "do NOT allow the user to delete a NEW row at [ %@ ][ %@ ]", String( indexPath.section ), String( indexPath.row ) )
            canEdit = false
        }
        else {
            canEdit = indexPath.section != ForumlaTableSections.nameAndYield
        }
        
        return canEdit
    }
    
    
    func tableView(_ tableView           : UITableView,
                     commit editingStyle : UITableViewCell.EditingStyle,
                     forRowAt indexPath  : IndexPath) {
        
        if editingStyle == .delete {
            logVerbose( "delete ingredient at [ %@ ][ %@ ]", String( indexPath.section ), String( indexPath.row ) )
            
            DispatchQueue.main.asyncAfter(deadline: ( .now() + 0.2 ), execute: {
                let  chefbookCentral = ChefbookCentral.sharedInstance
                
                chefbookCentral.selectedRecipeIndex = self.recipeIndex
                
                switch indexPath.section {
                    
                case ForumlaTableSections.flour:
                    chefbookCentral.deleteFormulaRecipeFlourIngredientAt( indexPath.row )
                    
                case ForumlaTableSections.ingredients:
                    chefbookCentral.deleteFormulaRecipeBreadIngredientAt( indexPath.row )
                    
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
    
    
    // MARK: Utility Methods

    private func loadFormulaIngredientCellAt(_ indexPath: IndexPath ) -> UITableViewCell {
        
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.ingredients ) else {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
//        logVerbose( "section[ %@ ] row[ %@ ]", String( indexPath.section ), String( indexPath.row ) )
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
    
    
    private func loadFormulaPreFermentCellAt(_ indexPath : IndexPath) -> UITableViewCell {
        
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
    
    
    private func loadImageViewCell() -> UITableViewCell {
        
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.image ) else {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        let     imageCell = cell as! FormulaImageTableViewCell
        let     recipe    = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
        var     imageName = ""
        
        if let name = recipe.imageName {
//            logVerbose( "imageName[ %@ ]", name )
            imageName = name
        }
        
        imageCell.delegate = self
        imageCell.initializeWith( imageName )

        return cell
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension FormulaEditorViewController : UITableViewDelegate {
    
    func tableView(_ tableView                : UITableView,
                     didSelectRowAt indexPath : IndexPath ) {
        
//        tableView.deselectRow( at: indexPath, animated: false )
        if indexPath.section == ForumlaTableSections.preFerment && ChefbookCentral.sharedInstance.recipeArray[self.recipeIndex].poolish != nil {
            
            if let sectionHeaderView = tableView.headerView( forSection: indexPath.section ) as? SectionHeaderView {
                loadPoolishEditorPopoverFrom( sectionHeaderView )
            }
            
        }
        
    }
    
    
    func tableView(_ tableView                        : UITableView,
                     heightForHeaderInSection section : Int ) -> CGFloat {
        
        let     height = section == ForumlaTableSections.nameAndYield ? 0.0 : 44.0 as CGFloat
        
        return height
    }
    
    
    func tableView(_ tableView                : UITableView,
                     heightForRowAt indexPath : IndexPath ) -> CGFloat {
        
        let     heightForRow : CGFloat = ( ( indexPath.section == ForumlaTableSections.nameAndYield ) && ( indexPath.row == CellIndexes.image ) ) ? 244.0 : 44.0
        
        return heightForRow
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
    
    
}

