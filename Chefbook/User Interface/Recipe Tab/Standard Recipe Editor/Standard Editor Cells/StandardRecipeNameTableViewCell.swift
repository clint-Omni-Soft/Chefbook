//
//  StandardRecipeNameTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 7/31/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol StandardRecipeNameTableViewCellDelegate: AnyObject {
    func standardRecipeNameTableViewCell( standardRecipeNameTableViewCell: StandardRecipeNameTableViewCell, editedName: String )
}


class StandardRecipeNameTableViewCell: UITableViewCell {
    
    @IBOutlet weak var editButton          : UIButton!
    @IBOutlet weak var invisibleNameButton : UIButton!
    @IBOutlet weak var nameTextField       : UITextField!
    
    weak var delegate : StandardRecipeNameTableViewCellDelegate!
    
    private var inEditMode = false
    private var recipeName = ""
    
    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
//        logTrace()
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool,
                                animated: Bool ) {
        super.setSelected( false, animated: false )
    }
    
    
    
    // MARK: Public Initializer
    
    func initializeWith( standardRecipeName : String,
                         delegate    : StandardRecipeNameTableViewCellDelegate ) {
//        logTrace()
        let     isNew = standardRecipeName.isEmpty
        
        inEditMode    = isNew
        recipeName    = standardRecipeName
        self.delegate = delegate
        
        editButton.setImage( UIImage( named: "checkmark" ), for: .normal )
        editButton.setTitle( "", for: .normal )
        
        nameTextField.placeholder = inEditMode ? "Enter Name" : ""
        nameTextField.text        = recipeName

        configureControls()
   }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func editButtonTouched(_ sender: Any ) {
        
        if inEditMode && ( nameTextField.text?.isEmpty ?? true ) {
            logTrace( "ERROR:  nameTextField.text?.isEmpty" )
            return
        }
        
//        logTrace()
        inEditMode = !inEditMode

        configureControls()
        
        if !inEditMode {
            recipeName = nameTextField.text ?? ""

            nameTextField.resignFirstResponder()
            
            delegate.standardRecipeNameTableViewCell( standardRecipeNameTableViewCell : self,
                                                      editedName                      : recipeName )
        }

    }

    
    @IBAction func invisibleNameButtonTouched(_ sender: Any ) {
        editButtonTouched( self )
    }
    
    
    
    // MARK: Utility Methods
    
    private func configureControls() {
        
        nameTextField.borderStyle = inEditMode ? .roundedRect : .none
        nameTextField.isEnabled   = inEditMode
        nameTextField.textColor   = inEditMode ? .black : .blue
        
        editButton         .isHidden = !inEditMode
        invisibleNameButton.isHidden =  inEditMode
        
        if inEditMode {
            nameTextField.becomeFirstResponder()
        }

    }



}
