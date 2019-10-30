//
//  ProvisioningSummaryViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 10/30/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class ProvisioningSummaryViewController: UIViewController {

    // Public Variables
    
    var myProvision : Provision!        // Set by our parent

    
    @IBOutlet weak var myTableView: UITableView!
    
    
    
    // MARK: Private Variables
    
    private let cellID = "ProvisioningSummaryViewCell"
    
    private struct CellTags {
        static let ingredient = 10
        static let weight     = 11
    }
    
    private var     ingredientArray : [(name: String, weight: Int64)] = []

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        self.navigationItem.title = NSLocalizedString( "Title.ProvisioningSummary", comment: "Summary" )
        
        loadIngredientArray()
    }
    

    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    

    
    // MARK: Utility Methods
    
    private func loadIngredientArray() {
        logTrace()

        let     elementArray  = myProvision.elements?.allObjects as? [ProvisionElement]
        var     ingredientSet = Set<String>()

        
        // First we load up our ingredient names into a Set ... which ensures that we only have unique names
        for element in elementArray ?? [] {
            let breadIngredients = element.recipe?.breadIngredients?.allObjects as! [BreadIngredient]
            let flourIngredients = element.recipe?.flourIngredients?.allObjects as! [BreadIngredient]

            for ingredient in breadIngredients {
                ingredientSet.insert( ingredient.name! )
            }

            for ingredient in flourIngredients {
                ingredientSet.insert( ingredient.name! )
            }

        }
        
        // Next we iterate through the Set values and compute the total weight for each ingredient
        for ingredientName in ingredientSet {
            var     ingredientWeight = Int64( 0 )

            for element in elementArray ?? [] {
                let breadIngredients = element.recipe?.breadIngredients?.allObjects as! [BreadIngredient]
                let flourIngredients = element.recipe?.flourIngredients?.allObjects as! [BreadIngredient]
                
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
                
            }
            
            // Then add it to our array as a (name, weight) tuple
            ingredientArray.append( ( name: ingredientName, weight: ingredientWeight ) )
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
        
        return cell
    }
    
    
}
