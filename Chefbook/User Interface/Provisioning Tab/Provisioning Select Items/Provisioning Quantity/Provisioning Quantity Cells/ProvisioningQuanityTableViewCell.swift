//
//  ProvisioningQuanityTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 10/28/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//


import UIKit

protocol ProvisioningQuanityTableViewCellDelegate: class {
    
    func provisioningQuanityTableViewCell( provisioningQuanityTableViewCell : ProvisioningQuanityTableViewCell,
                                           elementIndex                     : Int,
                                           didSetNew quantity               : String )
    
    func provisioningQuanityTableViewCell( provisioningQuanityTableViewCell : ProvisioningQuanityTableViewCell,
                                           elementIndex                     : Int,
                                           didStartEditing                  : Bool )
}




class ProvisioningQuanityTableViewCell: UITableViewCell {
    
    @IBOutlet weak var quantityTextField        : UITextField!
    @IBOutlet weak var invisibleQuantityButton  : UIButton!
    @IBOutlet weak var titleLabel               : UILabel!
    @IBOutlet weak var detailLabel              : UILabel!
    @IBOutlet weak var acceptButton             : UIButton!
    

    
    // MARK: Public Variables
    
    weak var delegate : ProvisioningQuanityTableViewCellDelegate!
    
    
    // MARK: Private Variables
    
    private var elementIndex : Int!
    private var inEditMode   = false
    
    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
        logTrace()
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(  false, animated: animated )
    }
    
    
    
    // MARK: Public Initializer Methods
    
    func initializeWith( element      : ProvisionElement,
                         elementIndex : Int,
                         delegate     : ProvisioningQuanityTableViewCellDelegate ) {
        
        self.delegate     = delegate
        self.elementIndex = elementIndex
        
        acceptButton.setImage( UIImage( named: "checkmark" ), for: .normal )
        acceptButton.setTitle( "", for: .normal )

        titleLabel .text =  element.recipe?.name ?? "Unknown"
        detailLabel.text = (element.recipe?.isFormulaType)! ? String( format: NSLocalizedString( "LabelText.ProvisioningFormulaFormat",    comment: "Quantity: %d   Item Weight: %d" ), element.recipe?.formulaYieldQuantity ?? 1, element.recipe?.formulaYieldWeight ?? 10 ) :
                                                              String( format: NSLocalizedString( "LabelText.ProvisioningNonFormulaFormat", comment: "Quantity: %@   Options: %@"     ), element.recipe?.yield ?? "Unknown",   element.recipe?.yieldOptions ?? "Unknown")
        quantityTextField.text        = String( format: "%d", element.quantity )
        quantityTextField.borderStyle = .none

        acceptButton.isHidden = true
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func acceptButtonTouched(_ sender: Any ) {
        logTrace()
        configureControls()
        
        delegate.provisioningQuanityTableViewCell( provisioningQuanityTableViewCell : self,
                                                   elementIndex                     : elementIndex,
                                                   didSetNew                        : quantityTextField?.text ?? "1" )
    }
    
    
    @IBAction func invisibleQuantityButtonTouched(_ sender: Any ) {
        logTrace()
        configureControls()
        
        delegate.provisioningQuanityTableViewCell( provisioningQuanityTableViewCell : self,
                                                   elementIndex                     : elementIndex,
                                                   didStartEditing                  : true )
    }
    
    

    // MARK: Utility Methods
    
    private func configureControls() {
        
        inEditMode = !inEditMode
        
        acceptButton           .isHidden    = !inEditMode
        invisibleQuantityButton.isHidden    =  inEditMode
        quantityTextField      .borderStyle =  inEditMode ? .roundedRect : .none
        
        if inEditMode {
            quantityTextField.becomeFirstResponder()
        }
        else {
            quantityTextField.resignFirstResponder()
        }
        
    }
    
    
}
