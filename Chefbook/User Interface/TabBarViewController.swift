//
//  TabBarViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 8/16/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//


import UIKit



class TabBarViewController: UITabBarController {
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        tabBar.items![0].title = NSLocalizedString( "Title.RecipeList",   comment: "Recipes"      )
        tabBar.items![1].title = NSLocalizedString( "Title.Provisioning", comment: "Provisioning" )
        tabBar.items![2].title = NSLocalizedString( "Title.Settings",     comment: "Settings"     )
        
        let     chefbookCentral = ChefbookCentral.sharedInstance
        
        if !chefbookCentral.didOpenDatabase {
            chefbookCentral.delegate = self
            chefbookCentral.openDatabase()
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
}




// MARK: ChefbookCentralDelegate Methods

extension TabBarViewController : ChefbookCentralDelegate {
    
    func chefbookCentral( chefbookCentral: ChefbookCentral,
                          didOpenDatabase: Bool ) {
        
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        
        if didOpenDatabase {
            chefbookCentral.fetchRecipes()
        }
        else {
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.CannotOpenDatabase", comment: "Fatal Error!  Cannot open database.  Please delete and re-install the app." ) )
        }
        
    }
    
    
    func chefbookCentralDidReloadProvisionArray(chefbookCentral: ChefbookCentral) {
        
        logVerbose( "loaded [ %@ ] provisions", String( chefbookCentral.provisionArray.count ) )
    }
    
    
    func chefbookCentralDidReloadRecipeArray( chefbookCentral: ChefbookCentral ) {
        
        logVerbose( "loaded [ %@ ] recipes", String( chefbookCentral.recipeArray.count ) )
        chefbookCentral.fetchProvisions()
    }
    

}
