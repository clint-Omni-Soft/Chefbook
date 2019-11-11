//
//  FormulaIngredientTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 9/3/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol FormulaIngredientTableViewCellDelegate: class {
    
    func formulaIngredientTableViewCell( formulaIngredientTableViewCell : FormulaIngredientTableViewCell,
                                         ingredientIndexPath            : IndexPath,
                                         isNew                          : Bool,
                                         editedIngredientName           : String,
                                         editedPercentage               : String )

    func formulaIngredientTableViewCell( formulaIngredientTableViewCell : FormulaIngredientTableViewCell,
                                         ingredientIndexPath            : IndexPath,
                                         didStartEditing                : Bool )
}


class FormulaIngredientTableViewCell: UITableViewCell {

    @IBOutlet weak var addOrEditButton           : UIButton!
    @IBOutlet weak var ingredientTextField       : UITextField!
    @IBOutlet weak var invisibleIngredientButton : UIButton!
    @IBOutlet weak var invisiblePercentageButton : UIButton!
    @IBOutlet weak var percentageTextField       : UITextField!
    @IBOutlet weak var weightLabel               : UILabel!
    
    

    // MARK: Public Variables
    
    weak var delegate : FormulaIngredientTableViewCellDelegate!
    
    
    // MARK: Private Variables
    
