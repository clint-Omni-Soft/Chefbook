//
//  PoolishEditorViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 10/8/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


class PoolishEditorViewController: UIViewController {

    
    // MARK: Public Variables
    
    var     recipe : Recipe!    // Set by our parent
    
    
    // MARK: Private Variables
    
    @IBOutlet weak var cancelButton             : UIButton!
    @IBOutlet weak var editorTitle              : UILabel!
    @IBOutlet weak var percentOfFlourLabel      : UILabel!
    @IBOutlet weak var percentOfFlourTextField  : UITextField!
    @IBOutlet weak var percentOfTotalLabel      : UILabel!
    @IBOutlet weak var percentOfTotalTextField  : UITextField!
    @IBOutlet weak var percentOfWaterLabel      : UILabel!
    @IBOutlet weak var percentOfWaterTextField  : UITextField!
    @IBOutlet weak var percentOfYeistLabel      : UILabel!
    @IBOutlet weak var percentOfYeistTextField  : UITextField!
    @IBOutlet weak var saveButton               : UIButton!
    
    
    private struct PoolishDefaultPercentages {
        static let flour = "48"
        static let total = "30"
        static let water = "48"
        static let yeist = "4"
    }
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 290.0, height: 280.0 )
        
        editorTitle        .text = NSLocalizedString( "Title.PoolishEditor",      comment: "Poolish Editor"   )
        percentOfFlourLabel.text = NSLocalizedString( "LabelText.PercentOfFlour", comment: "Percent of Flour" )
        percentOfTotalLabel.text = NSLocalizedString( "LabelText.PercentOfTotal", comment: "Percent of Total" )
        percentOfWaterLabel.text = NSLocalizedString( "LabelText.PercentOfWater", comment: "Percent of Water" )
        percentOfYeistLabel.text = NSLocalizedString( "LabelText.PercentOfYeist", comment: "Percent of Yeist" )

        cancelButton.setTitle( NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), for: .normal )
        saveButton  .setTitle( NSLocalizedString( "ButtonTitle.Save",   comment: "Save"   ), for: .normal )
    }
    
    
    override func viewWillAppear(_ animated: Bool ) {
        logTrace()
        super.viewWillAppear( animated )
        
        loadTextFields()
    }
    
    
    override func didReceiveMemoryWarning() {
        logTrace()
        super.didReceiveMemoryWarning()
    }
    

    
    // MARK: Target/Action Methods
    
    @IBAction func cancelButtonTouched(_ sender: Any) {
        logTrace()
        dismiss( animated: true, completion: nil )
    }
    
    @IBAction func saveButtonTouched(_ sender: Any) {
        logTrace()
        saveData()
        dismiss( animated: true, completion: nil )
    }
    
    
    
    // MARK: Utility Methods
    
    private func loadTextFields() {
        logTrace()
        
        if let poolish = recipe.poolish {
            percentOfFlourTextField.text = String( format: "%d", poolish.percentOfFlour )
            percentOfTotalTextField.text = String( format: "%d", poolish.percentOfTotal )
            percentOfWaterTextField.text = String( format: "%d", poolish.percentOfWater )
            percentOfYeistTextField.text = String( format: "%d", poolish.percentOfYeist )
        }
        else {
            percentOfFlourTextField.text = PoolishDefaultPercentages.flour
            percentOfTotalTextField.text = PoolishDefaultPercentages.total
            percentOfWaterTextField.text = PoolishDefaultPercentages.water
            percentOfYeistTextField.text = PoolishDefaultPercentages.yeist
        }
        
    }

    
    private func saveData() {
        logTrace()

        let     chefbookCentral = ChefbookCentral.sharedInstance
        
        let     flour = Int16( percentOfFlourTextField?.text ?? PoolishDefaultPercentages.flour )!
        let     total = Int16( percentOfTotalTextField?.text ?? PoolishDefaultPercentages.total )!
        let     water = Int16( percentOfWaterTextField?.text ?? PoolishDefaultPercentages.water )!
        let     yeist = Int16( percentOfYeistTextField?.text ?? PoolishDefaultPercentages.yeist )!
        
        if let poolish = recipe.poolish {
            poolish.percentOfFlour = flour
            poolish.percentOfTotal = total
            poolish.percentOfWater = water
            poolish.percentOfYeist = yeist
            poolish.weight         = Int64( ( Float( recipe.formulaYieldWeight ) * Float( recipe.formulaYieldQuantity ) ) * ( Float( total ) / 100.0 ) )
            
            chefbookCentral.saveUpdatedRecipe( recipe: recipe )
        }
        else {
            chefbookCentral.addPoolishToFormulaRecipe( recipe         : recipe,
                                                       percentOfTotal : total,
                                                       percentOfFlour : flour,
                                                       percentOfWater : water,
                                                       percentOfYeist : yeist )
        }

    }

}
