//
//  CALayer+Additions.swift
//  TenClock
//
//  Created by Justyn Spooner on 12/01/2017.
//  Copyright © 2017 Joseph Daniels. All rights reserved.
//

import Foundation
import UIKit

extension CALayer {
    func applyChangeToAllSublayers(block: (CALayer) -> ()) {
        var queue: Array<CALayer> = [self]
        
        // I don't have my dev computer dos not sure of the syntax
        while let layer = queue.first {
            if let sublayers = layer.sublayers {
                queue += sublayers
            }
            
            block(layer)
            
            if let index = queue.index(of: layer) {
                queue.remove(at: index)
            }
        }
    }
}
