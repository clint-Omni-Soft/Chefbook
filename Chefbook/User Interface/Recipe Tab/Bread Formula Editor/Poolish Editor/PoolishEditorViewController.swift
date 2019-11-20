//
//  PoolishEditorViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 10/8/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


class PoolishEditorViewController: UIViewController
{
    // MARK: Public Variables
    
    var     recipe : Recipe!    // Set by our parent
    
    
    // MARK: Private Variables
    
    @IBOutlet weak var editorTitle              : UILabel!
    
    @IBOutlet weak var weightLabel              : UILabel!
    
    @IBOutlet weak var invisiblePercentageButton: UIButton!
    @IBOutlet weak var percentOfTotalTextField  : UITextField!
    @IBOutlet weak var percentOfTotalLabel      : UILabel!
    @IBOutlet weak var totalWeightOfPoolishLabel: UILabel!
    @IBOutlet weak var acceptButton             : UIButton!
    
    @IBOutlet weak var percentTitleLabel        : UILabel!
    @IBOutlet weak var poolishFormulaTitleLabel : UILabel!
    
    @IBOutlet weak var myTableView              : UITableView!
    
    @IBOutlet weak var cancelButton             : UIButton!
    @IBOutlet weak var saveButton               : UIButton!
    
    
    private struct PoolishDefaultPercentages {
        static let flour = "48"
        static let total = "30"
        static let water = "48"
        static let yeast = "4"
    }
    
    private let cellIdentifier = "poolishTableViewCell"
    
    private var     currentlyActiveTextField  : UITextField!
    private var     flourIngredients          = [BreadIngredient]()
    private var     percentOfFlourText        = PoolishDefaultPercentages.flour
    private var     percentOfTotalText        = PoolishDefaultPercentages.total
    private var     percentOfWaterText        = PoolishDefaultPercentages.water
    private var     percentOfYeastText        = PoolishDefaultPercentages.yeast
    private var     totalPoolishWeight        = Float( 0.0 )
    private var     totalYieldWeight          = Float( 100.0 )
    private var     waterIngredients          = [BreadIngredient]()
    private var     weightOfPoolishFlour      = Int64( 0 )
    private var     weightOfPoolishWater      = Int64( 0 )
    private var     weightOfPoolishYeast      = Int64( 0 )
    private var     weightOfRecipeFlour       = Int64( 0 )
    private var     weightOfRecipeWater       = Int64( 0 )
    private var     weightOfRecipeYeast       = Int64( 0 )
    private var     yeastIngredients          = [BreadIngredient]()

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        preferredContentSize = CGSize( width: 320.0, height: 440.0 )
        
        editorTitle             .text = NSLocalizedString( "Title.PoolishEditor",        comment: "Poolish Editor"   )
        weightLabel             .text = String( format: " %@ g", NSLocalizedString( "LabelText.Weight", comment: "Weight" ) )
        percentOfTotalLabel     .text = NSLocalizedString( "LabelText.PercentOfTotal",   comment: "Percent of Total" )
        poolishFormulaTitleLabel.text = NSLocalizedString( "Title.PoolishFormula",       comment: "Poolish Formula"  )

