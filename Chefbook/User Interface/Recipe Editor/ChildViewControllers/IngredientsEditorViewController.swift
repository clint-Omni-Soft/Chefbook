//
//  IngredientsEditorViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 7/31/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol IngredientsEditorViewControllerDelegate: class
{
    func ingredientsEditorViewController( ingredientsEditorViewController : IngredientsEditorViewController,
                                          didEditIngredients: Bool )
}



class IngredientsEditorViewController: UIViewController
{
    @IBOutlet weak var myTextView: UITextView!
    
    
    
    weak var delegate : IngredientsEditorViewControllerDelegate?
    
    var ingredients : String!   // Set by our delegate and, if modified by the user, updated by us
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        logTrace()
        super.viewDidLoad()
        
        title = NSLocalizedString( "Title.Ingredients", comment: "Ingredients" )
    }
    

    override func viewWillAppear(_ animated: Bool)
    {
        logTrace()
        super.viewWillAppear( animated )
        
        myTextView.text = ingredients
    }

    
    override func viewWillDisappear(_ animated: Bool)
    {
        logTrace()
        super.viewWillAppear( animated )
        
        if myTextView.text != ingredients
        {
            ingredients = myTextView.text
            delegate?.ingredientsEditorViewController( ingredientsEditorViewController: self,
                                                       didEditIngredients: true )
        }
        
    }
    
}
