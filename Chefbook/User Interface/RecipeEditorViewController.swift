//
//  RecipeEditorViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 7/26/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol RecipeEditorViewControllerDelegate: class
{
    func recipeEditorViewController( recipeEditorViewController : RecipeEditorViewController,
                                     didEditRecipe: Bool )
}



class RecipeEditorViewController: UIViewController
{

    // MARK: Public Variables
    weak var delegate: RecipeEditorViewControllerDelegate?
    
    var     indexOfItemBeingEdited:     Int!                        // Set by delegate
    var     launchedFromDetailView    = false                       // Set by delegate


    override func viewDidLoad()
    {
        super.viewDidLoad()
        logTrace()

        title = NSLocalizedString( "Title.RecipeEditor", comment: "Recipe Editor" )
    }
    


}
