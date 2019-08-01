//
//  RecipeIngredientsTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 7/31/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


class RecipeIngredientsTableViewCell: UITableViewCell
{
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var itemsLabel: UILabel!
    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        logTrace()
    }
    
    
    override func setSelected(_ selected: Bool,
                                animated: Bool )
    {
        super.setSelected( false, animated: animated )
    }
    
    
    
    // MARK: Public Initializer
    
    func initializeWith( ingredientsList: String )
    {
        logTrace()
        titleLabel?.text = NSLocalizedString( "CellTitle.Ingredients", comment: "Ingredients" )
        itemsLabel?.text = ingredientsList
    }


}
