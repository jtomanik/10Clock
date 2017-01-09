//
// Created by Joseph Daniels on 07/09/16.
// Copyright (c) 2016 Joseph Daniels. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
extension CALayer{
    open var size:CGSize{
        get{ return self.bounds.size.checked }
        set{ return self.bounds.size = newValue }
    }
    open var occupation:(CGSize, CGPoint) {
        get{ return (size, self.center.checked) }
        set{ size = newValue.0; position = newValue.1 }
    }
    open var center:CGPoint{
        get{ return self.bounds.center.checked }
    }
}
