//
//  FormulaImageTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 7/27/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit

protocol FormulaImageTableViewCellDelegate: class {
    
    func formulaImageTableViewCell( formulaImageTableViewCell: FormulaImageTableViewCell,
                                    cameraButtonTouched: Bool )
}



class FormulaImageTableViewCell: UITableViewCell {
    
    // MARK: Public Variables ... these are guaranteed to be set by our creator
    weak var delegate: FormulaImageTableViewCellDelegate?
    
    @IBOutlet weak var cameraButton     : UIButton!
    @IBOutlet weak var formulaImageView : UIImageView!
    
    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        logTrace()
   }
    

    override func setSelected(_ selected: Bool,
                                animated: Bool) {
        super.setSelected( false, animated: animated)
    }

    
    
    // MARK: Target/Action Methods
    
    @IBAction func cameraButtonTouched(_ sender: UIButton) {
        logTrace()
        delegate?.formulaImageTableViewCell( formulaImageTableViewCell: self,
                                             cameraButtonTouched: true )
    }
    
    
    // MARK: Public Initializer
    
    func initializeWith(_ imageName: String ) {
//        logVerbose( "imageName[ %@ ]", imageName )
        
        cameraButton.setImage( ( imageName.isEmpty ? UIImage.init( named: "camera" ) : nil ), for: .normal )
        cameraButton.backgroundColor = ( imageName.isEmpty ? .white : .clear )
        
        formulaImageView.image = ( imageName.isEmpty ? nil : ChefbookCentral.sharedInstance.imageWith( imageName ) )
    }
    
}