        cancelButton.setTitle( NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), for: .normal )
        saveButton  .setTitle( NSLocalizedString( "ButtonTitle.Save",   comment: "Save"   ), for: .normal )
        
        acceptButton.setImage( UIImage( named: "checkmark" ), for: .normal )
        acceptButton.setTitle( "", for: .normal )
        
        initializeIngredientData()
        computeSectionWeights()
    }
    
    
    override func viewWillAppear(_ animated: Bool ) {
        logTrace()
        super.viewWillAppear( animated )
        
        percentOfTotalTextField.text = percentOfTotalText

        configurePercentOfTotalTextField( inEditMode: false )
        
        myTableView.reloadData()
   }
    
    
    override func didReceiveMemoryWarning() {
        logTrace()
        super.didReceiveMemoryWarning()
    }
    

    
    // MARK: Target/Action Methods
    
    @IBAction func acceptButtonTouched(_ sender: Any) {
        logTrace()
        configurePercentOfTotalTextField( inEditMode: false )

        percentOfTotalText = percentOfTotalTextField.text ?? "10"
        
        computeSectionWeights()
        myTableView.reloadData()
    }
    
    
    @IBAction func cancelButtonTouched(_ sender: Any) {
        logTrace()
        dismiss( animated: true, completion: nil )
    }
    
    
    @IBAction func invisiblePercentageButtonTouched(_ sender: Any) {
        logTrace()
        configurePercentOfTotalTextField( inEditMode: true )
   }
    
    
    @IBAction func saveButtonTouched(_ sender: Any) {
        logTrace()
        let  total = Int( percentOfFlourText )! + Int( percentOfWaterText )! + Int( percentOfYeastText )!
        
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
    
    private func computeSectionWeights() {
        
        totalPoolishWeight   =        round( Float( totalYieldWeight   ) * ( ( Float( percentOfTotalText )! / 100.0 ) ) )
        weightOfPoolishFlour = Int64( round( Float( totalPoolishWeight ) * ( ( Float( percentOfFlourText )! / 100.0 ) ) ) )
        weightOfPoolishWater = Int64( round( Float( totalPoolishWeight ) * ( ( Float( percentOfWaterText )! / 100.0 ) ) ) )
        weightOfPoolishYeast = Int64( round( Float( totalPoolishWeight ) * ( ( Float( percentOfYeastText )! / 100.0 ) ) ) )
        
        totalWeightOfPoolishLabel.text = String( format: "%d", Int( totalPoolishWeight ) )
        logVerbose( "f[ %d ] w[ %d ] y[ %d ]", weightOfPoolishFlour, weightOfPoolishWater, weightOfPoolishYeast )
    }
    
    
    private func configure(_ cell         : PoolishTableViewCell,
                             at indexPath : IndexPath ) {
        
        let     ingredient : BreadIngredient!
        var     name       = "Unknown"
        var     weight     = Int64( 0 )
        var     percentage : Int16 = 0

        switch indexPath.section {
            
        case 0:
            if indexPath.row != 0 {
                ingredient = flourIngredients[indexPath.row - 1] as BreadIngredient
                
                name   = ingredient.name ?? "Unknown"
                weight = Int64( Float( weightOfPoolishFlour ) * ( Float( ingredient.weight ) / Float( weightOfRecipeFlour ) ) )
            }
            else {
                name   = NSLocalizedString( "PoolishComponent.Flour", comment: "Flour Components" )
                weight = weightOfPoolishFlour
            }
            
            percentage = Int16( percentOfFlourText ) ?? 1
            
        case 1:
            if indexPath.row != 0 {
                ingredient = waterIngredients[indexPath.row - 1]
                
                name   = ingredient.name ?? "Unknown"
                weight = Int64( Float( weightOfPoolishWater ) * ( Float( ingredient.weight ) / Float( weightOfRecipeWater ) ) )
            }
            else {
                name   = NSLocalizedString( "PoolishComponent.Water", comment: "Water Components" )
                weight = weightOfPoolishWater
            }
            
            percentage = Int16( percentOfWaterText ) ?? 1

        default:
            if indexPath.row != 0 {
                ingredient = yeastIngredients[indexPath.row - 1]
                
                name   = ingredient.name ?? "Unknown"
                weight = Int64( Float( weightOfPoolishYeast ) * ( Float( ingredient.weight ) / Float( weightOfRecipeYeast ) ) )
            }
            else {
                name   = NSLocalizedString( "PoolishComponent.Yeast", comment: "Yeast Components" )
                weight = weightOfPoolishYeast
            }
            
            percentage = Int16( percentOfYeastText ) ?? 1
        }
        
        cell.initializeCellWith( myDelegate : self,
                                 indexPath  : indexPath,
                                 name       : name,
                                 percentage : percentage,
                                 weight     : weight )
    }
    
    
    private func configurePercentOfTotalTextField( inEditMode : Bool ) {
        logVerbose( "[ %@ ]", stringFor( inEditMode ) )

        percentOfTotalTextField.backgroundColor = inEditMode ? .white : groupedTableViewBackgroundColor
        percentOfTotalTextField.borderStyle     = inEditMode ? .roundedRect : .none
        
        invisiblePercentageButton.isEnabled = !inEditMode
        percentOfTotalTextField  .isEnabled =  inEditMode

        acceptButton             .isHidden  = !inEditMode
        invisiblePercentageButton.isHidden  =  inEditMode
        totalWeightOfPoolishLabel.isHidden  =  inEditMode
        
        if inEditMode {
            percentOfTotalTextField.becomeFirstResponder()
        }
        else {
            percentOfTotalTextField.resignFirstResponder()
        }
        
    }
    
    
    private func initializeIngredientData() {
        logTrace()
        
        if let flourIngredientsArrary = recipe.flourIngredients?.allObjects as? [BreadIngredient] {
            flourIngredients = flourIngredientsArrary

            for flourIngredient in flourIngredients {
                weightOfRecipeFlour = weightOfRecipeFlour + flourIngredient.weight
            }
            
        }
        
        if let ingredientArray = recipe.breadIngredients?.allObjects as? [BreadIngredient] {
            
            for ingredient in ingredientArray {
                
                if ingredient.ingredientType == BreadIngredientTypes.water {
                    waterIngredients.append( ingredient )
                    weightOfRecipeWater = weightOfRecipeWater + ingredient.weight
               }
                else if ingredient.ingredientType == BreadIngredientTypes.yeast {
                    yeastIngredients.append(ingredient)
                    weightOfRecipeYeast = weightOfRecipeYeast + ingredient.weight
               }
                
            }

        }

        if let poolish = recipe.poolish {
            percentOfTotalText = String( format: "%d", poolish.percentOfTotal )
            
            percentOfFlourText = String( format: "%d", poolish.percentOfFlour )
            percentOfWaterText = String( format: "%d", poolish.percentOfWater )
            percentOfYeastText = String( format: "%d", poolish.percentOfYeast )
        }
        
        totalYieldWeight = Float( recipe.formulaYieldQuantity ) * Float( recipe.formulaYieldWeight )
    }

    
    private func saveData() {
        logTrace()

        let     chefbookCentral = ChefbookCentral.sharedInstance

        let     flour = Int16( percentOfFlourText ) ?? 1
        let     total = Int16( percentOfTotalText ) ?? 1
        let     water = Int16( percentOfWaterText ) ?? 1
        let     yeast = Int16( percentOfYeastText ) ?? 1
        
        if let poolish = recipe.poolish {
            poolish.percentOfFlour = flour
            poolish.percentOfTotal = total
            poolish.percentOfWater = water
            poolish.percentOfYeast = yeast
            poolish.weight         = Int64( ( Float( recipe.formulaYieldWeight ) * Float( recipe.formulaYieldQuantity ) ) * ( Float( total ) / 100.0 ) )

            chefbookCentral.saveUpdated( recipe )
        }
        else {
            chefbookCentral.addPoolishToFormulaRecipe( recipe         : recipe,
                                                       percentOfTotal : total,
                                                       percentOfFlour : flour,
                                                       percentOfWater : water,
                                                       percentOfYeast : yeast )
        }

    }

}



