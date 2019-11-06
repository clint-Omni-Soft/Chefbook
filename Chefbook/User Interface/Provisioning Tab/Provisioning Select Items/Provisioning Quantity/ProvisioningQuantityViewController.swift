//
//  ProvisioningQuantityViewController.swift
//  Chefbook
//
//  Created by Clint Shank on 10/28/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//


import UIKit


class ProvisioningQuantityViewController: UIViewController
{
    // MARK: Public Variables
    
    var myProvision : Provision!        // Set by our parent
    

    @IBOutlet weak var myTableView: UITableView!
    
    
    
    // MARK: Private Variables
    
    private let cellID = "ProvisioningQuanityTableViewCell"

    private let STORYBOARD_ID_PROVISIONING_SUMMARY = "ProvisioningSummaryViewController"

    private var     elementArray                  : [ProvisionElement]!
    private var     indexPathOfCellBeingEdited    = IndexPath(item: 0, section: 0)
    private var     originalViewOffset : CGFloat  = 0.0
    private var     provisionModified             = false
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString( "Title.ProvisioningSetQuantities", comment: "Set Quantities" )

        loadElementArray()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        provisionModified = false
        loadBarButtonItems()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear( animated )
        
        if provisionModified {
            ChefbookCentral.sharedInstance.saveUpdatedProvision(provision: myProvision )
        }
        
        provisionModified = false
    }
    

    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    
    
    // MARK: NSNotification Methods
    
    @objc func keyboardWillHideNotification( notification: NSNotification ) {
        logTrace()
        scrollCellBeingEdited( keyboardWillShow : false,
                               topOfKeyboard    : topOfKeyboardFromNotification( notification: notification ) )
    }
    
    
    @objc func keyboardWillShowNotification( notification: NSNotification ) {
        logTrace()
        scrollCellBeingEdited( keyboardWillShow : true,
                               topOfKeyboard    : topOfKeyboardFromNotification( notification: notification ) )
    }
    
    

    // MARK: Target / Action Methods
    
    @IBAction @objc func summaryBarButtonItemTouched( barButtonItem: UIBarButtonItem ) {
        logTrace()
        launchProvisioningSummaryViewController()
    }
    
    
    
    // MARK: Utility Methods

    private func launchProvisioningSummaryViewController() {
        
        logTrace()
        
        if provisionModified {
            ChefbookCentral.sharedInstance.saveUpdatedProvision(provision: myProvision )
            provisionModified = false
        }

        if let summaryVC : ProvisioningSummaryViewController = iPhoneViewControllerWithStoryboardId( storyboardId: STORYBOARD_ID_PROVISIONING_SUMMARY ) as? ProvisioningSummaryViewController {
            
            summaryVC.myProvision = myProvision
            
            let backItem = UIBarButtonItem()
            
            backItem.title = NSLocalizedString( "ButtonTitle.Back", comment: "Back" )
            navigationItem.backBarButtonItem = backItem
            
            navigationController?.pushViewController( summaryVC, animated: true )
        }
        else {
            logTrace( "ERROR: Could NOT load ProvisioningSelectItemsViewController!" )
        }
        
    }
    
    
    private func loadBarButtonItems() {
        logTrace()
        let     summaryBarButtonItem  = UIBarButtonItem.init( title : NSLocalizedString( "ButtonTitle.Summary", comment: "Summary" ),
                                                              style : .plain,
                                                              target: self,
                                                              action: #selector( summaryBarButtonItemTouched ) )
        
        navigationItem.rightBarButtonItem = summaryBarButtonItem
    }
    
    
    private func loadElementArray() {
        
        elementArray = myProvision.elements?.allObjects as? [ProvisionElement]
        
        elementArray = elementArray.sorted( by:
            { (element1, element2) -> Bool in
                let recipe1Name : String = element1.recipe?.name! ?? "a"
                let recipe2Name : String = element2.recipe?.name! ?? "b"
                
                return recipe1Name < recipe2Name     // We can do this because the name is a required field that must be unique
        } )
        
    }
    
    
    private func scrollCellBeingEdited( keyboardWillShow : Bool,     // false == willHide
                                        topOfKeyboard    : CGFloat ) {
        
        let     frame  = myTableView.frame
        var     origin = frame.origin
        
//        logVerbose( "[ %d ][ %d ] willShow[ %@ ] topOfKeyboard[ %f ]", indexPathOfCellBeingEdited.section, indexPathOfCellBeingEdited.row, stringFor( keyboardWillShow ), topOfKeyboard )
        if !keyboardWillShow {
            origin.y = ( originalViewOffset == 0.0 ) ? origin.y : originalViewOffset
        }
        else {
            originalViewOffset = origin.y
            
            if let cellBeingEdited = myTableView.cellForRow( at: indexPathOfCellBeingEdited ) {
                let     cellBottomY     = ( cellBeingEdited.frame.origin.y + cellBeingEdited.frame.size.height ) + originalViewOffset
                let     keyboardOverlap = topOfKeyboard - cellBottomY
                
                //                logVerbose( "cellBottomY[ %f ]  keyboardOverlap[ %f ]", cellBottomY, keyboardOverlap )
                if keyboardOverlap < 0.0 {
                    origin.y = origin.y + keyboardOverlap
                }
                
            }
            
        }
        
//        logVerbose( "originalViewOffset[ %f ]", originalViewOffset )
        myTableView.frame = CGRect( origin: origin, size: frame.size )
    }
    
    
    private func topOfKeyboardFromNotification( notification : NSNotification ) -> CGFloat {
        
        var     topOfKeyboard : CGFloat = 1000.0
        
        if let userInfo = notification.userInfo {
            let     endFrame = ( userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue )?.cgRectValue
            
            topOfKeyboard = endFrame?.origin.y ?? 1000.0 as CGFloat
        }
        
//        logVerbose( "topOfKeyboard[ %f ]", topOfKeyboard )
        return topOfKeyboard
    }
    
    
}



// MARK: ProvisioningQuanityTableViewCellDelegate Methods

extension ProvisioningQuantityViewController : ProvisioningQuanityTableViewCellDelegate {
    
    func provisioningQuanityTableViewCell( provisioningQuanityTableViewCell : ProvisioningQuanityTableViewCell,
                                           elementIndex                     : Int,
                                           didSetNew quantity               : String) {
        logTrace()
        elementArray[elementIndex].quantity = Int16( quantity ) ?? 1
        provisionModified = true
    }
    
    
    func provisioningQuanityTableViewCell( provisioningQuanityTableViewCell : ProvisioningQuanityTableViewCell,
                                           elementIndex                     : Int,
                                           didStartEditing                  : Bool) {
        logTrace()
        indexPathOfCellBeingEdited = IndexPath(item: elementIndex, section: 0)
    }
    

}



// MARK: UITableViewDataSource Methods

extension ProvisioningQuantityViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return elementArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: cellID ) else {
            
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
//        logVerbose( "section[ %d ] row[ %d ]", indexPath.section, indexPath.row )
        let     provisioningQuantityCell = cell as! ProvisioningQuanityTableViewCell
        let     element                  = elementArray[indexPath.row]
        
        provisioningQuantityCell.initializeWith( element      : element,
                                                 elementIndex : indexPath.row,
                                                 delegate     : self )
        return cell
    }
    
    
}




