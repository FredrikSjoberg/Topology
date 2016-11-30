//
//  Corner.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 30/11/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation

public protocol CornerType: Hashable {
    associatedtype Lake
    var elevation: Float { get }
    var downslope: Self { get }
    
    var adjacent: Set<Self> { get }
    
    var lake: Lake? { get }
    
    var isOcean: Bool { get }
    var isBorder: Bool { get }
}
