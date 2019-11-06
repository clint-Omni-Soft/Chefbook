//
//  FormulaYieldTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 9/3/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//


import UIKit


protocol FormulaYieldTableViewCellDelegate: class {
    
    func formulaYieldTableViewCell( formulaYieldTableViewCell: FormulaYieldTableViewCell,
                                    editedQuantity           : String,
                                    editedWeight             : String )
}


class FormulaYieldTableViewCell: UITableViewCell {

    // Public Variables
    
    @IBOutlet weak var editButton               : UIButton!
    @IBOutlet weak var invisibleQuantityButton  : UIButton!
    @IBOutlet weak var invisibleWeightButton    : UIButton!
    @IBOutlet weak var quantityTextField        : UITextField!
    @IBOutlet weak var weightTextField          : UITextField!
    @IBOutlet weak var yieldLabel               : UILabel!
    
    weak var delegate : FormulaYieldTableViewCellDelegate!
    
    // Private Variables
    private var inEditMode       = false
    private var quantityHasFocus = true
    private var yieldQuantity    = ""
    private var yieldWeight      = ""
    

    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
        logTrace()
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool,
                                animated: Bool ) {
        super.setSelected( false, animated: animated )
    }

    
    
    // MARK: Public Initializer
    
    func initializeWith( quantity : Int,
                         weight   : Int,
                         delegate : FormulaYieldTableViewCellDelegate ) {
//        logTrace()
        let     isNew = ( quantity == 0 && weight == 0 )
        
        inEditMode    = isNew
        yieldQuantity = String( format: "%d", quantity )
        yieldWeight   = String( format: "%d", weight   )
        self.delegate = delegate
        
        yieldLabel.text = NSLocalizedString( "LabelText.Yield", comment: "Yield" )
        
        editButton.setImage( UIImage( named: "checkmark" ), for: .normal )
        editButton.setTitle( "", for: .normal )
        
        quantityTextField.placeholder = quantity == 0 ? "#" : ""
        quantityTextField.text        = quantity == 0 ? ""  : yieldQuantity
        
        weightTextField  .placeholder = weight == 0 ? "W" : ""
        weightTextField  .text        = weight == 0 ? ""  : yieldWeight
        
        configureControls()
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func editButtonTouched(_ sender: Any ) {
        
        if inEditMode && ( ( quantityTextField.text?.isEmpty ?? true ) || ( weightTextField.text?.isEmpty ?? true ) ) {
            logTrace( "ERROR:  quantity or weight TextField.text?.isEmpty" )
            return
        }
        
//        logTrace()
        inEditMode = !inEditMode
        
        configureControls()
        
        if !inEditMode {
            yieldQuantity = quantityTextField.text ?? "1"
            yieldWeight   = weightTextField  .text ?? "1"
            
            quantityTextField.resignFirstResponder()
            weightTextField  .resignFirstResponder()
            
            delegate.formulaYieldTableViewCell( formulaYieldTableViewCell : self,
                                                editedQuantity            : yieldQuantity,
                                                editedWeight              : yieldWeight )
        }
        
    }
    
    
    @IBAction func invisibleQuantityButtonTouched(_ sender: Any ) {
        quantityHasFocus = true
        editButtonTouched( self )
   }
    
    
    @IBAction func invisibleWeightButtonTouched(_ sender: Any ) {
        quantityHasFocus = false
        editButtonTouched( self )
    }
    
    
    
    // MARK: Utility Methods
    
    private func configureControls() {
        
        quantityTextField.borderStyle = inEditMode ? .roundedRect : .none
        quantityTextField.isEnabled   = inEditMode
        quantityTextField.textColor   = inEditMode ? .black : .blue

        weightTextField  .borderStyle = inEditMode ? .roundedRect : .none
        weightTextField  .isEnabled   = inEditMode
        weightTextField  .textColor   = inEditMode ? .black : .blue

        editButton              .isHidden = !inEditMode
        invisibleQuantityButton .isHidden =  inEditMode
        invisibleWeightButton   .isHidden =  inEditMode
        
        if inEditMode {
            
            if quantityHasFocus {
                quantityTextField.becomeFirstResponder()
            }
            else {
                weightTextField.becomeFirstResponder()
            }
            
        }
        
    }
    
    
}
