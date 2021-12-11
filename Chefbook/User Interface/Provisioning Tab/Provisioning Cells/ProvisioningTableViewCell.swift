//
//  ProvisioningTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 10/29/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//


import UIKit



protocol ProvisioningTableViewCellDelegate: AnyObject {
    func provisioningTableViewCell( provisioningTableViewCell: ProvisioningTableViewCell, editedName: String, forRowAt index: Int )
}


class ProvisioningTableViewCell: UITableViewCell {

    // MARK: Public Variables

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var invisibleNameButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    weak var delegate : ProvisioningTableViewCellDelegate!
    
    
    
    // MARK: Private Variables
    
    private var inEditMode    = false
    private var provisionName = ""
    private var rowIndex      = NEW_PROVISION

    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
        logTrace()
        super.awakeFromNib()
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected( false, animated: false)
    }
    
    
    
    // MARK: Public Initializers
    
    func initializeWith( provisionName : String,
                         rowIndex      : Int,
                         delegate      : ProvisioningTableViewCellDelegate ) {

        let     isNew = rowIndex == NEW_PROVISION
        
        inEditMode         = isNew
        self.delegate      = delegate
        self.provisionName = provisionName
        self.rowIndex      = rowIndex

        editButton.setImage( UIImage( named: "checkmark" ), for: .normal )
        editButton.setTitle( "", for: .normal )
        
        nameTextField.placeholder = inEditMode ? "Enter Name" : ""
        nameTextField.text        = provisionName
        
        configureControls()
    }

    
    
    // MARK: Target/Action Methods
    
    @IBAction func editButtonTouched(_ sender: Any) {
        
        if inEditMode && ( nameTextField.text?.isEmpty ?? true ) {
            logTrace( "ERROR:  nameTextField.text?.isEmpty" )
            return
        }
        
//        logTrace()
        inEditMode = !inEditMode
        
        configureControls()
        
        let     editedName = nameTextField.text ?? ""
        
        if !inEditMode && unique( editedName ) {
            provisionName = editedName
            
            delegate.provisioningTableViewCell( provisioningTableViewCell : self,
                                                editedName                : provisionName,
                                                forRowAt                  : rowIndex )
        }
        
    }
    
    
    @IBAction func invisibleNameButtonTouched(_ sender: Any) {
        logTrace()
        editButtonTouched( self )
    }
    
    
    
    // MARK: Utility Methods
    
    private func configureControls() {

        accessoryType = inEditMode ? .none : .disclosureIndicator

        nameTextField.borderStyle = inEditMode ? .roundedRect : .none
        nameTextField.isEnabled   = inEditMode
        nameTextField.textColor   = inEditMode ? .black : .blue
        
        editButton         .isHidden = !inEditMode
        invisibleNameButton.isHidden =  inEditMode

        if inEditMode {
           nameTextField.becomeFirstResponder()
        }
        else {
            nameTextField.resignFirstResponder()
        }
        
    }
    
    
    private func unique(_ provisionName: String ) -> Bool {
        
        let     chefbookCentral   = ChefbookCentral.sharedInstance
        var     numberOfInstances = 0
        
        for provision in chefbookCentral.provisionArray {
            
            if ( provisionName.uppercased() == provision.name?.uppercased() ) {
                
                if rowIndex == NEW_PROVISION {
                    logTrace( "Found a duplicate! [New]." )
                    numberOfInstances += 1
                    break
                }
                else {
                    let     provisionBeingEdited = chefbookCentral.provisionArray[rowIndex]
                    
                    if provision.guid != provisionBeingEdited.guid
                    {
                        logTrace( "Found a duplicate! [Existing]." )
                        numberOfInstances += 1
                        break
                    }
                    
                }
                
            }
            
        }
        
        return ( numberOfInstances == 0 )
    }
    
    
}
