//
//  CarvePathType.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 30/11/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation

public protocol CarvePathType {
    associatedtype Location: CornerType
    
    var path: [Location] { get }
    var minimaElevation: Float { get }
    var targetElevation: Float { get }
}

extension CarvePathType {
    var steps: Int {
        return path.count-1
    }
    
    var stepElevation: Float {
        return (minimaElevation - targetElevation)/Float(steps)
    }
    
    var destination: Location {
        return path.last!
    }
}
