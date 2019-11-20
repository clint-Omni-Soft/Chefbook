//
//  RecipeStepsTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 7/31/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


class StandardRecipeStepsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        logTrace()
    }
    
    
    override func setSelected(_ selected: Bool,
                                animated: Bool ) {
        super.setSelected( false, animated: animated )
    }
    
    
    
    // MARK: Public Initializer
    
    func setupAsHeader() {
        backgroundColor = .lightGray

        stepsLabel.isHidden = true
        titleLabel.isHidden = false
        
        titleLabel.text = NSLocalizedString( "CellTitle.Steps", comment: "Steps" )
    }
    
    
    func initializeWith( stepsList: String ) {
//        logTrace()
        backgroundColor = .white
        
        stepsLabel.isHidden = false
        titleLabel.isHidden = true
        
        stepsLabel?.text = stepsList.isEmpty ? "?" : stepsList
    }
    

}
