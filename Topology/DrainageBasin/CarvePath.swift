//
//  CarvePath.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 30/11/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation

/// Valid target types include anything with:
/// - a valid downslope (ie, not self)
/// - ocean
/// - border
/// - a lake
/// But elevation must be lower (ie carveTaretElevation:)
class CarvePath<Corner: CornerType> : CarvePathType {
    private let carveTargetType: (Corner) -> Bool = { $0.downslope != $0 || $0.isOcean || $0.isBorder || $0.lake != nil }
    private let carveTargetElevation: (Corner, Float) -> Bool = { $0.elevation < $1 }
    
    var path: [Corner] = []
    let minimaElevation: Float
    var targetElevation: Float = 0
    
    init?(path: [Corner], minimaElevation: Float) {
        self.minimaElevation = minimaElevation
        
        let pathWithTarget = path.take{ self.carveTargetElevation($0, minimaElevation) && self.carveTargetType($0) }
        
        // Make sure we have more than just the localMinima in the path
        guard pathWithTarget.count > 1 else { return nil }
        // We require a target with a lower elevation that our localMinima
        guard pathWithTarget.last!.elevation < minimaElevation else { return nil }
        
        self.path = pathWithTarget
        self.targetElevation = pathWithTarget.last!.elevation
    }
}
