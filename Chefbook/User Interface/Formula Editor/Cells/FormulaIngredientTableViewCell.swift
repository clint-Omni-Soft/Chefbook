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
    func formulaIngredientTableViewCell( FormulaIngredientTableViewCell: FormulaIngredientTableViewCell,
                                         requestingAdd: Bool )
}


class FormulaIngredientTableViewCell: UITableViewCell
{

    @IBOutlet weak var addButton        : UIButton!
    @IBOutlet weak var ingredientLabel  : UILabel!
    @IBOutlet weak var percentageLabel  : UILabel!
    @IBOutlet weak var quantityLabel    : UILabel!
    
    
    // MARK: Public Variables
    
    var delegate : FormulaIngredientTableViewCellDelegate!
    
    
    // MARK: Private Variables
    
    private var isFlour       = false
    private var weightOfFlour = 0
    
    
    
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
    
    @IBAction func addButtonTouched(_ sender: Any)
    {
        logTrace()
        delegate.formulaIngredientTableViewCell( FormulaIngredientTableViewCell: self, requestingAdd: true )
    }
    
    
    
    // MARK: Public Initializers
    
    func setupAsHeaderWith( delegate: FormulaIngredientTableViewCellDelegate )
    {
        self.delegate = delegate
        
        percentageLabel.text = "%"
        ingredientLabel.text = NSLocalizedString( "LabelText.Ingredient", comment: "Ingredient" )
        quantityLabel  .text = NSLocalizedString( "LabelText.Weight",     comment: "Weight"     )

        setupCellAt( ingredientIndex: 0, isHeader: true )
    }
    
    
    func initializeWithRecipeAt( index: Int, ingredientIndex: Int  )
    {
        let recipe = ChefbookCentral.sharedInstance.recipeArray[index]
        
        setupCellAt( ingredientIndex: ingredientIndex, isHeader: false )

        if flourIngredientPresentIn( recipe: recipe )
        {
            let breadIngredient = breadIngredientAt( index: ingredientIndex, recipe: recipe )
            let itemQuantity    = Float( weightOfFlour ) * ( Float( breadIngredient.percentOfFlour ) / 100 )
            
            percentageLabel.text = String( format: "%d", breadIngredient.percentOfFlour )
            ingredientLabel.text = breadIngredient.name
            quantityLabel  .text = String( format: "%d g", Int( itemQuantity ) )
        }
        else
        {
            isFlour = true
            percentageLabel.text = "100"
            ingredientLabel.text = NSLocalizedString( "CellTitle.Flour", comment: "Flour" )
            quantityLabel  .text = ""
        }

    }

    
    
    // MARK: Utility Methods
    
    private func breadIngredientAt( index: Int, recipe : Recipe ) -> BreadIngredient
    {
        var     breadIngredient : BreadIngredient!
        
        logVerbose( "[ %d ]", index )
        
        if recipe.breadIngredients?.count != 0
        {
            for case let ingredient as BreadIngredient in recipe.breadIngredients!
            {
                if ingredient.index == index
                {
                    logVerbose( "Found it ... [ %@ ]", ingredient.name ?? "Unknown" )
                    breadIngredient = ingredient
                    break
                }
                
            }
            
        }

        return breadIngredient
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
    
    
    private func setupCellAt( ingredientIndex : Int,
                              isHeader        : Bool )
    {
        addButton.isHidden = !isHeader
        
        if isHeader
        {
            backgroundColor = .lightGray
        }
        else if ingredientIndex == 0
        {
            backgroundColor = .yellow
        }
        else
        {
            backgroundColor = .white
        }
        
        percentageLabel.textColor = ( isHeader ? .black : .blue )
        ingredientLabel.textColor = ( isHeader ? .black : .blue )
        quantityLabel  .textColor = ( isHeader ? .black : .blue )
    }
    
    
}
