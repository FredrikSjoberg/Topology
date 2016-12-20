//
//  TestLake.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 20/12/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation
@testable import Topology

class TestLake: NSObject, LakeType {
    var outflow: TestCorner?
    var corners: Set<TestCorner> = []
    var borderCorners: Set<TestCorner> = []
    
    var sections: Set<TestCenter> = []
    
    var elevation: Float = 0
}
