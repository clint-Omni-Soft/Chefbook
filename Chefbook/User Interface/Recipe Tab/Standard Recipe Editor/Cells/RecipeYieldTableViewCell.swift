//
//  RecipeYieldTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 8/2/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


class RecipeYieldTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var yieldLabel: UILabel!
    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
        logTrace()
    }

    override func setSelected(_ selected: Bool, animated: Bool ) {
        super.setSelected( false, animated: animated )
    }
    
    
    
    // MARK: Public Initializer
    
    func initializeWith( yield: String ) {
        logTrace()
        titleLabel?.text = NSLocalizedString( "CellTitle.Yield", comment: "Yield" )
        yieldLabel?.text = yield
    }

}