// MARK: PoolishTableViewCellDelegate Methods

extension PoolishEditorViewController : PoolishTableViewCellDelegate {
    
    func poolishTableViewCell( poolishTableViewCell : PoolishTableViewCell,
                               indexPath            : IndexPath,
                               didSetNew percentage : String ) {
        logVerbose( "IndexPath[ %d ][ %d ] ... [ %@ ]", indexPath.section, indexPath.row, percentage )
        
        switch indexPath.section {
        case 0:     percentOfFlourText = percentage
        case 1:     percentOfWaterText = percentage
        default:    percentOfYeastText = percentage
        }
        
        computeSectionWeights()
        myTableView.reloadData()
    }
    
    
    func poolishTableViewCell( poolishTableViewCell : PoolishTableViewCell,
                               indexPath            : IndexPath,
                               didStartEditing      : Bool ) {
        logTrace()
    }
    
}



// MARK: UITableViewDataSource Methods

extension PoolishEditorViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView ) -> Int {
        return 3
    }
    
    
    func tableView(_ tableView                     : UITableView,
                     numberOfRowsInSection section : Int ) -> Int {
        var     numberOfRows = 0
        
        
        switch section {
        case 0:     numberOfRows = flourIngredients.count
        case 1:     numberOfRows = waterIngredients.count
        default:    numberOfRows = yeastIngredients.count
        }
        
        return numberOfRows + 1 // Adding row for Header
    }
    
    
    func tableView(_ tableView              : UITableView,
                     cellForRowAt indexPath : IndexPath ) -> UITableViewCell {
        
        let     cell = tableView.dequeueReusableCell( withIdentifier: cellIdentifier ) as! PoolishTableViewCell
        
        configure( cell, at : indexPath )
        
        return cell
        
    }
    
    
}


