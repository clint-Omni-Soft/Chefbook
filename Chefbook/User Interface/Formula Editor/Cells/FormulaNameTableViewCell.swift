//
//  FormulaNameTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 7/31/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol FormulaNameTableViewCellDelegate: class
{
    func formulaNameTableViewCell( formulaNameTableViewCell : FormulaNameTableViewCell,
                                   editedName               : String )
}


class FormulaNameTableViewCell: UITableViewCell
{
    
    @IBOutlet weak var editButton    : UIButton!
    @IBOutlet weak var nameTextField : UITextField!
    
    
    weak var delegate : FormulaNameTableViewCellDelegate!
    
    private var inEditMode = false
    private var recipeName = ""
    
    
    
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
    
    func initializeWith( formulaName : String,
                         delegate    : FormulaNameTableViewCellDelegate )
    {
//        logTrace()
        let isNew = formulaName.isEmpty
        
        
        inEditMode    = isNew
        recipeName    = formulaName
        self.delegate = delegate
        
        nameTextField.borderStyle = isNew ? .roundedRect : .none
        nameTextField.isEnabled   = isNew
        nameTextField.placeholder = isNew ? "Enter Name" : ""
        nameTextField.text        = recipeName

        editButton.setImage( UIImage( named: ( inEditMode ? "checkmark" : "pencil" ) ), for: .normal )
        editButton.setTitle( "", for: .normal )
   }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func editButtonTouched(_ sender: UIButton )
    {
        if inEditMode && ( nameTextField.text?.isEmpty ?? true )
        {
            logTrace( "ERROR:  nameTextField.text?.isEmpty" )
            return
        }
        
//        logTrace()
        inEditMode = !inEditMode

        nameTextField.borderStyle = inEditMode ? .roundedRect : .none
        nameTextField.isEnabled   = inEditMode

        editButton.setImage( UIImage( named: ( inEditMode ? "checkmark" : "pencil" ) ), for: .normal )

        if !inEditMode
        {
            recipeName = nameTextField.text ?? ""

            nameTextField.endEditing( true )
            
            delegate.formulaNameTableViewCell( formulaNameTableViewCell: self, editedName: recipeName )
        }

    }

    
}
