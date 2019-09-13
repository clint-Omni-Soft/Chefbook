//
//  FormulaIngredientTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 9/3/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol FormulaIngredientTableViewCellDelegate
{
    func formulaIngredientTableViewCell( formulaIngredientTableViewCell : FormulaIngredientTableViewCell,
                                         requestingAdd                  : Bool )
    
    func formulaIngredientTableViewCell( formulaIngredientTableViewCell : FormulaIngredientTableViewCell,
                                         ingredientIndex                : Int,
                                         editedIngredientName           : String,
                                         editedPercentage               : String )
}


class FormulaIngredientTableViewCell: UITableViewCell
{

    @IBOutlet weak var addOrEditButton      : UIButton!
    @IBOutlet weak var ingredientTextField  : UITextField!
    @IBOutlet weak var percentageTextField  : UITextField!
    @IBOutlet weak var weightLabel          : UILabel!
    
    

    // MARK: Public Variables
    
    var delegate : FormulaIngredientTableViewCellDelegate!
    
    
    // MARK: Private Variables
    
    private var inEditMode      = false
    private var ingredientIndex = 0
    private var isHeader        = false
    private var weightOfFlour   = 0
    
    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool, animated: Bool )
    {
        super.setSelected( false, animated: animated )
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func addOrEditButtonTouched(_ sender: Any)
    {
        logTrace()
        
        if isHeader
        {
            delegate.formulaIngredientTableViewCell( formulaIngredientTableViewCell : self,
                                                     requestingAdd                  : true )
        }
        else
        {
            let     percentage = Int( percentageTextField.text ?? "0" )
            
            
            if inEditMode && ( ( ingredientTextField.text?.isEmpty ?? true ) || ( percentageTextField.text?.isEmpty ?? true ) || ( percentage == 0 ) )
            {
                logTrace( "ERROR:  ingredientTextField?.isEmpty or percentage == 0" )
                return
            }
            
            logTrace()
            let isFlour = ingredientIndex == 0
            
            
            inEditMode = !inEditMode
            
            ingredientTextField.borderStyle = inEditMode ? .roundedRect : .none
            ingredientTextField.isEnabled   = inEditMode
            
            percentageTextField.borderStyle = ( inEditMode && !isFlour ) ? .roundedRect : .none
            percentageTextField.isEnabled   = ( inEditMode && !isFlour )
            
            addOrEditButton.setImage( UIImage(named: ( inEditMode ? "checkmark" : "pencil" ) ), for: .normal )
            
            if !inEditMode
            {
                ingredientTextField.endEditing( true )
                percentageTextField.endEditing( true )
                
                delegate.formulaIngredientTableViewCell( formulaIngredientTableViewCell : self,
                                                         ingredientIndex                : ingredientIndex,
                                                         editedIngredientName           : ingredientTextField.text ?? "",
                                                         editedPercentage               : percentageTextField.text ?? "" )
            }
            
        }
        
    }
    
    
    
    // MARK: Public Initializers
    
    func setupAsHeaderWith( delegate: FormulaIngredientTableViewCellDelegate )
    {
        logTrace()
        self.delegate = delegate
        self.isHeader = true
        
        ingredientTextField.text = NSLocalizedString( "LabelText.Ingredient", comment: "Ingredient" )
        percentageTextField.text = "%"
        weightLabel        .text = NSLocalizedString( "LabelText.Weight",     comment: "Weight"     )

        setupCellAt( ingredientIndex: 0 )
    }
    
    
    func initializeWithRecipeAt( recipeIndex     : Int,
                                 ingredientIndex : Int,
                                 isNew           : Bool,
                                 delegate        : FormulaIngredientTableViewCellDelegate )
    {
        logTrace()
        let isFlour = ingredientIndex == 0
        
        
        self.delegate        = delegate
        self.ingredientIndex = ingredientIndex
        
        setupCellAt( ingredientIndex: ingredientIndex )

        if isNew
        {
            ingredientTextField.text = isFlour ? NSLocalizedString( "CellTitle.Flour", comment: "Flour" ) : "???"
            percentageTextField.text = isFlour ? "100" : ""
            weightLabel        .text = ""
            
            addOrEditButtonTouched( self )
        }
        else
        {
            let recipe          = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
            let breadIngredient = breadIngredientAt( index: ingredientIndex, recipe: recipe )
            
            
            ingredientTextField.text = breadIngredient.name
            percentageTextField.text = String( format: "%d",   breadIngredient.percentOfFlour )
            weightLabel        .text = String( format: "%d g", breadIngredient.weight )
        }

    }

    
    
    // MARK: Utility Methods
    
    private func breadIngredientAt( index  : Int,
                                    recipe : Recipe ) -> BreadIngredient
    {
        var     breadIngredient : BreadIngredient!
        
//        logVerbose( "[ %d ]", index )
        
        if recipe.breadIngredients?.count != 0
        {
            for case let ingredient as BreadIngredient in recipe.breadIngredients!
            {
                if ingredient.index == index
                {
//                    logVerbose( "Found it ... [ %@ ]", ingredient.name ?? "Unknown" )
                    breadIngredient = ingredient
                    break
                }
                
            }
            
        }

        return breadIngredient
    }
    
    
    private func setupCellAt( ingredientIndex : Int )
    {
//        logVerbose( "[ %d ]", ingredientIndex )
        if isHeader
        {
            backgroundColor = .lightGray
            
            addOrEditButton.setImage( nil, for: .normal )
            addOrEditButton.setTitle( "+", for: .normal )
        }
        else
        {
            backgroundColor = ingredientIndex == 0 ? .yellow : .white
            
            addOrEditButton.setImage( UIImage( named: ( inEditMode ? "checkmark" : "pencil" ) ), for: .normal )
            addOrEditButton.setTitle( "", for: .normal )
        }

        ingredientTextField.borderStyle = .none
        percentageTextField.borderStyle = .none
    }
    
    
}
