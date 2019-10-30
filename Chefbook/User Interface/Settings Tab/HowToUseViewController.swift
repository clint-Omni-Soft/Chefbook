//
//  HowToUseViewController.swift
//  MyPins
//
//  Created by Clint Shank on 5/2/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



class HowToUseViewController: UIViewController {
    
    @IBOutlet weak var myTextView: UITextView!
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.HowToUse", comment: "How to Use" )
        preferredContentSize = CGSize.init( width: 320, height: 480 )
        
        
        let     contents = NSLocalizedString( "LableText.HowToUse01", comment: "RECIPE LIST\n\nAdd a Recipe - Touching the plus sign (+) button will take you to the Recipe Editor where you can add/modify information about that recipe.  Tapping any of the recipes in the list will load it into the Recipe Editor\n\n\n" ) +
                           NSLocalizedString( "LableText.HowToUse02", comment: "RECIPE EDITOR\n\nProvides the ability to (a) assign it a name, (b) associate an image with the recipe and zoom in on it, (c) specify the yield, (d) provide an ingredients list, " ) +
                           NSLocalizedString( "LableText.HowToUse03", comment: "and (e) describe the steps to produce the end product.  Just touch any of the blue links to add/modify any of the text.\n\nNOTE: If the Recipe Editor is hidden (i.e. - you are ZOOMed into the image), you cannot select a different recipe until you dismiss the overlaying view.\n\n\n" ) +
                           NSLocalizedString( "LableText.HowToUse04", comment: "SETTINGS\n\nTouch any populated row in the table to get information/configuration data about this app.\n\nAbout - Our contact information.\n\nHow to Use - This view.\n\n\n" )

       myTextView.text = contents
    }
    
    
    override func viewDidLayoutSubviews() {
        logTrace()
        super.viewDidLayoutSubviews()
        
        myTextView.setContentOffset( CGPoint.zero, animated: true )
    }
    
    
    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
}
