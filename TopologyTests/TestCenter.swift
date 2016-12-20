//
//  TestCenter.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 20/12/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation
@testable import Topology

class TestCenter: NSObject, CenterType {
    var neighbors: Set<TestCenter> = []
    
    var corners: Set<TestCorner> = []
    
    var lake: TestLake?
    var elevation: Float = 0
    var isCoast: Bool = false
}
