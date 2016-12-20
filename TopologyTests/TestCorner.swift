//
//  TestCorner.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 20/12/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation
@testable import Topology

class TestCorner: NSObject, CornerType {
    init(elevation: Float = 0) {
        self.elevation = elevation
    }
    
    var elevation: Float

    var downslope: TestCorner {
        let sorted = adjacent.sorted{ $0.elevation < $1.elevation }
        guard let lowest = sorted.first else {
            return self
        }
        return (lowest.elevation < elevation ? lowest : self)
    }
    
    var adjacent: Set<TestCorner> = []
    
    var touches: Set<TestCenter> = []
    
    var lake: TestLake?
    
    var isOcean: Bool = false

    var isBorder: Bool = false
}
