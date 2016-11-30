//
//  PoolTracker.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 30/11/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation

internal class PoolTracker<Corner: CornerType where Corner.Lake: LakeType, Corner.Lake.Location == Corner, Corner.Downslope == Corner, Corner.Adjacent == Corner, Corner.Center: CenterType, Corner.Center.Neighbor == Corner.Center, Corner.Center.Lake == Corner.Lake, Corner.Lake.Section == Corner.Center, Corner.Center.Corner == Corner> {
    var pool: Set<Corner.Center>
    var flooded: Set<Corner.Center> = []
    var watermass: Float
    var targetElevation: Float = 0
    
    private let validCenter: (Corner.Center) -> Bool = { $0.lake == nil && !$0.isCoast }
    
    /// Calculates the total difference (up or down) of a center's corners.
    private let deltaCornerElevation: (Corner.Center, Float) -> Float = {
        let node = $0
        let target = $1
        return node.corners.reduce(0){ $0 + fabsf($1.elevation - target) }
    }
    
    init(watermass: Float, pool: Set<Corner.Center>) throws {
        self.watermass = watermass
        self.pool = pool
            .filter(validCenter)
            .set()
        
        // Set the correct targetElevation
        let initial = self.pool
            .map{ ($0, deltaCornerElevation($0, $0.elevation)) }
            .sorted{ $0.1 < $1.1 }
        
        guard let elevation = initial.first?.1 else {
            throw FloodwaveError.NoValidInitialNode(center: pool)
        }
        targetElevation = elevation
    }
    
    
    func processNext() {
        // Find our starting point.
        let valid = pool
            .map{ ($0, deltaCornerElevation($0, targetElevation)) }
            .sorted{ $0.1 < $1.1 }
        
        guard let possible = valid.first else {
            watermass = 0
            return
        }
        
        if possible.1 <=  watermass {
            // Reduce watermass by the amount it took to "fill" the center
            // This is equal to the "delta" of the center
            watermass -= possible.1
            
            // Transfer to flooded
            pool.remove(possible.0)
            flooded.insert(possible.0)
            
            // Replenish Pool
            let additions = possible.0.neighbors
                .filter(validCenter)
                .filter{ !flooded.contains($0) }
            pool.formUnion(additions)
        }
        else {
            watermass = 0
        }
    }
}
