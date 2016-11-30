//
//  ForceCarvePath.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 30/11/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation

/// Forced targets include:
/// - lakes (can be lowered)
/// - border (can be lowered)
/// - any land (ie ANY LAND that was not included in standard carve, ex: other local minimas)
class ForceCarvePath<Corner: CornerType> : CarvePathType {
    private let forceCarveTargetType: (Corner) -> Bool = { $0.lake != nil || $0.isBorder || !$0.isOcean } // NOTE: Should possibly be ($0.downslope == $0 && !$0.isOcean) instead of !$0.isOcean
    private let forceCarveDeltaTargetElevation: Float = 0.9
    
    var path: [Corner] = []
    let minimaElevation: Float
    let targetElevation: Float
    
    init(path: [Corner], minimaElevation: Float) throws {
        self.minimaElevation = minimaElevation
        self.targetElevation = minimaElevation * forceCarveDeltaTargetElevation
        
        let pathWithTarget = path.prefix{ self.forceCarveTargetType($0) }
        
        // Make sure we have more than just the localMinima in the path
        guard pathWithTarget.count > 1 else {
            throw DrainageBasinError.FailedToForceCarveLocalMinima(corner: pathWithTarget.first!) }
        
        self.path = pathWithTarget
    }
}
