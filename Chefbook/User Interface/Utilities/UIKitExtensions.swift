//
//  UIKitExtensionsViewController.swift
//  ClearedTo
//
//  Created by Clint Shank on 3/1/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



extension UIViewController {
    
    func presentAlert( title: String, message: String ) {
        
        logVerbose( "[ %@ ][ %@ ]", title, message )
        let         alert    = UIAlertController.init( title: title, message: message, preferredStyle: UIAlertController.Style.alert )
        let         okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ),
                                                   style: UIAlertAction.Style.default,
                                                   handler: nil )
        alert.addAction( okAction )
        
        present( alert, animated: true, completion: nil )
    }
    
}


extension String {
    
    func heightWithConstrainedWidth( width: CGFloat, font: UIFont ) -> CGFloat {
        
        let constraintRect = CGSize( width  : width,
                                     height : .greatestFiniteMagnitude )
        let boundingBox    = self.boundingRect( with        : constraintRect,
                                                options     : [.usesLineFragmentOrigin, .usesFontLeading],
                                                attributes  : [NSAttributedString.Key.font: font],
                                                context     : nil)
        return boundingBox.height
    }
    
    
}


func stringFor(_ boolValue: Bool ) -> String
{
    return ( boolValue ? "true" : "false" )
}



