//
//  FormulaYieldTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 9/3/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//


import UIKit


protocol FormulaYieldTableViewCellDelegate: class
{
    func formulaYieldTableViewCell( formulaYieldTableViewCell: FormulaYieldTableViewCell,
                                    editedQuantity           : String,
                                    editedWeight             : String )
}


class FormulaYieldTableViewCell: UITableViewCell
{

    @IBOutlet weak var editButton        : UIButton!
    @IBOutlet weak var quantityTextField : UITextField!
    @IBOutlet weak var weightTextField   : UITextField!
    @IBOutlet weak var yieldLabel        : UILabel!
    
    
    var delegate : FormulaYieldTableViewCellDelegate!
    
    private var inEditMode    = false
    private var yieldQuantity = ""
    private var yieldWeight   = ""
    

    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool,
                                animated: Bool )
    {
        super.setSelected( false, animated: animated )
    }

    
    
    // MARK: Public Initializer
    
    func initializeWith( quantity : Int,
                         weight   : Int,
                         delegate : FormulaYieldTableViewCellDelegate )
    {
        logTrace()
        let     isNew = ( quantity == 0 && weight == 0 )
        
        
        inEditMode    = isNew
        yieldQuantity = String( format: "%d", quantity )
        yieldWeight   = String( format: "%d", weight   )
        self.delegate = delegate
        
        yieldLabel.text = NSLocalizedString( "LabelText.Yield", comment: "Yield" )
        
        quantityTextField.borderStyle = isNew ? .roundedRect : .none
        quantityTextField.isEnabled   = isNew
        quantityTextField.placeholder = quantity == 0 ? "#" : ""
        quantityTextField.text        = quantity == 0 ? ""  : yieldQuantity
        
        weightTextField  .borderStyle = isNew ? .roundedRect : .none
        weightTextField  .isEnabled   = isNew
        weightTextField  .placeholder = weight == 0 ? "W" : ""
        weightTextField  .text        = weight == 0 ? ""  : yieldWeight
        
        editButton.setImage( UIImage( named: ( inEditMode ? "checkmark" : "pencil" ) ), for: .normal )
        editButton.setTitle( "", for: .normal )
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func editButtonTouched(_ sender: Any )
    {
        if inEditMode && ( ( quantityTextField.text?.isEmpty ?? true ) || ( weightTextField.text?.isEmpty ?? true ) )
        {
            logTrace( "ERROR:  quantity or weight TextField.text?.isEmpty" )
            return
        }
        
        logTrace()
        inEditMode = !inEditMode
        
        quantityTextField.borderStyle = inEditMode ? .roundedRect : .none
        quantityTextField.isEnabled   = inEditMode
        
        weightTextField  .borderStyle = inEditMode ? .roundedRect : .none
        weightTextField  .isEnabled   = inEditMode
        
        editButton.setImage( UIImage( named: ( inEditMode ? "checkmark" : "pencil" ) ), for: .normal )
        
        if !inEditMode
        {
            yieldQuantity = quantityTextField.text ?? "1"
            yieldWeight   = weightTextField  .text ?? "1"
            
            quantityTextField.endEditing( true )
            weightTextField  .endEditing( true )
            
            delegate.formulaYieldTableViewCell( formulaYieldTableViewCell : self,
                                                editedQuantity            : yieldQuantity,
                                                editedWeight              : yieldWeight )
        }
        
    }
    
    
}
