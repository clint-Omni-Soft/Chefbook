//
//  FormulaPreFermentTableViewCell.swift
//  Chefbook
//
//  Created by Clint Shank on 10/7/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol FormulaPreFermentTableViewCellDelegate: AnyObject {
    func formulaPreFermentTableViewCell( formulaPreFermentTableViewCell: FormulaPreFermentTableViewCell, indexPath: IndexPath, editedName: String, editedPercentage: String, editedWeight: String )
    func formulaPreFermentTableViewCell( formulaPreFermentTableViewCell: FormulaPreFermentTableViewCell, indexPath: IndexPath, didStartEditing: Bool )
}



class FormulaPreFermentTableViewCell: UITableViewCell {

    @IBOutlet weak var acceptButton              : UIButton!
    @IBOutlet weak var nameTextField             : UITextField!
    @IBOutlet weak var invisibleWeightButton     : UIButton!
    @IBOutlet weak var percentageTextField       : UITextField!
    @IBOutlet weak var weightTextField           : UITextField!
    
    
    
    // MARK: Public Variables
    
    weak var delegate : FormulaPreFermentTableViewCellDelegate!
    
    
    // MARK: Private Variables
    
    private struct FieldNames {
        static let percentage = 0
        static let name       = 1
        static let weight     = 2
    }
    
    private var inEditMode         = false
    private var myIndexPath        : IndexPath!
    private var fieldWithFocus     = FieldNames.name
    private var preFermentType     = PreFermentTypes.biga
    private var waitingForKeyboard = false

    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
//        logTrace()
        super.awakeFromNib()
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected( false, animated: animated)
    }
    
    
    
    // MARK: Public Initializers
    
    func initializeWithRecipeAt( recipeIndex : Int,
                                 indexPath   : IndexPath,
                                 delegate    : FormulaPreFermentTableViewCellDelegate ) {
//        logTrace()
        self.delegate = delegate
        myIndexPath   = indexPath
        inEditMode    = false
        
        backgroundColor = .white
        
        acceptButton.setImage( UIImage( named: "checkmark" ), for: .normal )
        acceptButton.setTitle( "", for: .normal )
        
        let     recipe = ChefbookCentral.sharedInstance.recipeArray[recipeIndex]
        
        if let preFerment = recipe.preFerment {
            
            nameTextField  .text = preFerment.name
            weightTextField.text = String( format : "%d", preFerment.weight )
            
            preFermentType = Int( preFerment.type )
            
            if preFerment.weight == 0 && !waitingForKeyboard {
                waitingForKeyboard = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                    self.invisibleWeightButtonTouched( self )
                })
                
            }
            
        }
        else if let poolish = recipe.poolish {
            
            nameTextField       .text = NSLocalizedString( "CellTitle.Poolish", comment: "Poolish" )
            percentageTextField .text = String( format : "%d", poolish.percentOfTotal )
            weightTextField     .text = String( format : "%d", poolish.weight         )

            preFermentType = PreFermentTypes.poolish
        }
        
        configureControls()
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func acceptButtonTouched(_ sender: Any) {
//        logTrace()
        inEditMode = !inEditMode
        
        configureControls()
        
        if !inEditMode {
            weightTextField.resignFirstResponder()
            
            delegate.formulaPreFermentTableViewCell( formulaPreFermentTableViewCell : self,
                                                     indexPath                      : myIndexPath,
                                                     editedName                     : nameTextField.text ?? "",
                                                     editedPercentage               : percentageTextField.text ?? "",
                                                     editedWeight                   : weightTextField.text ?? "" )
        }
        
    }
    
    
    @IBAction func invisibleWeightButtonTouched(_ sender: Any) {
//        logTrace()
        inEditMode = !inEditMode
        
        configureControls()

        delegate.formulaPreFermentTableViewCell( formulaPreFermentTableViewCell : self,
                                                 indexPath                      : myIndexPath,
                                                 didStartEditing                : true )
        waitingForKeyboard = false
        weightTextField.becomeFirstResponder()
    }
    
    
    
    // MARK: Utility Methods
    
    private func configureControls() {
//        logVerbose( "inEditMode[ %@ ]", stringFor( inEditMode ) )

        nameTextField.borderStyle = .none
        nameTextField.isEnabled   = false
        nameTextField.textColor   = .black

        if preFermentType == PreFermentTypes.poolish {
            acceptButton         .isHidden = true
            invisibleWeightButton.isHidden = true

            percentageTextField.borderStyle = .none
            percentageTextField.isEnabled   = false
            percentageTextField.isHidden    = false
            percentageTextField.textColor   = .black

            weightTextField.borderStyle = .none
            weightTextField.isEnabled   = false
            weightTextField.textColor   = .black
        }
        else {
            acceptButton         .isHidden = !inEditMode
            invisibleWeightButton.isHidden =  inEditMode
            percentageTextField  .isHidden = true
            
            weightTextField.borderStyle = inEditMode ? .roundedRect : .none
            weightTextField.isEnabled   = inEditMode
            weightTextField.textColor   = inEditMode ? .black : .blue
        }
        
    }
    
    
}
