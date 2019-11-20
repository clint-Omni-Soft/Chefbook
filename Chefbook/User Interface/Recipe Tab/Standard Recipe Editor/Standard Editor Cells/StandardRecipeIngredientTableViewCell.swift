//
//  StandardRecipeIngredientTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 9/3/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol StandardRecipeIngredientTableViewCellDelegate: class {
    
    func standardRecipeIngredientTableViewCell( standardRecipeIngredientTableViewCell : StandardRecipeIngredientTableViewCell,
                                                ingredientIndexPath                   : IndexPath,
                                                isNew                                 : Bool,
                                                editedName                            : String,
                                                editedAmount                          : String )

    func standardRecipeIngredientTableViewCell( standardRecipeIngredientTableViewCell : StandardRecipeIngredientTableViewCell,
                                                ingredientIndexPath                   : IndexPath,
                                                didStartEditing                       : Bool )

    func standardRecipeIngredientTableViewCell( standardRecipeIngredientTableViewCell : StandardRecipeIngredientTableViewCell,
                                                requestNewIngredient                  : Bool )
}


class StandardRecipeIngredientTableViewCell: UITableViewCell {

    @IBOutlet weak var addOrEditButton           : UIButton!
    @IBOutlet weak var amountTextField           : UITextField!
    @IBOutlet weak var ingredientTextField       : UITextField!
    @IBOutlet weak var invisibleAmountButton     : UIButton!
    @IBOutlet weak var invisibleIngredientButton : UIButton!
    
    

    // MARK: Public Variables
    
    weak var delegate : StandardRecipeIngredientTableViewCellDelegate!
    
    
    // MARK: Private Variables
    
