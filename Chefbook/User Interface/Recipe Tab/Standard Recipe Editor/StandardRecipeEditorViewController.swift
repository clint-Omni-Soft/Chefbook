//
//  StandardRecipeEditorViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 11/15/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class StandardRecipeEditorViewController: UIViewController {
    
    // MARK: Public Variables
    var     recipeIndex:     Int!                        // Set by caller
    
    
    @IBOutlet weak var myTableView: UITableView!
    
    
    // MARK: Private Variables
    
    private struct CellHeights {
        static let header       : CGFloat =  44.0
        static let image        : CGFloat = 244.0
        static let ingredients  : CGFloat =  44.0
        static let name         : CGFloat =  44.0
        static let steps        : CGFloat =   0.0       // Calculated
        static let yield        : CGFloat =  44.0
    }
    
    private struct CellIdentifiers {
        static let image        = "StandardRecipeImageTableViewCell"
        static let ingredients  = "StandardRecipeIngredientsTableViewCell"
        static let name         = "StandardRecipeNameTableViewCell"
        static let steps        = "StandardRecipeStepsTableViewCell"
        static let yield        = "StandardRecipeYieldTableViewCell"
    }
    
    private struct NameImageAndYieldCellIndexes {
        static let name         = 0
        static let image        = 2
        static let header       = 3
        static let yield        = 1
    }
    
    struct StandardRecipeTableSections {
        static let nameImageAndYield = 0
        static let ingredients       = 1
        static let steps             = 2
        
        static let numberOfSections  = 3
        static let none              = 99
    }
    
    private enum StateMachine {
        case name
        case yield
        case ingredients
    }
    
    private struct StoryboardIds {
        static let imageViewer         = "ImageViewController"
        static let provisioningSummary = "ProvisioningSummaryViewController"
        static let stepsEditor         = "StepsEditorViewController"
    }
    
    private var     currentState                    = StateMachine.name
    private var     imageCell                       : StandardRecipeImageTableViewCell!     // Set in StandardRecipeImageTableViewCellDelegate Method
    private var     indexPathOfCellBeingEdited      = IndexPath(item: 0, section: 0)
    private var     loadingImageView                = false
    private var     newIngredientForSection         = 0
    private var     originalViewOffset : CGFloat    = 0.0
    private var     waitingForDidHideNotification   = false
    private var     waitingForNotification          = false

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString( "Title.RecipeEditor", comment: "Recipe Editor" )
        
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
        
        logVerbose( "recovering selectedRecipeIndex[ %d ] from chefbookCentral", chefbookCentral.selectedRecipeIndex )
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
        
