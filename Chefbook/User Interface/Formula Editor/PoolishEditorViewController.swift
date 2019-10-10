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
    
    @IBOutlet weak var editorTitle              : UILabel!
    
    @IBOutlet weak var percentOfTotalTextField  : UITextField!
    @IBOutlet weak var percentOfTotalLabel      : UILabel!
    @IBOutlet weak var totalWeightOfPoolishLabel: UILabel!
    
    @IBOutlet weak var percentTitleLabel        : UILabel!
    @IBOutlet weak var poolishFormulaTitleLabel : UILabel!
    
    @IBOutlet weak var percentOfFlourTextField  : UITextField!
    @IBOutlet weak var percentOfFlourLabel      : UILabel!
    @IBOutlet weak var weightOfFlourLabel       : UILabel!
    
    @IBOutlet weak var percentOfWaterTextField  : UITextField!
    @IBOutlet weak var percentOfWaterLabel      : UILabel!
    @IBOutlet weak var weightOfWaterLabel       : UILabel!
    
    @IBOutlet weak var percentOfYeistTextField  : UITextField!
    @IBOutlet weak var percentOfYeistLabel      : UILabel!
    @IBOutlet weak var weightOfYeistLabel       : UILabel!
    
    @IBOutlet weak var cancelButton             : UIButton!
    @IBOutlet weak var saveButton               : UIButton!
    
    
    private struct PoolishDefaultPercentages {
        static let flour = "48"
        static let total = "30"
        static let water = "48"
        static let yeist = "4"
    }
    
    var     currentlyActiveTextField  : UITextField!
    var     percentOfFlourText        = PoolishDefaultPercentages.flour
    var     percentOfTotalText        = PoolishDefaultPercentages.total
    var     percentOfWaterText        = PoolishDefaultPercentages.water
    var     percentOfYeistText        = PoolishDefaultPercentages.yeist
    var     totalYieldWeight          : Float = 100.0

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        preferredContentSize = CGSize(width: 300.0, height: 320.0 )
        
        editorTitle        .text = NSLocalizedString( "Title.PoolishEditor",        comment: "Poolish Editor"   )
        percentOfTotalLabel.text = NSLocalizedString( "LabelText.PercentOfTotal",   comment: "Percent of Total" )
        percentOfTotalLabel.text = NSLocalizedString( "Title.PoolishFormula",       comment: "Poolish Formula"  )
        percentOfFlourLabel.text = NSLocalizedString( "IngredientType.Flour",       comment: "Flour" )
        percentOfWaterLabel.text = NSLocalizedString( "IngredientType.Water",       comment: "Water" )
        percentOfYeistLabel.text = NSLocalizedString( "IngredientType.Yeist",       comment: "Yeist" )

        cancelButton.setTitle( NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), for: .normal )
        saveButton  .setTitle( NSLocalizedString( "ButtonTitle.Save",   comment: "Save"   ), for: .normal )
    }
    
    
    override func viewWillAppear(_ animated: Bool ) {
        logTrace()
        super.viewWillAppear( animated )
        
        populateControlsWithData()
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
    
    
    @IBAction func endEditingRequested(_ sender: Any) {
        logTrace()
        currentlyActiveTextField.resignFirstResponder()
        populateWeightLabels()
    }
    
    
    @IBAction func textFieldDidBeginEditing(_ sender: UITextField) {
        logTrace()
        currentlyActiveTextField = sender
    }
    
    
    @IBAction func saveButtonTouched(_ sender: Any) {
        logTrace()
        percentOfFlourText = percentOfFlourTextField.text ?? PoolishDefaultPercentages.flour
        percentOfWaterText = percentOfWaterTextField.text ?? PoolishDefaultPercentages.water
        percentOfYeistText = percentOfYeistTextField.text ?? PoolishDefaultPercentages.yeist
        
        let  total = Int( percentOfFlourText )! + Int( percentOfWaterText )! + Int( percentOfYeistText )!
        
        if  100 == total {
            saveData()
            dismiss( animated: true, completion: nil )
        }
        else {
            logTrace( "ERROR:  The poolish formula percentages do NOT sum to 100!" )
            presentAlert( title   : NSLocalizedString( "AlertTitle.Error",                  comment: "Error!" ),
                          message : NSLocalizedString( "AlertMessage.PercentagesDontAddUp", comment: "The poolish formula percentages do NOT sum to 100!  Please adjust and try again." ) )
        }

    }
    
    
    
    // MARK: Utility Methods
    
    private func populateControlsWithData() {
        logTrace()

        if let poolish = recipe.poolish {
            percentOfTotalTextField.text = String( format: "%d", poolish.percentOfTotal )

            percentOfFlourTextField.text = String( format: "%d", poolish.percentOfFlour )
            percentOfWaterTextField.text = String( format: "%d", poolish.percentOfWater )
            percentOfYeistTextField.text = String( format: "%d", poolish.percentOfYeist )
        }
        else {
            percentOfTotalTextField.text = PoolishDefaultPercentages.total

            percentOfFlourTextField.text = PoolishDefaultPercentages.flour
            percentOfWaterTextField.text = PoolishDefaultPercentages.water
            percentOfYeistTextField.text = PoolishDefaultPercentages.yeist
        }
        
        totalYieldWeight = Float( recipe.formulaYieldQuantity ) * Float( recipe.formulaYieldWeight )
        
        populateWeightLabels()
    }

    
    private func populateWeightLabels() {
        
        percentOfTotalText = percentOfTotalTextField.text ?? PoolishDefaultPercentages.total
        
        percentOfFlourText = percentOfFlourTextField.text ?? PoolishDefaultPercentages.flour
        percentOfWaterText = percentOfWaterTextField.text ?? PoolishDefaultPercentages.water
        percentOfYeistText = percentOfYeistTextField.text ?? PoolishDefaultPercentages.yeist
        
        let     totalPoolishWeight =      round( totalYieldWeight   * ( ( Float( percentOfTotalText )! / 100.0 ) ) )
        let     weightOfFlour      = Int( round( totalPoolishWeight * ( ( Float( percentOfFlourText )! / 100.0 ) ) ) )
        let     weightOfWater      = Int( round( totalPoolishWeight * ( ( Float( percentOfWaterText )! / 100.0 ) ) ) )
        let     weightOfYeist      = Int( round( totalPoolishWeight * ( ( Float( percentOfYeistText )! / 100.0 ) ) ) )
        
        totalWeightOfPoolishLabel.text = String( format: "%d", Int( totalPoolishWeight ) )
        
        weightOfFlourLabel.text = String( format: "%d", weightOfFlour )
        weightOfWaterLabel.text = String( format: "%d", weightOfWater )
        weightOfYeistLabel.text = String( format: "%d", weightOfYeist )
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
