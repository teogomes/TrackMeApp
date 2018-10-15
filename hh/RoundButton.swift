//
//  RoundButton.swift
//  hh
//
//  Created by Teodoro Gomes on 04/09/2018.
//  Copyright © 2018 Teodoro Gomes. All rights reserved.
//

import UIKit

@IBDesignable

class RoundButton: UIButton {

    @IBInspectable var cornerRadius : CGFloat = 0{
        didSet{
            self.layer.cornerRadius = cornerRadius
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0{
        didSet{
            self.layer.borderWidth = borderWidth
        }
    }
}
