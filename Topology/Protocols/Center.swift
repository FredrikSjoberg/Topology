//
//  Center.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 30/11/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation

public protocol CenterType: Hashable {
    associatedtype Neighbor: Hashable
    associatedtype Corner: Hashable
    associatedtype Lake
    
    var neighbors: Set<Neighbor> { get }
    
    var corners: Set<Corner> { get }
    
    var lake: Lake? { get }
    var elevation: Float { get }
    var isCoast: Bool { get }
}
