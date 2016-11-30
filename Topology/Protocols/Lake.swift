//
//  Lake.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 30/11/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation

public protocol LakeType: Hashable {
    associatedtype Location: CornerType
    associatedtype Section: CenterType
    
    var outflow: Location? { get }
    var corners: Set<Location> { get }
    var borderCorners: Set<Location> { get }
    
    var sections: Set<Section> { get }
    
    var elevation: Float { get }
}
