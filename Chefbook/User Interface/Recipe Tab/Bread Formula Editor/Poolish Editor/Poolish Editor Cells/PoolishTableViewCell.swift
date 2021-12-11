//
//  PoolishTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 10/14/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//


import UIKit


protocol PoolishTableViewCellDelegate: AnyObject {
    
    func poolishTableViewCell( poolishTableViewCell: PoolishTableViewCell, indexPath: IndexPath, didSetNew percentage: String )
    func poolishTableViewCell( poolishTableViewCell: PoolishTableViewCell, indexPath: IndexPath, didStartEditing: Bool )
}




class PoolishTableViewCell: UITableViewCell {
    
    @IBOutlet weak var acceptButton              : UIButton!
    @IBOutlet weak var ingredientLabel           : UILabel!
    @IBOutlet weak var invisiblePercentageButton : UIButton!
    @IBOutlet weak var percentageTextField       : UITextField!
    @IBOutlet weak var weightLabel               : UILabel!
    
    
    // MARK: Public Variables
    
    weak var delegate : PoolishTableViewCellDelegate!
    
    
    // MARK: Private Variables
    
    private var inEditMode  = false
    private var myIndexPath : IndexPath!

    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected( false, animated: animated)
    }
    
    
    
    // MARK: Public Initializer Methods
    
    func initializeCellWith( myDelegate : PoolishTableViewCellDelegate,
                             indexPath  : IndexPath,
                             name       : String,
                             percentage : Int16,
                             weight     : Int64 ) {
        
        delegate    = myDelegate
        myIndexPath = indexPath
        
        acceptButton.setImage( UIImage( named: "checkmark" ), for: .normal )
        acceptButton.setTitle( "", for: .normal )

        ingredientLabel    .text        = name
        percentageTextField.text        = String( format: "%d", percentage )
        percentageTextField.borderStyle = .none
        weightLabel        .text        = String( format: "%d", weight )
        
        let isHeaderRow = indexPath.row == 0
        
        backgroundColor                    =  isHeaderRow ? groupedTableViewBackgroundColor : .white
        acceptButton             .isHidden = true
        invisiblePercentageButton.isHidden = !isHeaderRow
        percentageTextField      .isHidden = !isHeaderRow
        weightLabel              .isHidden =  isHeaderRow

//        ingredientLabel.textAlignment = isHeaderRow ? .left : .center
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func acceptButtonTouched(_ sender: Any ) {
        logTrace()
        configureHeaderControls()
        
        delegate.poolishTableViewCell( poolishTableViewCell : self,
                                       indexPath            : myIndexPath,
                                       didSetNew            : percentageTextField?.text ?? "1" )
    }
    
    
    @IBAction func invisiblePercentageButtonTouched(_ sender: Any ) {
        logTrace()
        configureHeaderControls()
        
        delegate.poolishTableViewCell( poolishTableViewCell : self,
                                       indexPath            : myIndexPath,
                                       didStartEditing      : true )
    }

    
    
    // MARK: Utility Methods
    
    private func configureHeaderControls() {
        
        inEditMode = !inEditMode

        acceptButton             .isHidden    = !inEditMode
        invisiblePercentageButton.isHidden    =  inEditMode
        percentageTextField      .borderStyle =  inEditMode ? .roundedRect : .none
        
        if inEditMode {
            percentageTextField.becomeFirstResponder()
        }
        else {
            percentageTextField.resignFirstResponder()
        }
    }

    

}
