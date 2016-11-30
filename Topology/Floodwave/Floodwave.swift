//
//  Floodwave.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 30/11/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation
import Utilities


public enum FloodwaveError<Corner: CornerType where Corner.Lake: LakeType, Corner.Lake.Location == Corner, Corner.Downslope == Corner, Corner.Adjacent == Corner, Corner.Center: CenterType, Corner.Center.Neighbor == Corner.Center, Corner.Center.Lake == Corner.Lake, Corner.Lake.Section == Corner.Center, Corner.Center.Corner == Corner>: Error {
    case NoValidInitialNode(center: Set<Corner.Center>)
    case NoWatermassFlowForCorner(corner: Corner)
}

/**
 Applies a flood over nodes starting from a vertex.
 Flood magnitude depends on watermassFlow at initial vertex.
 
 :warning: Should not be used on a vertex network without local minima as might have unexpected results
 */
public class Floodwave<Corner: CornerType where Corner.Lake: LakeType, Corner.Lake.Location == Corner, Corner.Downslope == Corner, Corner.Adjacent == Corner, Corner.Center: CenterType, Corner.Center.Neighbor == Corner.Center, Corner.Center.Lake == Corner.Lake, Corner.Lake.Section == Corner.Center, Corner.Center.Corner == Corner> {
    public var createLakeRequest: (([Corner.Center], Float) -> Corner.Lake)!
    public var removeLakeRequest: ((Corner.Lake) -> Void)!
    public var addSectionsRequest: ((Set<Corner.Center>, Corner.Lake) -> Void)!
    /// :param1: Sections to move
    /// :param2: To lake
    public var moveSectionsRequest: ((Set<Corner.Center>, Corner.Lake) -> Void)!
    public var elevationRequest: ((Set<Corner>, Float) -> Void)!
    
    public init() {
    }
    
    /**
     Floods land untill threshold is reached
     See flood:proposedElevation for further information
     
     :param: threshold [0, 1]
     */
    public func flood(watermassFlow: [Corner : Float], untilThreshold threshold: Float) throws {
        let sorted = watermassFlow.sorted{ $0.1 > $1.1 }.map{ $0.0 }
        
        // The amount of lakes to be created depends on "lakeThreshold"
        // This is a simple percentage of land covered with lakes
        // LakeThreshold of:
        // 0 -> no lakes
        // 1 -> 20% lakes
        var targetLakeCenters = Int(threshold * 0.2 * Float(sorted.filter{ !$0.isOcean }.count))
        var queue = Queue(elements: sorted)
        while !queue.isEmpty && targetLakeCenters > 0 {
            if let corner = queue.pop() {
                guard let watermass = watermassFlow[corner] else { throw FloodwaveError.NoWatermassFlowForCorner(corner: corner) }
                let tracker = try centersToFlood(around: corner, watermass: watermass)
                try flood(centers: Array(tracker.flooded), proposedElevation: tracker.targetElevation)
                
                // Invalidate processed corners
                tracker.flooded
                    .flatMap{ $0.corners }
                    .forEach{ queue.invalidate(element: $0) }
                
                // Update targetNum
                targetLakeCenters -= tracker.flooded.count
            }
        }
    }
    
    /**
     Will flood the 'centers' creating a lake in the process. Elevation of lake might not be 'proposedElevation'
     
     :param: centers target to flood
     :param: elevation the proposed elevation the new lake will be flattened to
     :warning: centers must NOT contain a center that is allready part of an existing lake
     :warning: elevation of lake created may be lower if a lake merge took place
     :warning: generated lakes do NOT have an outflow set.
     */
    public func flood(centers: [Corner.Center], proposedElevation: Float) throws -> Corner.Lake {
        // Check if centers have neighbors that contain lake(s)
        let neighborLakes = centers.flatMap{ $0.neighbors }
            .set()
            .subtracting(centers)
            .flatMap{ $0.lake }
            .set()
        
        guard neighborLakes.count > 0 else {
            // We have no direct lake neighbors, create a new Lake
            return createLakeRequest(centers, proposedElevation)
        }
        
        // Determine the lake with the lowest elevation and merge everything into 1
        let hostLake = neighborLakes
            .sorted{ $0.elevation < $1.elevation }
            .first!
        let hostElevation = hostLake.elevation
        let lakeElevation = (proposedElevation < hostElevation ? proposedElevation : hostElevation)
        
        // Add centers to hostLake
        addSectionsRequest(centers.set(), hostLake)
        
        let otherLakes = neighborLakes
            .filter{ $0 != hostLake }
        
        // Transfer other lake's centers to hostLake
        let otherCenters = otherLakes
            .flatMap{ $0.sections }
            .set()
        moveSectionsRequest(otherCenters, hostLake)
//        modify.sections(from: otherCenters)
        
        // Set new elevation for hostLake
        let elevations = hostLake.sections
            .flatMap{ $0.corners }
            .set()
        elevationRequest(elevations, lakeElevation)
//            .forEach{ ModifyCorner(entity: $0).elevation(lakeElevation) }
        
        // Remove leftover lakes after merge
        try otherLakes.forEach{ removeLakeRequest($0) }
        
        return hostLake
    }
    
    
    /**
     Select centers for flooding from the supplied corner.
     
     :warning: returned centers may have lakes as direct neighbors
     :param: vertex starting point
     :returns: centers flooded nodes
     */
    private func centersToFlood(around corner: Corner, watermass: Float) throws -> PoolTracker<Corner> {
        // The corners watermassFlow will determine if we can flood it.
        // WatermassFlow > Center's deltaCornerElevation == flooded center
        
        // The pool will guide us forward
        let tracker = try PoolTracker(watermass: watermass, pool: corner.touches)
        
        while tracker.watermass > 0 {
            tracker.processNext()
        }
        return tracker
    }
}