//        logVerbose( "[ %d ][ %d ] cellIsVisible[ %@ ]", indexPathOfCellBeingEdited.section, indexPathOfCellBeingEdited.row, stringFor( cellIsVisible ) )
        
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
    
    
    private func ingredientAt(_ indexPath: IndexPath ) -> StandardIngredient {
        
        let     recipe             = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
        let     ingredientsArray   = recipe.standardIngredients?.allObjects as! [StandardIngredient]
        var     standardIngredient : StandardIngredient!
        
        
        for ingredient in ingredientsArray {
            
            if ingredient.index == indexPath.row {
                standardIngredient = ingredient
                break
            }
            
        }
        
        return standardIngredient
    }
    
    
    private func initializeStateMachine() {
        
        logTrace()
        if recipeIndex == NEW_RECIPE {
            currentState = StateMachine.name
        }
        else {
            let recipe = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
            
            currentState = ( recipe.yield == 0 || recipe.yieldWeight == 0 ) ? .yield : .ingredients
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
        
//        myTableView.register( SectionHeaderView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderView.reuseIdentifier )   // this form is required for programmatic header construction
    }
    
    
    private func isIngredientUniqueAt(_ indexPath : IndexPath,
                                        name      : String ) -> Bool {
        
        let     chefbookCentral  = ChefbookCentral.sharedInstance
        var     isUnique         = true
        let     recipe           = chefbookCentral.recipeArray[recipeIndex]
        let     ingredientsArray = recipe.standardIngredients?.allObjects as! [StandardIngredient]
        
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
    
    
    private func processIngredientInputs( ingredientIndexPath : IndexPath,
                                          isNew               : Bool,
                                          name                : String,
                                          amount              : String ) {
        logTrace()
        let     newAmount = amount.trimmingCharacters( in: .whitespacesAndNewlines )
        let     newName   = name  .trimmingCharacters( in: .whitespacesAndNewlines )
        
        if !newName.isEmpty {
            let     chefbookCentral = ChefbookCentral.sharedInstance
            
            if self.isIngredientUniqueAt( ingredientIndexPath, name: newName ) {
                
                let     recipe = chefbookCentral.recipeArray[recipeIndex]
                
                chefbookCentral.selectedRecipeIndex = recipeIndex

                if isNew {
                    newIngredientForSection = StandardRecipeTableSections.none

                    chefbookCentral.addStandardIngredientTo( recipe   : recipe,
                                                             index    : isNew ? ( chefbookCentral.recipeArray[self.recipeIndex].standardIngredients?.count ?? 0 ) : ingredientIndexPath.row,
                                                             name     : newName,
                                                             amount   : newAmount )
                }
                else {
                    let     ingredient = ingredientAt( ingredientIndexPath )
                    let     recipe     = chefbookCentral.recipeArray[recipeIndex]
                    
                    ingredient.amount = newAmount
                    ingredient.name   = newName
                    
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
    
    
    private func processNameInput(_ name : String ) {
        logTrace()
        let     myName = name.trimmingCharacters( in: .whitespacesAndNewlines )
        
        if !myName.isEmpty {
            
            if self.unique( myName ) {
                
                let     chefbookCentral = ChefbookCentral.sharedInstance
                
                if self.recipeIndex == NEW_RECIPE {
                    
                    currentState = StateMachine.yield
                    
                    chefbookCentral.addStandardRecipe( myName )
                }
                else {
                    let     recipe = chefbookCentral.recipeArray[recipeIndex]
                    
                    recipe.name = myName
                    
                    chefbookCentral.saveUpdated( recipe )
                }
                
            }
            else {
                logTrace( "ERROR:  Duplicate standardRecipe name!" )
                presentAlert( title   : NSLocalizedString( "AlertTitle.Error",                  comment: "Error!" ),
                              message : NSLocalizedString( "AlertMessage.DuplicateStandardRecipeName", comment: "The recipe name you choose already exists.  Please try again." ) )
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
        
        
        recipe.yield       = Int16( myYieldQuantity ) ?? 1
        recipe.yieldWeight = Int64( myYieldWeight   ) ?? 1
        
        currentState = StateMachine.ingredients
        
        chefbookCentral.selectedRecipeIndex = recipeIndex
        
        chefbookCentral.saveUpdated( recipe )
    }
    
    
    private func unique(_ recipeName: String ) -> Bool {
        
        let     chefbookCentral   = ChefbookCentral.sharedInstance
        var     numberOfInstances = 0
        
        for recipe in chefbookCentral.recipeArray {
            
            if ( recipeName.uppercased() == recipe.name?.uppercased() ) {
                
                if recipeIndex == NEW_RECIPE {
                    logTrace( "Found a duplicate! [New]." )
                    numberOfInstances += 1
                }
                else {
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
    
    
    private func scrollCellBeingEdited( keyboardDidShow : Bool,     // false == willHide
                                        topOfKeyboard   : CGFloat ) {
        
        if indexPathOfCellBeingEdited.section == 0 {
            return
        }
        
        let     frame  = myTableView.frame
        var     origin = frame.origin
        
//        logVerbose( "[ %d ][ %d ] willShow[ %@ ] topOfKeyboard[ %f ]", indexPathOfCellBeingEdited.section, indexPathOfCellBeingEdited.row, stringFor( keyboardWillShow ), topOfKeyboard )
        if !keyboardDidShow {
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
        
//        logVerbose( "keyboardDidShow[ %@ ]  originalViewOffset[ %f ]", stringFor( keyboardDidShow ), originalViewOffset )
        myTableView.frame = CGRect( origin: origin, size: frame.size )
    }
    
    
    private func topOfKeyboardFromNotification(_ notification : NSNotification ) -> CGFloat {
        
        var     topOfKeyboard : CGFloat = 1000.0
        
        if let userInfo = notification.userInfo {
            let     endFrame = ( userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue )?.cgRectValue
            
            topOfKeyboard = endFrame?.origin.y ?? 1000.0 as CGFloat
        }
        
//        logVerbose( "topOfKeyboard[ %f ]", topOfKeyboard )
        return topOfKeyboard
    }


}



// MARK: ChefbookCentralDelegate Methods

extension StandardRecipeEditorViewController : ChefbookCentralDelegate {
    
    func chefbookCentral( chefbookCentral : ChefbookCentral,
                          didOpenDatabase : Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
    }
    
    
    func chefbookCentralDidReloadProvisionArray(chefbookCentral: ChefbookCentral) {
        logVerbose( "loaded [ %d ] provisions", chefbookCentral.provisionArray.count )
    }
    
    
    func chefbookCentralDidReloadRecipeArray( chefbookCentral : ChefbookCentral ) {
//        logVerbose( "loaded [ %d ] recipes ... current recipeIndex[ %d ] ... recovering [ %d ] from chefbookCentral", chefbookCentral.recipeArray.count, recipeIndex, chefbookCentral.selectedRecipeIndex )
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



// MARK: StandardRecipeImageTableViewCellDelegate Methods

extension StandardRecipeEditorViewController : StandardRecipeImageTableViewCellDelegate {
    
    func standardRecipeImageTableViewCell( standardRecipeImageTableViewCell: StandardRecipeImageTableViewCell,
                                    cameraButtonTouched: Bool) {
        logTrace()
        imageCell = standardRecipeImageTableViewCell
        
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



// MARK: StandardRecipeIngredientTableViewCellDelegate Methods

extension StandardRecipeEditorViewController : StandardRecipeIngredientTableViewCellDelegate {
    
    func standardRecipeIngredientTableViewCell( standardRecipeIngredientTableViewCell : StandardRecipeIngredientTableViewCell,
                                                ingredientIndexPath                   : IndexPath,
                                                isNew                                 : Bool,
                                                editedName                            : String,
                                                editedAmount                          : String ) {
        logTrace()
        processIngredientInputs( ingredientIndexPath : ingredientIndexPath,
                                 isNew               : isNew,
                                 name                : editedName,
                                 amount              : editedAmount )
    }
    
    
    func standardRecipeIngredientTableViewCell( standardRecipeIngredientTableViewCell : StandardRecipeIngredientTableViewCell,
                                                ingredientIndexPath                   : IndexPath,
                                                didStartEditing                       : Bool ) {
        logVerbose( "[ %d ][ %d ]", ingredientIndexPath.section, ingredientIndexPath.row )
        indexPathOfCellBeingEdited = ingredientIndexPath
        ensureCellBeingEditedIsVisible()
    }
    
    
    func standardRecipeIngredientTableViewCell( standardRecipeIngredientTableViewCell : StandardRecipeIngredientTableViewCell,
                                                requestNewIngredient                  : Bool ) {
        logTrace()
        newIngredientForSection = StandardRecipeTableSections.ingredients
        myTableView.reloadData()
    }
    
    
}



// MARK: StandardRecipeNameTableViewCellDelegate Methods

extension StandardRecipeEditorViewController : StandardRecipeNameTableViewCellDelegate {
    
    func standardRecipeNameTableViewCell( standardRecipeNameTableViewCell : StandardRecipeNameTableViewCell,
                                          editedName                      : String ) {
        logTrace()
        processNameInput( editedName )
    }
    
    
}



// MARK: StandardRecipeYieldTableViewCellDelegate Methods

extension StandardRecipeEditorViewController : StandardRecipeYieldTableViewCellDelegate {
    
    func standardRecipeYieldTableViewCell( standardRecipeYieldTableViewCell : StandardRecipeYieldTableViewCell,
                                           editedQuantity                   : String,
                                           editedWeight                     : String ) {
        logTrace()
        processYieldInputs( yieldQuantity : editedQuantity,
                            yieldWeight   : editedWeight )
    }
    
    
}



// MARK: StepsEditorViewControllerDelegate Methods

extension StandardRecipeEditorViewController : StepsEditorViewControllerDelegate {
    
    func stepsEditorViewController( stepsEditorViewController : StepsEditorViewController,
                                    didEditSteps              : Bool ) {
        logTrace()
        let     chefbookCentral = ChefbookCentral.sharedInstance
        let     recipe          = chefbookCentral.recipeArray[recipeIndex]
        
        
        recipe.steps = stepsEditorViewController.steps
        
        chefbookCentral.saveUpdated( recipe )
    }
    
    
}



// MARK: UIImagePickerControllerDelegate Methods

extension StandardRecipeEditorViewController : UIImagePickerControllerDelegate,
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
                            UIImageWriteToSavedPhotosAlbum( myImageToSave, self, #selector( StandardRecipeEditorViewController.image(_ :didFinishSavingWithError:contextInfo: ) ), nil )
                        }
                        
                        let     imageName = ChefbookCentral.sharedInstance.saveImage( myImageToSave )
                        
                        if imageName.isEmpty {
                            logTrace( "ERROR:  Image save FAILED!" )
                            self.presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                               message: NSLocalizedString( "AlertMessage.ImageSaveFailed", comment: "We were unable to save the image you selected." ) )
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

extension StandardRecipeEditorViewController : UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle( for controller : UIPresentationController ) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension StandardRecipeEditorViewController : UITableViewDataSource {
    
    func numberOfSections( in tableView : UITableView ) -> Int {
        var numberOfSections = 0
        
        if !waitingForNotification {
            numberOfSections = ( currentState == .name || currentState == .yield ) ? 1 : StandardRecipeTableSections.numberOfSections
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
                
            case StandardRecipeTableSections.nameImageAndYield:
                switch currentState {
                case .name:     numberOfRows = 1
                case .yield:    numberOfRows = 2
                default:        numberOfRows = 4    // 3rd row - image ... 4th row - % Name Weight header for the following sections
                }
                
            case StandardRecipeTableSections.ingredients:
                let     indexOfNextIngredient = chefbookCentral.recipeArray[recipeIndex].standardIngredients?.count ?? 0
                
                numberOfRows = indexOfNextIngredient + ( newIngredientForSection == StandardRecipeTableSections.ingredients ? 1 : 0 )
                
            case StandardRecipeTableSections.steps:
                numberOfRows = 2
                
            default:
                break
            }
            
        }
        
//        logVerbose( "section[ %d ]  numberOfRows[ %d ]", section, numberOfRows )
        return numberOfRows
    }
    
    
    func tableView(_ tableView              : UITableView,
                     cellForRowAt indexPath : IndexPath ) -> UITableViewCell {
//        logVerbose( "[ %d ][ %d ]", indexPath.section, indexPath.row)
        var     cell : UITableViewCell!
        
        switch indexPath.section {
            
        case StandardRecipeTableSections.nameImageAndYield:
            
            switch indexPath.row {
            case NameImageAndYieldCellIndexes.header:   cell = loadStandardRecipeIngredientCellAt( indexPath )     // Creates the Name Amount header for the ingredients section
            case NameImageAndYieldCellIndexes.image:    cell = loadStandardRecipeImageViewCell()
            case NameImageAndYieldCellIndexes.name:     cell = loadStandardRecipeNameCell()
            case NameImageAndYieldCellIndexes.yield:    cell = loadStandardRecipeYieldCell()
            default:                                    break
            }
            
        case StandardRecipeTableSections.ingredients:
            cell = loadStandardRecipeIngredientCellAt( indexPath )
            
        case StandardRecipeTableSections.steps:
            cell = loadStandardRecipeStepsCellAsHeader( indexPath.row == 0 )
            
        default:
            break
        }
        
        return cell
    }
    
    
    func tableView(_ tableView              : UITableView,
                     canEditRowAt indexPath : IndexPath) -> Bool {
        var canEdit = true
        
        if indexPath.section == newIngredientForSection &&
           indexPath.row + 1 == tableView.numberOfRows( inSection: newIngredientForSection ) {
            
            canEdit = false
        }
        else if indexPath.section == StandardRecipeTableSections.steps  {
            
            canEdit = false
        }
        else {
            canEdit = indexPath.section != StandardRecipeTableSections.nameImageAndYield
        }
        
//        logVerbose( "[ %d ][ %d ] = [ %@ ]", indexPath.section, indexPath.row, stringFor( canEdit ) )
        return canEdit
    }
    
    
    func tableView(_ tableView           : UITableView,
                     commit editingStyle : UITableViewCell.EditingStyle,
                     forRowAt indexPath  : IndexPath) {
        
        if editingStyle == .delete && indexPath.section == StandardRecipeTableSections.ingredients {
            logVerbose( "delete ingredient at [ %d ][ %d ]", indexPath.section, indexPath.row )
            
            DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.2 ), execute: {
                let     chefbookCentral = ChefbookCentral.sharedInstance
                let     recipe          = chefbookCentral.recipeArray[self.recipeIndex]
                
                chefbookCentral.selectedRecipeIndex = self.recipeIndex
                chefbookCentral.deleteStandardIngredientFrom( recipe : recipe,
                                                              with   : indexPath.row )
            })
            
        }
        
    }
    
    
    // MARK: Utility Methods
    
    private func loadStandardRecipeImageViewCell() -> UITableViewCell {

        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.image ) else {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }

//        logTrace()
        let     imageCell = cell as! StandardRecipeImageTableViewCell
        let     recipe    = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
        var     imageName = ""
        
        if let name = recipe.imageName {
            logVerbose( "imageName[ %@ ]", name )
            imageName = name
        }
        
        imageCell.delegate = self
        imageCell.initializeWith( imageName )
        
        return cell
    }
    
    
    private func loadStandardRecipeIngredientCellAt(_ indexPath: IndexPath ) -> UITableViewCell {
        
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.ingredients ) else {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        let     setupAsHeader                = indexPath.section == StandardRecipeTableSections.nameImageAndYield
        let     standardRecipeIngredientCell = cell as! StandardRecipeIngredientTableViewCell
        
//        logVerbose( "[ %d ][ %d ] setupAsHeader[ %@ ]", indexPath.section, indexPath.row, stringFor( setupAsHeader ) )
        if setupAsHeader {
            
            standardRecipeIngredientCell.setupAsHeaderWithDelegate( self )
        }
        else {
            let     recipe             = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
            let     lastIngredientRow  = recipe.standardIngredients?.count ?? 0
            let     isNewIngredientRow = newIngredientForSection == indexPath.section && lastIngredientRow == indexPath.row
            
            standardRecipeIngredientCell.initializeWithRecipeAt( recipeIndex         : recipeIndex,
                                                                 ingredientIndexPath : indexPath,
                                                                 isNew               : isNewIngredientRow,
                                                                 delegate            : self )
        }
        
        return cell
    }
    
    
    private func loadStandardRecipeNameCell() -> UITableViewCell {
        
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.name ) else {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
//        logTrace()
        let     standardRecipeNameCell = cell as! StandardRecipeNameTableViewCell
        let     recipeName             = ( ( recipeIndex == NEW_RECIPE ) ? "" : ChefbookCentral.sharedInstance.recipeArray[recipeIndex].name! )
        
        standardRecipeNameCell.initializeWith( standardRecipeName : recipeName,
                                               delegate           : self )
        return cell
    }
    
    
    private func loadStandardRecipeStepsCellAsHeader(_ asHeader : Bool ) -> UITableViewCell {
        
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.steps ) else {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        let     stepsCell = cell as! StandardRecipeStepsTableViewCell

//        logVerbose( "asHeader[ %@ ]", stringFor( asHeader ) )
        
        if asHeader {
            stepsCell.setupAsHeader()
        }
        else {
            let     recipe    = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
            let     stepsText = recipe.steps ?? ""
            
            stepsCell.initializeWith( stepsList: stepsText )
        }
        
        return cell
    }
    
    
    private func loadStandardRecipeYieldCell() -> UITableViewCell {
        
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.yield ) else {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }

        logTrace()
        let     yieldCell = cell as! StandardRecipeYieldTableViewCell
        var     quantity  = 0
        var     weight    = 0

        if recipeIndex != NEW_RECIPE {
            let recipe = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]

            quantity = Int( recipe.yield       )
            weight   = Int( recipe.yieldWeight )
        }

        yieldCell.initializeWith( quantity  : quantity,
                                  weight    : weight,
                                  delegate  : self )
        return cell
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension StandardRecipeEditorViewController : UITableViewDelegate {
    
    func tableView(_ tableView                : UITableView,
                   didSelectRowAt indexPath : IndexPath ) {
        
        tableView.deselectRow( at: indexPath, animated: false )
        
        if indexPath.section == StandardRecipeTableSections.steps && indexPath.row == 1 {
            launchStepsEditorViewController()
        }

    }
    
    
    func tableView(_ tableView                        : UITableView,
                     heightForHeaderInSection section : Int ) -> CGFloat {
        return 0.0
    }
    
    
    func tableView(_ tableView                : UITableView,
                     heightForRowAt indexPath : IndexPath ) -> CGFloat {
        
        var     height : CGFloat = 0.0
        
        switch indexPath.section {
            
        case StandardRecipeTableSections.nameImageAndYield:
            switch indexPath.row
            {
            case NameImageAndYieldCellIndexes.header:   height = CellHeights.header
            case NameImageAndYieldCellIndexes.image:    height = CellHeights.image
            case NameImageAndYieldCellIndexes.name:     height = CellHeights.name
            case NameImageAndYieldCellIndexes.yield:    height = CellHeights.yield
            default:                                    break
            }

        case StandardRecipeTableSections.ingredients:
            height = CellHeights.ingredients
            
        default:
            height = ( indexPath.row == 0 ) ? 44.0 : cellHeightForSteps()
        }

//        logVerbose( "[ %d ][ %d ] = [ %f ]", indexPath.section, indexPath.row, height  )
        return height
    }
    
    
    
    // MARK: Utility Methods
    
    private func cellHeightForSteps() -> CGFloat {
        
        var     cellHeight    : CGFloat = 32.0 // 16 pixel top and bottom margin
        let     widthOfCell   = myTableView.frame.size.width - 32.0
        let     recipe        = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
        let     stepsText     = recipe.steps ?? ""
        let     arrayOfLines  = stepsText.components( separatedBy: "\n" )
        
        for line in arrayOfLines {
            cellHeight += line.heightWithConstrainedWidth( width: widthOfCell, font: .systemFont( ofSize: 17.0 ) )
        }
        
        return cellHeight
    }
    
    
    private func launchStepsEditorViewController() {
        
        let     recipe    = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
        let     stepsText = recipe.steps ?? ""

        logVerbose( "stepsText[ %@ ]", stepsText )
        if let stepsEditorViewController: StepsEditorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.stepsEditor ) as? StepsEditorViewController {
            
            stepsEditorViewController.delegate = self
            stepsEditorViewController.steps    = stepsText
            
            navigationController?.pushViewController( stepsEditorViewController, animated: true )
        }
        else {
            logTrace( "ERROR: Could NOT load StepsEditorViewController!" )
        }
        
    }
    
    
}