    private var inEditMode         = false
    private var isFlour            = false
    private var isNew              = false
    private var myIndexPath        : IndexPath!
    private var percentageHasFocus = true

    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
//        logTrace()
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool, animated: Bool ) {
        super.setSelected( false, animated: false )
    }
    
    
    
    // MARK: Public Initializers
    
    func setupAsHeader() {
//        logTrace()
        backgroundColor = .lightGray
        ingredientTextField.backgroundColor = .lightGray
        percentageTextField.backgroundColor = .lightGray

        ingredientTextField.textColor = .black
        percentageTextField.textColor = .black

        ingredientTextField.text = NSLocalizedString( "LabelText.Ingredient", comment: "Ingredient" )
        percentageTextField.text = "%"
        weightLabel        .text = String( format: "%@ g", NSLocalizedString( "LabelText.Weight", comment: "Weight" ) )
        
        ingredientTextField.borderStyle = .none
        percentageTextField.borderStyle = .none
        
        addOrEditButton          .isHidden = true
        invisibleIngredientButton.isHidden = true
        invisiblePercentageButton.isHidden = true
    }
    
    
    func initializeWithRecipeAt( recipeIndex         : Int,
                                 ingredientIndexPath : IndexPath,
                                 isNew               : Bool,
                                 delegate            : FormulaIngredientTableViewCellDelegate ) {
//        logTrace()
        self.delegate = delegate
        self.isNew    = isNew
        myIndexPath   = ingredientIndexPath
        isFlour       = ( myIndexPath.section == ForumlaTableSections.flour )
        inEditMode    = false
        
        backgroundColor = isFlour ? .yellow : .white
        
        addOrEditButton.setImage( UIImage( named: "checkmark" ), for: .normal )
        addOrEditButton.setTitle( "", for: .normal )
        
        let recipe = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]

        if isNew {
            if isFlour {
                ingredientTextField.text = NSLocalizedString( "CellTitle.Flour", comment: "Flour" )
                percentageTextField.text = ( self.myIndexPath.row == 0 ? "100" : "" )
                weightLabel        .text = ""
            }
            else {
                ingredientTextField.text = ingredientNameFor( recipe : recipe )
                percentageTextField.text = ( self.myIndexPath.row == 0 ? "50" : "" )
                weightLabel        .text = ""
            }
            
            DispatchQueue.main.asyncAfter(deadline: ( .now() + 0.2 ), execute: {
                self.invisiblePercentageButtonTouched( self )
            })
            
        }
        else {
            let ingredient = ingredientFrom( recipe : recipe )
            
            ingredientTextField.text = ingredient.name
            percentageTextField.text = String( format : "%d", ingredient.percentOfFlour )
            weightLabel        .text = String( format : "%d", ingredient.weight         )

            configureControls()
        }
        
    }
    
    

    // MARK: Target/Action Methods
    
    @IBAction func addOrEditButtonTouched(_ sender: Any) {
        
        let     percentage = Int( percentageTextField.text ?? "0" )
        
        if inEditMode && ( ( ingredientTextField.text?.isEmpty ?? true ) || ( percentageTextField.text?.isEmpty ?? true ) || ( percentage == 0 ) ) {
            logTrace( "ERROR:  ingredientTextField?.isEmpty or percentage == 0" )
            return
        }

//        logTrace()
        inEditMode = !inEditMode
        
        configureControls()
        
        if !inEditMode {
            ingredientTextField.resignFirstResponder()
            percentageTextField.resignFirstResponder()
            
            delegate.formulaIngredientTableViewCell( formulaIngredientTableViewCell : self,
                                                     ingredientIndexPath            : myIndexPath,
                                                     isNew                          : isNew,
                                                     editedIngredientName           : ingredientTextField.text ?? "",
                                                     editedPercentage               : percentageTextField.text ?? "" )
        }
            
    }
    
    
    @IBAction func invisibleIngredientButtonTouched(_ sender: Any ) {
        percentageHasFocus = false
        delegate.formulaIngredientTableViewCell( formulaIngredientTableViewCell: self,
                                                 ingredientIndexPath            : myIndexPath,
                                                 didStartEditing                : true )
        inEditMode = !inEditMode
        
        configureControls()
    }
    
    
    @IBAction func invisiblePercentageButtonTouched(_ sender: Any ) {
        percentageHasFocus = true
        delegate.formulaIngredientTableViewCell( formulaIngredientTableViewCell: self,
                                                 ingredientIndexPath            : myIndexPath,
                                                 didStartEditing                : true )
        inEditMode = !inEditMode
        
        configureControls()
  }
    
    
    
    // MARK: Utility Methods
    
    private func configureControls() {
        
        ingredientTextField.borderStyle = inEditMode ? .roundedRect : .none
        ingredientTextField.isEnabled   = inEditMode
        ingredientTextField.textColor   = inEditMode ? .black : .blue

        percentageTextField.borderStyle = inEditMode ? .roundedRect : .none
        percentageTextField.isEnabled   = inEditMode
        percentageTextField.textColor   = inEditMode ? .black : .blue

        ingredientTextField.backgroundColor = .white
        percentageTextField.backgroundColor = .white
        
        if myIndexPath.section == ForumlaTableSections.flour {
            
            ingredientTextField.backgroundColor = inEditMode ? .white : .yellow
            percentageTextField.backgroundColor = inEditMode ? .white : .yellow
        }
        
        if isNew && ( myIndexPath == IndexPath( item: 0, section: ForumlaTableSections.flour ) ) {
            
            percentageTextField.borderStyle = .none
            percentageTextField.isEnabled   = false
        }
        else {
            percentageTextField.borderStyle = inEditMode ? .roundedRect : .none
            percentageTextField.isEnabled   = inEditMode
        }
        
        addOrEditButton          .isHidden = !inEditMode
        invisibleIngredientButton.isHidden =  inEditMode
        invisiblePercentageButton.isHidden =  inEditMode
        
        if inEditMode {
            
            if percentageHasFocus {
                percentageTextField.becomeFirstResponder()
            }
            else {
                ingredientTextField.becomeFirstResponder()
            }
            
        }
        
    }
    
    
    private func ingredientFrom( recipe : Recipe ) -> BreadIngredient {
        
        var     selectedIngredient : BreadIngredient!
        let     dataSource         = ( isFlour ? recipe.flourIngredients : recipe.breadIngredients )
        let     ingredientArray    = dataSource?.allObjects as! [BreadIngredient]
        
        
        for ingredient in ingredientArray {
            
            if ingredient.index == myIndexPath.row {
                
//              logVerbose( "Found it ... [ %@ ]", ingredient.name ?? "Unknown" )
                selectedIngredient = ingredient
                break
            }
            
        }
        
        return selectedIngredient
    }
    
    
    private func ingredientNameFor( recipe : Recipe ) -> String {
        let     ingredientArray = recipe.breadIngredients?.allObjects as! [BreadIngredient]
        var     name            = "??"
        var     waterPresent    = false
        var     yeastPresent    = false

        
        for ingredient in ingredientArray {
            
            switch ingredient.ingredientType {
            case BreadIngredientTypes.water:    waterPresent = true
            case BreadIngredientTypes.yeast:    yeastPresent = true
            default:
                break
            }
            
        }

        if !waterPresent {
            name = NSLocalizedString( "IngredientType.Water", comment: "Water" )
        }
        else if !yeastPresent {
            name = NSLocalizedString( "IngredientType.Yeast", comment: "Yeast" )
        }
        
        return name
    }
    
    
}
