//
//  RecipeEditorViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 7/26/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


class RecipeEditorViewController: UIViewController,
                                  ChefbookCentralDelegate,
                                  IngredientsEditorViewControllerDelegate,
                                  RecipeImageTableViewCellDelegate,
                                  StepsEditorViewControllerDelegate,
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
        static let imageViewer       = "ImageViewController"
        static let ingredientsEditor = "IngredientsEditorViewController"
        static let stepsEditor       = "StepsEditorViewController"
    }
    
    private struct CellHeights
    {
        static let image        : CGFloat = 240.0
        static let ingredients  : CGFloat =   0.0       // Calculated
        static let name         : CGFloat =  44.0
        static let steps        : CGFloat =   0.0       // Calculated
        static let yield        : CGFloat =  70.0
        static let yieldOptions : CGFloat =  70.0
    }
    
    private struct CellIdentifiers
    {
        static let image        = "RecipeImageTableViewCell"
        static let ingredients  = "RecipeIngredientsTableViewCell"
        static let name         = "RecipeNameTableViewCell"
        static let steps        = "RecipeStepsTableViewCell"
        static let yield        = "RecipeYieldTableViewCell"
        static let yieldOptions = "RecipeYieldOptionsTableViewCell"
    }
    
    private struct CellIndexes
    {
        static let name         = 0
        static let image        = 1
        static let yield        = 2
        static let yieldOptions = 3
        static let ingredients  = 4
        static let steps        = 5

        static let numberOfCells = 6
    }
    
    private var     firstTimeIn                 = true
    private var     imageAssigned               = false
    private var     imageCell                   : RecipeImageTableViewCell!     // Set in RecipeImageTableViewCellDelegate Method
    private var     imageName                   = String()
    private var     ingredientsText             = String()
    private var     loadingImageView            = false
    private var     recipeName                  = String()
    private var     originalImageName           = String()
    private var     originalIngredients         = String()
    private var     originalRecipeName          = String()
    private var     originalSteps               = String()
    private var     originalYield               = String()
    private var     originalYieldOptions        = String()
    private var     stepsText                   = String()
    private var     waitingForNotification      = false
    private var     yield                       = String()
    private var     yieldOptions                = String()

    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        logTrace()
        super.viewDidLoad()

        title = NSLocalizedString( "Title.RecipeEditor", comment: "Recipe Editor" )
        
        preferredContentSize = CGSize( width: 320, height: 460 )
        myTableView.separatorStyle = .none

        if UIDevice.current.userInterfaceIdiom == .pad
        {
            waitingForNotification = true
        }
        else
        {
            initializeVariables()
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        logTrace()
        super.viewWillAppear( animated )
        
        configureBarButtonItem()
        myTableView.reloadData()
        
        NotificationCenter.default.addObserver( self,
                                                selector: #selector( RecipeEditorViewController.recipesUpdated( notification: ) ),
                                                name:     NSNotification.Name( rawValue: NOTIFICATION_RECIPES_UPDATED ),
                                                object:   nil )
        NotificationCenter.default.addObserver( self,
                                                selector: #selector( RecipeEditorViewController.recipeSelected( notification: ) ),
                                                name:     NSNotification.Name( rawValue: NOTIFICATION_RECIPE_SELECTED ),
                                                object:   nil )
    }
    
    
    override func viewWillDisappear(_ animated: Bool)
    {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
        
        if !imageAssigned && !imageName.isEmpty
        {
            deleteImage()
        }
        
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
        
        if loadingImageView
        {
            loadingImageView = false
            launchImageViewController()
        }
        else
        {
            self.myTableView.reloadData()
        }
        
    }
    
    
    
    // MARK: IngredientsEditorViewControllerDelegate Methods
    
    func ingredientsEditorViewController( ingredientsEditorViewController: IngredientsEditorViewController,
                                          didEditIngredients: Bool )
    {
        logTrace()
        ingredientsText = ingredientsEditorViewController.ingredients
        
        updateChefbookCentral()
    }
    
    

    // MARK: NSNotification Methods
    
    @objc func recipeSelected( notification: NSNotification )
    {
        logTrace()
        waitingForNotification = false
        
        configureBarButtonItem()
        initializeVariables()
        
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
        
        if !imageAssigned && !imageName.isEmpty
        {
            deleteImage()
        }
        
        initializeVariables()
        
        myTableView.reloadData()
    }
    
    
    
    // MARK: RecipeImageTableViewCellDelegate Methods
    
    func recipeImageTableViewCell( recipeImageTableViewCell: RecipeImageTableViewCell,
                                   cameraButtonTouched: Bool )
    {
        logTrace()
        imageCell = recipeImageTableViewCell
        
        if imageName.isEmpty
        {
            promptForImageSource()
        }
        else
        {
            promptForImageDispostion()
        }
        
    }
    
    
    
    // MARK: StepsEditorViewControllerDelegate Methods
    
    func stepsEditorViewController( stepsEditorViewController: StepsEditorViewController,
                                    didEditSteps: Bool )
    {
        logTrace()
        stepsText = stepsEditorViewController.steps
       
        updateChefbookCentral()
    }
    
  
    
    // MARK: Target/Action Methods
    
    @IBAction func cancelBarButtonTouched( sender: UIBarButtonItem )
    {
        logTrace()
        dismissView()
    }
    
    
    
    // MARK: UIImagePickerControllerDelegate Methods
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController )
    {
        logTrace()
        if nil != presentedViewController
        {
            dismiss( animated: true, completion: nil )
        }
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any] )
    {
        logTrace()
        if nil != presentedViewController
        {
            dismiss( animated: true, completion: nil )
        }
        
        DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.01 ) )
        {
            if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String
            {
                if "public.image" == mediaType
                {
                    var     imageToSave: UIImage? = nil
                    
                    
                    if let originalImage: UIImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
                    {
                        imageToSave = originalImage
                    }
                    else if let editedImage: UIImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
                    {
                        imageToSave = editedImage
                    }
                    
                    if let myImageToSave = imageToSave
                    {
                        if .camera == picker.sourceType
                        {
                            UIImageWriteToSavedPhotosAlbum( myImageToSave, self, #selector( RecipeEditorViewController.image(_ :didFinishSavingWithError:contextInfo: ) ), nil )
                        }
                        
                        
                        let     imageName = ChefbookCentral.sharedInstance.saveImage( image: myImageToSave )
                        
                        
                        if imageName.isEmpty
                        {
                            logTrace( "ERROR:  Image save FAILED!" )
                            self.presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                               message: NSLocalizedString( "AlertMessage.ImageSaveFailed", comment: "We were unable to save the image you selected." ) )
                        }
                        else
                        {
                            self.imageAssigned = false
                            self.imageName     = imageName
                            
                            logVerbose( "Saved image as [ %@ ]", imageName )
                            
                            self.imageCell.initializeWith( imageName: self.imageName )
                            
                            self.updateChefbookCentral()
                        }
                        
                    }
                    else
                    {
                        logTrace( "ERROR:  Unable to unwrap imageToSave!" )
                    }
                    
                }
                else
                {
                    logVerbose( "ERROR:  Invalid media type[ %@ ]", mediaType )
                    self.presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                       message: NSLocalizedString( "AlertMessage.InvalidMediaType", comment: "We can't save the item you selected.  We can only save photos." ) )
                }
                
            }
            else
            {
                logTrace( "ERROR:  Unable to convert info[UIImagePickerControllerMediaType] to String" )
            }
            
        }
        
    }
    
    
    
    // MARK: UIImageWrite Completion Methods
    
    @objc func image(_ image: UIImage,
                     didFinishSavingWithError error: NSError?,
                     contextInfo: UnsafeRawPointer )
    {
        guard error == nil else
        {
            if let myError = error
            {
                logVerbose( "ERROR:  Save to photo album failed!  Error[ %@ ]", myError.localizedDescription )
            }
            else
            {
                logTrace( "ERROR:  Save to photo album failed!  Error[ Unknown ]" )
            }
            
            return
        }
        
        logTrace( "Image successfully saved to photo album" )
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
//        logTrace()
        let numberOfRows = waitingForNotification ? 0 : CellIndexes.numberOfCells
        
        return numberOfRows
    }
    
    
    func tableView(_ tableView: UITableView,
                     cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
//        logVerbose( "row[ %d ]", indexPath.row)
        var     cell : UITableViewCell!
        
        
        switch indexPath.row
        {
        case CellIndexes.image:
            cell = loadImageViewCell()
        case CellIndexes.name:
            cell = loadRecipeNameCell()
        case CellIndexes.ingredients:
            cell = loadIngredientsCell()
        case CellIndexes.steps:
            cell = loadStepsCell()
        case CellIndexes.yield:
            cell = loadYieldCell()
        case CellIndexes.yieldOptions:
            cell = loadYieldOptionsCell()
        default:
            cell = UITableViewCell.init()
        }
        
        return cell
    }
    
    
    
    // MARK: UITableViewDelegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath )
    {
        tableView.deselectRow( at: indexPath, animated: false )
        
        switch indexPath.row
        {
        case CellIndexes.ingredients:
            launchIngredientsEditorViewController()
            
        case CellIndexes.name:
            editRecipeName()
            
        case CellIndexes.steps:
            launchStepsEditorViewController()
        
        case CellIndexes.yield:
            editRecipeYield()

        case CellIndexes.yieldOptions:
            editRecipeYieldOptions()

        default:
            break
        }
        
    }
    
    
    func tableView(_ tableView: UITableView,
                     heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        var     height : CGFloat = 44.0
        
        
        switch indexPath.row
        {
        case CellIndexes.image:
            height = CellHeights.image
        case CellIndexes.ingredients:
            height = cellHeightForIngredients()
        case CellIndexes.name:
            height = CellHeights.name
        case CellIndexes.steps:
            height = cellHeightForSteps()
        case CellIndexes.yield:
            height = CellHeights.yield
        case CellIndexes.yieldOptions:
            height = CellHeights.yieldOptions
        default:
            break
        }
        
        return height
    }

    
    
    // MARK: Utility Methods
    
    private func cellHeightForIngredients() -> CGFloat
    {
        let     arrayOfLines  = ingredientsText.components( separatedBy: "\n" )
        var     cellHeight    : CGFloat = 40.0
        let     heightPerLine : CGFloat = 21.0
        
        
        cellHeight += CGFloat( arrayOfLines.count ) * heightPerLine
        
        return cellHeight
    }
    
    
    private func cellHeightForSteps() -> CGFloat
    {
        let     arrayOfLines  = stepsText.components( separatedBy: "\n" )
        var     cellHeight    : CGFloat = 40.0
        let     heightPerLine : CGFloat = 21.0
        
        
        cellHeight += CGFloat( arrayOfLines.count ) * heightPerLine
        
        return cellHeight
    }
    
    
    private func configureBarButtonItem()
    {
        let launchedFromMasterView = UIDevice.current.userInterfaceIdiom == .pad

        navigationItem.leftBarButtonItem  = ( waitingForNotification ? nil : UIBarButtonItem.init( title: ( launchedFromMasterView ? NSLocalizedString( "ButtonTitle.Done", comment: "Done" ) : NSLocalizedString( "ButtonTitle.Back",   comment: "Back"   ) ),
                                                                                                   style: .plain,
                                                                                                   target: self,
                                                                                                   action: #selector( cancelBarButtonTouched ) ) )
    }
    

    private func dataChanged() -> Bool
    {
        var     dataChanged  = false
        

        if ( ( recipeName       != originalRecipeName   ) ||
             ( imageName        != originalImageName    ) ||
             ( ingredientsText  != originalIngredients  ) ||
             ( stepsText        != originalSteps        ) ||
             ( yield            != originalYield        ) ||
             ( yieldOptions     != originalYieldOptions ) )
        {
            dataChanged = true
        }
        
        logVerbose( "[ %@ ]", stringFor( dataChanged ) )
        
        return dataChanged
    }
    
    
    private func deleteImage()
    {
        if !ChefbookCentral.sharedInstance.deleteImageWith( name: imageName )
        {
            logVerbose( "ERROR: Unable to delete image[ %@ ]!", self.imageName )
            presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.UnableToDeleteImage", comment: "We were unable to delete the image you created." ) )
        }
        
        imageName     = String.init()
        imageAssigned = true
        
        updateChefbookCentral()
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
    
    
    @objc private func editRecipeName()
    {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.EditRecipeName", comment: "Edit recipe name" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let     nameTextField = alert.textFields![0] as UITextField
            
            
            if var textStringName = nameTextField.text
            {
                textStringName = textStringName.trimmingCharacters( in: .whitespacesAndNewlines )
                
                if !textStringName.isEmpty
                {
                    logTrace( "We have a non-zero length string" )
                    
                    if textStringName == self.recipeName
                    {
                        logTrace( "No changes ... do nothing!" )
                        return
                    }
                    
                    if self.unique( recipeName: textStringName )
                    {
                        self.recipeName = textStringName
                        
                        self.updateChefbookCentral()
                    }
                    else
                    {
                        logTrace( "ERROR:  Duplicate name field!" )
                        self.presentAlert( title:   NSLocalizedString( "AlertTitle.Error",                 comment: "Error!" ),
                                           message: NSLocalizedString( "AlertMessage.DuplicateRecipeName", comment: "The recipe name you choose already exists.  Please try again." ) )
                    }
                    
                }
                else
                {
                    logTrace( "ERROR:  Name field cannot be left blank!" )
                    self.presentAlert( title:   NSLocalizedString( "AlertTitle.Error",               comment: "Error!" ),
                                       message: NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank" ) )
                }
                
            }
            
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        
        alert.addTextField
            { ( textField ) in
                
                if self.recipeName.isEmpty
                {
                    textField.placeholder = NSLocalizedString( "LabelText.Name", comment: "Name" )
                }
                else
                {
                    textField.text = self.recipeName
                }
                
                textField.autocapitalizationType = .words
        }
        
        alert.addAction( saveAction   )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    @objc private func editRecipeYield()
    {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.EditRecipeYield", comment: "Edit recipe yield" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let     yieldTextField = alert.textFields![0] as UITextField
            
            
            if var textStringName = yieldTextField.text
            {
                textStringName = textStringName.trimmingCharacters( in: .whitespacesAndNewlines )
                
                if !textStringName.isEmpty
                {
                    logTrace( "We have a non-zero length string" )
                    
                    if textStringName == self.yield
                    {
                        logTrace( "No changes ... do nothing!" )
                        return
                    }
                    
                    self.yield = textStringName
                    
                    self.updateChefbookCentral()
                }
                else
                {
                    logTrace( "ERROR:  Yield field cannot be left blank!" )
                    self.presentAlert( title:   NSLocalizedString( "AlertTitle.Error",               comment: "Error!" ),
                                       message: NSLocalizedString( "AlertMessage.YieldCannotBeBlank", comment: "Yield cannot be left blank" ) )
                }
                
            }
            
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        
        alert.addTextField
            { ( textField ) in
                
                if self.recipeName.isEmpty
                {
                    textField.placeholder = NSLocalizedString( "LabelText.Yield", comment: "Yield" )
                }
                else
                {
                    textField.text = self.yield
                }
                
                textField.autocapitalizationType = .words
        }
        
        alert.addAction( saveAction   )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    @objc private func editRecipeYieldOptions()
    {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.EditRecipeYieldOptions", comment: "Edit recipe yield options" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let     yieldOptionsTextField = alert.textFields![0] as UITextField
            
            
            if var textStringName = yieldOptionsTextField.text
            {
                textStringName = textStringName.trimmingCharacters( in: .whitespacesAndNewlines )
                
                if !textStringName.isEmpty
                {
                    logTrace( "We have a non-zero length string" )
                    
                    if textStringName == self.yieldOptions
                    {
                        logTrace( "No changes ... do nothing!" )
                        return
                    }
                    
                    self.yieldOptions = textStringName
                    
                    self.updateChefbookCentral()
                }

            }
            
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        
        alert.addTextField
            { ( textField ) in
                
                if self.recipeName.isEmpty
                {
                    textField.placeholder = NSLocalizedString( "LabelText.YieldOptions", comment: "Yield Options" )
                }
                else
                {
                    textField.text = self.yieldOptions
                }
                
                textField.autocapitalizationType = .words
        }
        
        alert.addAction( saveAction   )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func initializeVariables()
    {
        logTrace()
        let         chefbookCentral = ChefbookCentral.sharedInstance
        var         frame           = CGRect.zero
        
        
        frame.size.height = .leastNormalMagnitude
        
        myTableView.tableHeaderView = UIView( frame: frame )
        myTableView.tableFooterView = UIView( frame: frame )
        myTableView.contentInsetAdjustmentBehavior = .never
        
        if NEW_RECIPE == indexOfItemBeingEdited
        {
            imageName       = String()
            ingredientsText = String()
            recipeName      = String()
            stepsText       = String()
            yield           = String()
            yieldOptions    = String()
        }
        else
        {
            let         recipe = chefbookCentral.recipeArray[indexOfItemBeingEdited]
            
            
            imageName       = recipe.imageName     ?? ""
            ingredientsText = recipe.ingredients   ?? ""
            recipeName      = recipe.name          ?? ""
            stepsText       = recipe.steps         ?? ""
            yield           = recipe.yield         ?? ""
            yieldOptions    = recipe.yieldOptions  ?? ""
            
        }
        
        originalImageName    = imageName
        originalIngredients  = ingredientsText
        originalRecipeName   = recipeName
        originalSteps        = stepsText
        originalYield        = yield
        originalYieldOptions = yieldOptions
        
        imageAssigned = true
    }
    
    
    private func launchImageViewController()
    {
        logVerbose( "imageName[ %@ ]", imageName )
        if let imageViewController: ImageViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.imageViewer ) as? ImageViewController
        {
            imageViewController.imageName = imageName
            
            navigationController?.pushViewController( imageViewController, animated: true )
        }
        else
        {
            logTrace( "ERROR: Could NOT load ImageViewController!" )
        }
        
    }
    
    
    private func launchIngredientsEditorViewController()
    {
        logVerbose( "ingredientsText[ %@ ]", ingredientsText )
        if let ingredientsEditorViewController: IngredientsEditorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.ingredientsEditor ) as? IngredientsEditorViewController
        {
            ingredientsEditorViewController.delegate    = self
            ingredientsEditorViewController.ingredients = ingredientsText
            
            navigationController?.pushViewController( ingredientsEditorViewController, animated: true )
        }
        else
        {
            logTrace( "ERROR: Could NOT load IngredientsEditorViewController!" )
        }
        
    }
    
    
    private func launchStepsEditorViewController()
    {
        logVerbose( "stepsText[ %@ ]", stepsText )
        if let stepsEditorViewController: StepsEditorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.stepsEditor ) as? StepsEditorViewController
        {
            stepsEditorViewController.delegate = self
            stepsEditorViewController.steps    = stepsText
            
            navigationController?.pushViewController( stepsEditorViewController, animated: true )
        }
        else
        {
            logTrace( "ERROR: Could NOT load StepsEditorViewController!" )
        }
        
    }
    
    
    private func loadImageViewCell() -> UITableViewCell
    {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.image ) else
        {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        
        logVerbose( "[ %@ ]", imageName )
        let imageCell = cell as! RecipeImageTableViewCell
        
        
        imageCell.delegate = self
        imageCell.initializeWith( imageName: imageName )
        
        return cell
    }
    
    
    private func loadIngredientsCell() -> UITableViewCell
    {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.ingredients ) else
        {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        
        logVerbose( "[ %@ ]", ingredientsText )
        let ingredientsCell = cell as! RecipeIngredientsTableViewCell
        
        
        ingredientsCell.initializeWith( ingredientsList: ingredientsText )
        
        return cell
    }
    
    
    private func loadRecipeNameCell() -> UITableViewCell
    {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.name ) else
        {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        
        logTrace()
        let recipeNameCell = cell as! RecipeNameTableViewCell
        
        
        recipeNameCell.initializeWith( recipeName: recipeName )
        
        if firstTimeIn && ( NEW_RECIPE == indexOfItemBeingEdited )
        {
            firstTimeIn = false
            
            DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.2 ) )
            {
                self.editRecipeName()
            }
            
        }
        
        return cell
    }
    
    
    private func loadStepsCell() -> UITableViewCell
    {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.steps ) else
        {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        
        logVerbose( "[ %@ ]", stepsText )
        let stepsCell = cell as! RecipeStepsTableViewCell
        
        
        stepsCell.initializeWith( stepsList: stepsText )
        
        return cell
    }
    
    
    private func loadYieldCell() -> UITableViewCell
    {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.yield ) else
        {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        
        logVerbose( "[ %@ ]", yield )
        let yieldCell = cell as! RecipeYieldTableViewCell
        
        
        yieldCell.initializeWith( yield: yield )
        
        return cell
    }
    
    
    private func loadYieldOptionsCell() -> UITableViewCell
    {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIdentifiers.yieldOptions ) else
        {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        
        logVerbose( "[ %@ ]", yieldOptions )
        let yieldOptionsCell = cell as! RecipeYieldOptionsTableViewCell
        
        
        yieldOptionsCell.initializeWith( yieldOptions: yieldOptions )
        
        return cell
    }
    
    
    private func openImagePickerFor( sourceType: UIImagePickerController.SourceType )
    {
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
    
    
    private func promptForImageDispostion()
    {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.ImageDisposition", comment: "What would you like to do with this image?" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     deleteAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Delete", comment: "Delete" ), style: .default )
        { ( alertAction ) in
            logTrace( "Delete Action" )
            
            self.deleteImage()
            
            self.imageCell.initializeWith( imageName: self.imageName )
        }
        
        let     replaceAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Replace", comment: "Replace" ), style: .default )
        { ( alertAction ) in
            logTrace( "Replace Action" )
            
            self.deleteImage()
            
            self.imageCell.initializeWith( imageName: self.imageName )
            
            self.promptForImageSource()
        }
        
        let     zoomAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.ZoomIn", comment: "Zoom In" ), style: .default )
        { ( alertAction ) in
            logTrace( "Zoom In Action" )
            
            if self.dataChanged()
            {
                self.loadingImageView = true
                self.updateChefbookCentral()
            }
            else
            {
                self.launchImageViewController()
            }
            
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
        
        
        if UIImagePickerController.isSourceTypeAvailable( .camera )
        {
            alert.addAction( cameraAction )
        }
        
        alert.addAction( albumAction  )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func unique( recipeName: String ) -> Bool
    {
        let     chefbookCentral   = ChefbookCentral.sharedInstance
        var     numberOfInstances = 0
        
        
        for recipe in chefbookCentral.recipeArray
        {
            if ( recipeName.uppercased() == recipe.name?.uppercased() )
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
    
    
    private func updateChefbookCentral()
    {
        logTrace()
        let     chefbookCentral = ChefbookCentral.sharedInstance
        
        
        chefbookCentral.delegate = self
        
        if NEW_RECIPE == indexOfItemBeingEdited
        {
            chefbookCentral.addRecipe( name: recipeName,
                                       imageName: imageName,
                                       ingredients: ingredientsText,
                                       isFormulaType: false,
                                       steps: stepsText,
                                       yield: yield,
                                       yieldOptions: yieldOptions )
        }
        else
        {
            let     recipe = chefbookCentral.recipeArray[indexOfItemBeingEdited]
            
            
            recipe.name             = recipeName
            recipe.imageName        = imageName
            recipe.ingredients      = ingredientsText
            recipe.isFormulaType    = false
            recipe.steps            = stepsText
            recipe.yield            = yield
            recipe.yieldOptions     = yieldOptions
            
            chefbookCentral.saveUpdatedRecipe( recipe: recipe )
        }
        
        imageAssigned = true
    }
    

    
    



}
