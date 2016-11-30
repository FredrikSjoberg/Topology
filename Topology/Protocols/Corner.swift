//
//  Corner.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 30/11/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation

public protocol CornerType: Hashable {
    associatedtype Adjacent: Hashable
    associatedtype Downslope
    associatedtype Lake
    
    var elevation: Float { get }
    var downslope: Downslope { get }
    
    var adjacent: Set<Adjacent> { get }
    
    var lake: Lake? { get }
    
    var isOcean: Bool { get }
    var isBorder: Bool { get }
}
