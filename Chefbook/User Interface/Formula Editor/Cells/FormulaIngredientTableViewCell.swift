//
//  FormulaIngredientTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 9/3/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol FormulaIngredientTableViewCellDelegate: class
{
    func formulaIngredientTableViewCell( formulaIngredientTableViewCell : FormulaIngredientTableViewCell,
                                         ingredientIndexPath            : IndexPath,
                                         isNew                          : Bool,
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
    
    weak var delegate : FormulaIngredientTableViewCellDelegate!
    
    
    // MARK: Private Variables
    
    private var inEditMode  = false
    private var isFlour     = false
    private var isNew       = false
    private var myIndexPath : IndexPath!
    
    
    
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
        let     percentage = Int( percentageTextField.text ?? "0" )
        
        
        if inEditMode && ( ( ingredientTextField.text?.isEmpty ?? true ) || ( percentageTextField.text?.isEmpty ?? true ) || ( percentage == 0 ) )
        {
            logTrace( "ERROR:  ingredientTextField?.isEmpty or percentage == 0" )
            return
        }
        

        logTrace()
        inEditMode = !inEditMode
        
        ingredientTextField.borderStyle = inEditMode ? .roundedRect : .none
        ingredientTextField.isEnabled   = inEditMode
        
        ingredientTextField.backgroundColor = .white
        
        if myIndexPath.section == 1     // flour
        {
            ingredientTextField.backgroundColor = inEditMode ? .white : .yellow
            percentageTextField.backgroundColor = inEditMode ? .white : .yellow
        }
        
        if isNew && myIndexPath == IndexPath( item: 0, section: 1 )
        {
            percentageTextField.borderStyle = .none
            percentageTextField.isEnabled   = false
        }
        else
        {
            percentageTextField.borderStyle = inEditMode ? .roundedRect : .none
            percentageTextField.isEnabled   = inEditMode
        }
        
        addOrEditButton.setImage( UIImage(named: ( inEditMode ? "checkmark" : "pencil" ) ), for: .normal )
        
        if !inEditMode
        {
            ingredientTextField.endEditing( true )
            percentageTextField.endEditing( true )
            
            delegate.formulaIngredientTableViewCell( formulaIngredientTableViewCell : self,
                                                     ingredientIndexPath            : myIndexPath,
                                                     isNew                          : isNew,
                                                     editedIngredientName           : ingredientTextField.text ?? "",
                                                     editedPercentage               : percentageTextField.text ?? "" )
        }
            
    }
    
    
    
    // MARK: Public Initializers
    
    func setupAsHeader()
    {
//        logTrace()
        backgroundColor = .lightGray

        ingredientTextField.text = NSLocalizedString( "LabelText.Ingredient", comment: "Ingredient" )
        percentageTextField.text = "%"
        weightLabel        .text = NSLocalizedString( "LabelText.Weight",     comment: "Weight"     )
        
        ingredientTextField.borderStyle = .none
        percentageTextField.borderStyle = .none

        addOrEditButton.isHidden = true
    }
    
    
    func initializeWithRecipeAt( recipeIndex         : Int,
                                 ingredientIndexPath : IndexPath,
                                 isNew               : Bool,
                                 delegate            : FormulaIngredientTableViewCellDelegate )
    {
//        logTrace()
        self.delegate = delegate
        self.isNew    = isNew
        isFlour       = ingredientIndexPath.section == 1
        myIndexPath   = ingredientIndexPath
        
        setupCell()

        if isNew
        {
            ingredientTextField.text = isFlour ? NSLocalizedString( "CellTitle.Flour", comment: "Flour" ) : "???"
            percentageTextField.text = isFlour ? ( self.myIndexPath.row == 0 ? "100" : "" ) : ""
            weightLabel        .text = ""
            
            addOrEditButtonTouched( self )
        }
        else
        {
            let recipe     = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
            let ingredient = ingredientFrom( recipe : recipe )
            
            
            ingredientTextField.text = ingredient.name
            percentageTextField.text = String( format: "%d",   ingredient.percentOfFlour )
            weightLabel        .text = String( format: "%d g", ingredient.weight         )
        }

    }

    
    
    // MARK: Utility Methods
    
    private func ingredientFrom( recipe : Recipe ) -> BreadIngredient
    {
        var     selectedIngredient : BreadIngredient!
        let     dataSource         = ( isFlour ? recipe.flourIngredients : recipe.breadIngredients )
        let     ingredientArray    = dataSource?.allObjects as! [BreadIngredient]
        
        
        for ingredient in ingredientArray
        {
            if ingredient.index == myIndexPath.row
            {
//              logVerbose( "Found it ... [ %@ ]", ingredient.name ?? "Unknown" )
                selectedIngredient = ingredient
                break
            }

        }
        
        return selectedIngredient
    }
    
    
    private func setupCell()
    {
        backgroundColor = isFlour ? .yellow : .white
        
        addOrEditButton.isHidden = false
        addOrEditButton.setImage( UIImage( named: ( inEditMode ? "checkmark" : "pencil" ) ), for: .normal )
        addOrEditButton.setTitle( "", for: .normal )

        ingredientTextField.borderStyle = .none
        percentageTextField.borderStyle = .none

        ingredientTextField.isEnabled = false
        percentageTextField.isEnabled = false
    }
    
    
}
