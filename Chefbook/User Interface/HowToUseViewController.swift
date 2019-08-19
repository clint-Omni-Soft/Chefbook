//
//  HowToUseViewController.swift
//  MyPins
//
//  Created by Clint Shank on 5/2/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



class HowToUseViewController: UIViewController
{
    @IBOutlet weak var myTextView: UITextView!
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.HowToUse", comment: "How to Use" )
        preferredContentSize = CGSize.init( width: 320, height: 480 )
        
        
        let     contents = NSLocalizedString( "LableText.HowToUse01", comment: "PIN LIST\n\nAdd a Pin - Touching the plus sign (+) button will take you to the Pin Editor where you can associate provide information about that pin.\n\n\n" ) +
                           NSLocalizedString( "LableText.HowToUse02", comment: "PIN EDITOR\n\nProvides the ability to (a) associate an image with the pin, (b) assign it a name, (c) addresss and/or description, (d) modify its coordinates and/or altitude, " ) +
                           NSLocalizedString( "LableText.HowToUse03", comment: "(e) change the altitude display units and (f) set its pin color.  Touch the Save button when you are done.  To see the pin's location on the map, touch the Show on Map button\n\n\n" ) +
                           NSLocalizedString( "LableText.HowToUse04", comment: "SETTINGS\n\nTouch any populated row in the table to get information/configuration data about this app.\n\nAbout - Our contact information.\n\nHow to Use - This view.\n\n\n" )

        myTextView.text = contents
    }
    
    
    override func viewDidLayoutSubviews()
    {
        logTrace()
        super.viewDidLayoutSubviews()
        
        myTextView.setContentOffset( CGPoint.zero, animated: true )
    }
    
    
    override func didReceiveMemoryWarning()
    {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    
    
    
    
    
    
    
}
