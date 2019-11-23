//
//  ProvisioningSummaryViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 10/30/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class ProvisioningSummaryViewController: UIViewController {

    // MARK: Public Variables
    
    var myProvision : Provision!        // Set by our parent
    var myRecipe    : Recipe!
    var useRecipe   : Bool = false

    
    @IBOutlet weak var myTableView: UITableView!
    
    
    
    // MARK: Private Variables
    
    private let cellID = "ProvisioningSummaryViewCell"
    
    private struct CellTags {
        static let ingredient = 10
        static let weight     = 11
        static let amount     = 12
    }
    
    private var     ingredientArray : [(name: String, weight: Int64, amount: String)] = []

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        self.navigationItem.title = NSLocalizedString( "Title.ProvisioningSummary", comment: "Summary" )
        
        if useRecipe {
            loadIngredientArrayFromRecipe()
        }
        else {
            loadIngredientArrayFromProvision()
        }

    }
    

    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    

    
    // MARK: Utility Methods
    
    private func loadIngredientArrayFromProvision() {
        logTrace()

        let     elementArray  = myProvision.elements?.allObjects as? [ProvisionElement]
        var     ingredientSet = Set<String>()

        
        // First we load up our ingredient names into a Set ... which ensures that we only have unique names
        for element in elementArray ?? [] {
            let breadIngredients    = element.recipe?.breadIngredients?   .allObjects as! [BreadIngredient]
            let flourIngredients    = element.recipe?.flourIngredients?   .allObjects as! [BreadIngredient]
            let standardIngredients = element.recipe?.standardIngredients?.allObjects as! [StandardIngredient]

            for ingredient in breadIngredients {
                ingredientSet.insert( ingredient.name! )
            }

            for ingredient in flourIngredients {
                ingredientSet.insert( ingredient.name! )
            }
            
            for ingredient in standardIngredients {
                ingredientSet.insert( ingredient.name! )
            }

        }
        
        // Next we iterate through the Set values and compute the total weight for each ingredient
        for ingredientName in ingredientSet {
            
            var     amountString     = ""
            var     ingredientWeight = Int64( 0 )

            for element in elementArray ?? [] {
                
                let breadIngredients    = element.recipe?.breadIngredients?   .allObjects as! [BreadIngredient]
                let flourIngredients    = element.recipe?.flourIngredients?   .allObjects as! [BreadIngredient]
                let standardIngredients = element.recipe?.standardIngredients?.allObjects as! [StandardIngredient]

                for ingredient in breadIngredients {
                    
                    if ingredientName == ingredient.name {
                        ingredientWeight += ingredient.weight * Int64( element.quantity )
                    }
                    
                }
                
                for ingredient in flourIngredients {
                    
                    if ingredientName == ingredient.name {
                        ingredientWeight += ingredient.weight * Int64( element.quantity )
                    }
                    
                }
                
                for ingredient in standardIngredients {
                    
                    if ingredientName == ingredient.name {
                        
                        if !amountString.isEmpty {
                            amountString += ", "
                        }
                        
                        amountString += ingredient.amount ?? "<??>"
                    }
                    
                }
                
            }
            
            // Then add it to our array as a (name, weight) tuple
            ingredientArray.append( ( name: ingredientName, weight: ingredientWeight, amount: amountString ) )
        }
        
        // The last thing we do is sort it so it looks nice
        ingredientArray = ingredientArray.sorted( by:
            { (tuple1, tuple2) -> Bool in
                tuple1.name < tuple2.name
            } )

    }

    
    private func loadIngredientArrayFromRecipe() {
        logTrace()
        var     ingredientSet = Set<String>()
        
        
        // First we load up our ingredient names into a Set ... which ensures that we only have unique names
        let     breadIngredients    = myRecipe.breadIngredients?   .allObjects as! [BreadIngredient]
        let     flourIngredients    = myRecipe.flourIngredients?   .allObjects as! [BreadIngredient]
        let     standardIngredients = myRecipe.standardIngredients?.allObjects as! [StandardIngredient]

        for ingredient in breadIngredients {
            ingredientSet.insert( ingredient.name! )
        }
        
        for ingredient in flourIngredients {
            ingredientSet.insert( ingredient.name! )
        }
        
        for ingredient in standardIngredients {
            ingredientSet.insert( ingredient.name! )
        }
        
        // Next we iterate through the Set values and compute the total weight for each ingredient
        for ingredientName in ingredientSet {
            
            var     amountString     = ""
            var     ingredientWeight = Int64( 0 )
            
            for ingredient in breadIngredients {
                
                if ingredientName == ingredient.name {
                    ingredientWeight += ingredient.weight * Int64( 1 )
                }
                
            }
            
            for ingredient in flourIngredients {
                
                if ingredientName == ingredient.name {
                    ingredientWeight += ingredient.weight * Int64( 1 )
                }
                
            }
            
            for ingredient in standardIngredients {
                
                if ingredientName == ingredient.name {
                    
                    if !amountString.isEmpty {
                        amountString += ", "
                    }
                    
                    amountString += ingredient.amount ?? "<???>"
                }
                
            }
            
            // Then add it to our array as a (name, weight) tuple
            ingredientArray.append( ( name: ingredientName, weight: ingredientWeight, amount: amountString ) )
        }
        
        // The last thing we do is sort it so it looks nice
        ingredientArray = ingredientArray.sorted( by:
            { (tuple1, tuple2) -> Bool in
                tuple1.name < tuple2.name
        } )
        
    }

    
}



// MARK: UITableViewDataSource Methods

extension ProvisioningSummaryViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ingredientArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let     cell            = tableView.dequeueReusableCell( withIdentifier: cellID ) ?? UITableViewCell()
        let     amountLabel     = cell.viewWithTag( CellTags.amount     ) as! UILabel
        let     ingredientLabel = cell.viewWithTag( CellTags.ingredient ) as! UILabel
        let     weightLabel     = cell.viewWithTag( CellTags.weight     ) as! UILabel
        let     ingredient      = ingredientArray[indexPath.row]
        var     weightText      = ""
        
        if ingredient.weight > 1000 {
            weightText = String( format: "%.2f kg", Float( ingredient.weight ) / 1000 )
        }
        else {
            weightText = String( format: "%d g", ingredient.weight )
        }
        
        ingredientLabel.text = ingredient.name
        weightLabel    .text = weightText
        amountLabel    .text = ingredient.amount
        
        amountLabel.isHidden = ingredient.amount.isEmpty
        weightLabel.isHidden = ingredient.weight == 0
        
        return cell
    }
    
    
}



extension ProvisioningSummaryViewController: UITableViewDelegate {
    
    func tableView(_ tableView                : UITableView,
                     heightForRowAt indexPath : IndexPath) -> CGFloat {
        
        let     ingredient   = ingredientArray[indexPath.row]
        var     heightOfCell : CGFloat = 44.0
        let     widthOfCell  = myTableView.frame.size.width - 32.0

        if !ingredient.amount.isEmpty {
            heightOfCell += ingredient.amount.heightWithConstrainedWidth( width: widthOfCell, font: .systemFont( ofSize: 14.0 ) )
        }
        
        return heightOfCell
    }
    
    
}

