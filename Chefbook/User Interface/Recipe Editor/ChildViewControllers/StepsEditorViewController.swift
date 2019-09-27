//
//  StepsEditorViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 7/31/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol StepsEditorViewControllerDelegate: class {
    
    func stepsEditorViewController( stepsEditorViewController : StepsEditorViewController,
                                    didEditSteps              : Bool )
}



class StepsEditorViewController: UIViewController {
    
    @IBOutlet weak var myTextView: UITextView!
    
    weak var delegate : StepsEditorViewControllerDelegate?
    
    var steps : String!   // Set by our delegate and, if modified by the user, updated by us
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        title = NSLocalizedString( "Title.Steps", comment: "Steps" )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        myTextView.text = steps
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        if myTextView.text != steps {
            
            steps = myTextView.text
            delegate?.stepsEditorViewController( stepsEditorViewController: self,
                                                 didEditSteps: true )
        }
        
    }
    

}
