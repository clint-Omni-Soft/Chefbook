//
//  RecipeYieldOptionsTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 8/2/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


class RecipeYieldOptionsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel       : UILabel!
    @IBOutlet weak var yieldOptionsLabel: UILabel!
    
    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
        logTrace()
    }
    
    override func setSelected(_ selected: Bool,
                                animated: Bool ) {
        super.setSelected( false, animated: animated )
    }
    
    
    
    // MARK: Public Initializer
    
    func initializeWith( yieldOptions: String ) {
        logTrace()
        titleLabel?       .text = NSLocalizedString( "CellTitle.YieldOptions", comment: "YieldOptions" )
        yieldOptionsLabel?.text = yieldOptions
    }
    
}
