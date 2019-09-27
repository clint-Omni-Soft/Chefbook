//
//  RecipeImageTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 7/27/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit

protocol RecipeImageTableViewCellDelegate: class {
    
    func recipeImageTableViewCell( recipeImageTableViewCell: RecipeImageTableViewCell,
                                   cameraButtonTouched: Bool )
}



class RecipeImageTableViewCell: UITableViewCell {
    
    // MARK: Public Variables ... these are guaranteed to be set by our creator
    weak var delegate: RecipeImageTableViewCellDelegate?
    
    @IBOutlet weak var cameraButton     : UIButton!
    @IBOutlet weak var recipeImageView  : UIImageView!
    
    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
        logTrace()
   }
    

    override func setSelected(_ selected: Bool,
                                animated: Bool) {
        super.setSelected( false, animated: animated)
    }

    
    
    // MARK: Target/Action Methods
    
    @IBAction func cameraButtonTouched(_ sender: UIButton) {
        logTrace()
        delegate?.recipeImageTableViewCell( recipeImageTableViewCell: self,
                                            cameraButtonTouched: true )
    }
    
    
    // MARK: Public Initializer
    
    func initializeWith( imageName: String ) {
        logTrace()
        cameraButton.setImage( ( imageName.isEmpty ? UIImage.init( named: "camera" ) : nil ), for: .normal )
        cameraButton.backgroundColor = ( imageName.isEmpty ? .white : .clear )
        
        recipeImageView.image = ( imageName.isEmpty ? nil : ChefbookCentral.sharedInstance.imageWith( name: imageName ) )
    }
    
}
