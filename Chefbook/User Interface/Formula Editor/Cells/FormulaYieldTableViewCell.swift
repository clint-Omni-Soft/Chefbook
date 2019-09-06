//
//  FormulaYieldTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 9/3/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//


import UIKit


class FormulaYieldTableViewCell: UITableViewCell
{

    @IBOutlet weak var yieldLabel: UILabel!
    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool, animated: Bool )
    {
        super.setSelected( false, animated: animated )
    }

    
    
    // MARK: Public Initializer
    
    func initializeWith( numberOfLoaves: Int,
                         loafWeight: Int )
    {
        logTrace()
        yieldLabel?.text = String( format: NSLocalizedString( "CellTitle.FormulaYieldFormat", comment: "Yield %d items weighing %dg" ), numberOfLoaves, loafWeight )
    }
    
}
