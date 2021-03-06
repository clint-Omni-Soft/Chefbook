//
//  SplashScreenViewController.swift
//  MyPins
//
//  Created by Clint Shank on 4/10/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



class SplashScreenViewController: UIViewController {
    
    @IBOutlet weak var contactUsLabel : UILabel!
    @IBOutlet weak var titleLabel     : UILabel!
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
//        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "LabelText.About", comment: "About" )
        
        contactUsLabel  .text = NSLocalizedString( "LabelText.ContactUs", comment: "All rights reserved.  Contact us at" )
        titleLabel      .text = NSLocalizedString( "Title.App",           comment: "Where Was That?"                     )
    }
    
    
    override func viewWillAppear(_ animated: Bool ) {
        logTrace()
        super.viewWillAppear( animated )
    }
    
    
    override func viewWillDisappear(_ animated: Bool ) {
        logTrace()
        super.viewWillDisappear( animated )
    }
    
    
    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    
}
