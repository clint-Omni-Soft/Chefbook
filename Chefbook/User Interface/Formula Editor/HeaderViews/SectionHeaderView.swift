//
//  SectionHeaderView.swift
//  Chefbook
//
//  Created by Clint Shank on 9/18/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit



protocol SectionHeaderViewDelegate : class
{
    func sectionHeaderView( sectionHeaderView        : SectionHeaderView,
                            didRequestAddFor section : Int )
}



class SectionHeaderView: UITableViewHeaderFooterView
{
    // MARK: Public Variables
    
    static let reuseIdentifier : String = String( describing: self )
    static var nib             : UINib { return UINib( nibName: reuseIdentifier, bundle: nil ) }


    // MARK: Private Variables
    
    private      var addButton  : UIButton!
    private weak var delegate   : SectionHeaderViewDelegate!
    private      var section    = 1
    private      var titleLabel : UILabel!

    
    // MARK: UITableViewHeaderFooterView Lifecycle Methods
    
    override init( reuseIdentifier: String? )
    {
        logTrace()
        super.init( reuseIdentifier: reuseIdentifier )
        
        addButton = UIButton.init( type: .system )
        
        addButton.addTarget( self, action: #selector( addButtonTouched ), for: .touchUpInside )
        addButton.setTitle(  "+", for: .normal )
        addButton.titleLabel?.font = .systemFont( ofSize: 24 )

        contentView.addSubview( addButton )
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        addButton.widthAnchor   .constraint( equalToConstant: 14.0       ).isActive = true
        addButton.heightAnchor  .constraint( equalToConstant: 14.0       ).isActive = true
        addButton.centerYAnchor .constraint( equalTo: self.centerYAnchor ).isActive = true
        addButton.trailingAnchor.constraint( equalTo: contentView.layoutMarginsGuide.trailingAnchor ).isActive = true
    }

    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func addButtonTouched(_ sender: Any )
    {
        logVerbose( "section[ %d ]", section )
        delegate.sectionHeaderView( sectionHeaderView : self,
                                    didRequestAddFor  : section )
    }
    
    
    
    // MARK: Public Initializers
    
    func initWith( title         : String,
                   for section   : Int,
                   with delegate : SectionHeaderViewDelegate )
    {
//        logTrace()
        self.delegate   = delegate
        self.section    = section
        textLabel?.text = title
    }
    

    
    
}