    private var inEditMode          = false
    private var isHeader            = false
    private var isNew               = false
    private var ingredientIndexPath = IndexPath( item: 0, section: 0 )
    private var amountHasFocus      = true

    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
//        logTrace()
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool, animated: Bool ) {
        super.setSelected( false, animated: false )
    }
    
    
    
    // MARK: Public Initializers
    
    func setupAsHeaderWithDelegate(_ delegate : StandardRecipeIngredientTableViewCellDelegate ) {
//        logTrace()
        self.delegate = delegate
        isHeader = true
        backgroundColor = .lightGray
        
        ingredientTextField.backgroundColor = .lightGray
        amountTextField    .backgroundColor = .lightGray

        ingredientTextField.textColor = .black
        amountTextField    .textColor = .black

        ingredientTextField.text = NSLocalizedString( "LabelText.Ingredient", comment: "Ingredient" )
        amountTextField    .text = NSLocalizedString( "LabelText.Amount",     comment: "Amount" )
        
        ingredientTextField.borderStyle = .none
        amountTextField    .borderStyle = .none
        
        ingredientTextField.isEnabled = false
        amountTextField    .isEnabled = false
        
        invisibleIngredientButton.isHidden = true
        invisibleAmountButton    .isHidden = true
 
        addOrEditButton.setImage( nil, for: .normal )
        addOrEditButton.setTitle( "+", for: .normal )
    }
    
    
    func initializeWithRecipeAt( recipeIndex         : Int,
                                 ingredientIndexPath : IndexPath,
                                 isNew               : Bool,
                                 delegate            : StandardRecipeIngredientTableViewCellDelegate ) {
//        logTrace()
        self.delegate            = delegate
        self.isNew               = isNew
        self.ingredientIndexPath = ingredientIndexPath
        inEditMode               = false
        isHeader                 = false

        backgroundColor = .white
        
        addOrEditButton.setImage( UIImage( named: "checkmark" ), for: .normal )
        addOrEditButton.setTitle( "", for: .normal )
        
        let recipe = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]

        if isNew {
            amountTextField    .text = "?"
            ingredientTextField.text = "?"
            
            DispatchQueue.main.asyncAfter(deadline: ( .now() + 0.2 ), execute: {
                self.invisibleIngredientButtonTouched( self )
            })
            
        }
        else {
            let ingredient = ingredientFrom( recipe )
            
            amountTextField    .text = ingredient.amount
            ingredientTextField.text = ingredient.name

            configureControls()
        }
        
    }
    
    

    // MARK: Target/Action Methods
    
    @IBAction func addOrEditButtonTouched(_ sender: Any) {
        
        if isHeader {
            delegate.standardRecipeIngredientTableViewCell( standardRecipeIngredientTableViewCell : self,
                                                            requestNewIngredient                  : true )
            return
        }
        
        
        let     weight = Int( amountTextField.text ?? "0" )
        
        if inEditMode && ( ( ingredientTextField.text?.isEmpty ?? true ) || ( amountTextField.text?.isEmpty ?? true ) || ( weight == 0 ) ) {
            logTrace( "ERROR:  ingredientTextField?.isEmpty or percentage == 0" )
            return
        }

//        logTrace()
        inEditMode = !inEditMode
        
        configureControls()
        
        if !inEditMode {
            amountTextField    .resignFirstResponder()
            ingredientTextField.resignFirstResponder()

            delegate.standardRecipeIngredientTableViewCell( standardRecipeIngredientTableViewCell : self,
                                                            ingredientIndexPath                   : ingredientIndexPath,
                                                            isNew                                 : isNew,
                                                            editedName                            : ingredientTextField.text ?? "",
                                                            editedAmount                          : amountTextField.text ?? "" )
        }
            
    }
    
    
    @IBAction func invisibleAmountButtonTouched(_ sender: Any ) {
        amountHasFocus = true
        delegate.standardRecipeIngredientTableViewCell( standardRecipeIngredientTableViewCell : self,
                                                        ingredientIndexPath                   : ingredientIndexPath,
                                                        didStartEditing                       : true )
        inEditMode = !inEditMode
        
        configureControls()
    }
    
    
    @IBAction func invisibleIngredientButtonTouched(_ sender: Any ) {
        amountHasFocus = false
        delegate.standardRecipeIngredientTableViewCell( standardRecipeIngredientTableViewCell : self,
                                                        ingredientIndexPath                   : ingredientIndexPath,
                                                        didStartEditing                       : true )
        inEditMode = !inEditMode
        
        configureControls()
    }
    
    
    
    // MARK: Utility Methods
    
    private func configureControls() {
        
        amountTextField    .backgroundColor = .white
        amountTextField    .borderStyle     = inEditMode ? .roundedRect : .none
        amountTextField    .isEnabled       = inEditMode
        amountTextField    .textColor       = inEditMode ? .black : .blue
        
        ingredientTextField.backgroundColor = .white
        ingredientTextField.borderStyle     = inEditMode ? .roundedRect : .none
        ingredientTextField.isEnabled       = inEditMode
        ingredientTextField.textColor       = inEditMode ? .black : .blue

        addOrEditButton          .isHidden = !inEditMode
        invisibleIngredientButton.isHidden =  inEditMode
        invisibleAmountButton    .isHidden =  inEditMode
        
        if inEditMode {
            
            if amountTextField.text == "?" {
                amountTextField.text = ""
            }
            
            if ingredientTextField.text == "?" {
                ingredientTextField.text = ""
            }
            
            if amountHasFocus {
                amountTextField.becomeFirstResponder()
            }
            else {
                ingredientTextField.becomeFirstResponder()
            }
            
        }
        
    }
    
    
    private func ingredientFrom(_ recipe : Recipe ) -> StandardIngredient {
        
        var     selectedIngredient : StandardIngredient!
        let     ingredientArray    = recipe.standardIngredients?.allObjects as! [StandardIngredient]
        
        for ingredient in ingredientArray {
            
            if ingredient.index == ingredientIndexPath.row {
                
//              logVerbose( "Found it ... [ %@ ]", ingredient.name ?? "Unknown" )
                selectedIngredient = ingredient
                break
            }
            
        }
        
        return selectedIngredient
    }
    
    
}
