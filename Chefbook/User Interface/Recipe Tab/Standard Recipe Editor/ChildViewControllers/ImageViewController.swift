//
//  ImageViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 7/12/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController,
                           UIScrollViewDelegate {
    
    var imageName : String!     // Set by our parent
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView : UIImageView!
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString( "Title.RecipeImage", comment: "Recipe Image" )
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
    }
    
    
    override func viewWillAppear(_ animated: Bool ) {
        logTrace()
        super.viewWillAppear( animated )
        
        imageView.image = ChefbookCentral.sharedInstance.imageWith( imageName )
    }
    
    
    
    // MARK: UIScrollViewDelegate Methods
    
    func viewForZooming( in scrollView: UIScrollView ) -> UIView? {
//        logTrace()
        return imageView
    }
    
    
}
