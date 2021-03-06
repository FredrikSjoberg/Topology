//
//  HardMinimaSolution.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 30/11/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation

public struct HardMinimaSolution<Corner: CornerType where Corner.Downslope == Corner, Corner.Adjacent == Corner> {
    public let corner: Corner
    public let elevation: Float
}
