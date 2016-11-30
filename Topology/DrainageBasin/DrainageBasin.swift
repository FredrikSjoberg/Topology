//
//  DrainageBasin.swift
//  KnightsFee
//
//  Created by Fredrik Sjöberg on 25/01/16.
//  Copyright © 2016 Knights Fee. All rights reserved.
//

import Foundation
import Utilities

public enum DrainageBasinError<T: CornerType> : Error {
    case UnprocessedCornersInNetwork(unprocessed: Set<T>)
    case FailedToHandleLocalMinima(minima: Set<T>)
    case LocalMinimaWithoutRootPath(corner: T)
    case LocalMinimaAtZeroElevation(corner: T)
    case FailedToForceCarveLocalMinima(corner: T)
}


public class DrainageBasin<Corner: CornerType where Corner.Lake: LakeType, Corner.Lake.Location == Corner> {
    public var elevationRequest: ((Corner, Float) -> Void)!
    public var outflowRequest: ((Corner.Lake, Corner) -> Void)!
    
    private var pathTracker = PathTracker<Corner>()
    private var horizon: Heap<Corner> = Heap{ $0.elevation < $1.elevation }
    private var localMinima: Set<Corner> = []
    private var unprocessed: Set<Corner> = []
    
    /// Only LocalMinima that are NOT border and NOT ocean are considered
    private let localMinimaFilter: (Corner) -> Bool = { !$0.isBorder && !$0.isOcean && $0.downslope == $0 }
    
    /// NOT Ocean and Border
    private let initialLandHorizonFilter: (Corner) -> Bool = { (!$0.isOcean && $0.isBorder) }
    /// Ocean, but only if (any) adjacent corners are NOT Ocean
    // http://www.juliusparishy.com/articles/2014/12/14/adopting-map-reduce-in-swift
    private let initialOceanHorizonFilter: (Corner) -> Bool = { ($0.isOcean && $0.adjacent.reduce(false){ $0 || !$1.isOcean }) }
    /// 
    private let isHorizonFilter: (Corner, Set<Corner>) -> Bool = { $1.intersection($0.adjacent).count > 0 }
    
    public func errodeAndFlood(network: Set<Corner>) throws {
        // We allways start of with a "fresh" network set. That way calculating the initial horizon
        // is easier as we do not have to consider if a possible corner has been processed or not
        unprocessed = network
        
        // Identify localMinima
        localMinima = network.filter(localMinimaFilter).set()
        
        // Make sure we do not have any Zero Elevation Local Minima
        let resolver = HardMinimaResolver(corners: Array(localMinima))
        while let solution = try resolver.process() {
            elevationRequest(solution.corner, solution.elevation)
        }
        
        // Refresh trackers
        pathTracker = PathTracker()
        horizon = Heap{ $0.elevation < $1.elevation }
        
        // Create the horizon
        // Horizon is determined by either
        // a. Border Corners NOT being Ocean
        // b. Ocean Corners with Land Corners adjacent
        let filtered = unprocessed.filter{ initialLandHorizonFilter($0) || initialOceanHorizonFilter($0) }
        
        filtered.forEach{
            pathTracker.add(root: $0)
            horizon.push(element: $0)
        }
        unprocessed.subtract(filtered)
        
        // Begin cycling through our unprocessed corners
        while !horizon.isEmpty {
            if let current = horizon.pop() {
                // Handle any adjacent corners that are still unprocessed
                try current.adjacent
                    .filter{ unprocessed.contains($0) }
                    .forEach{
                        let next = $0
                        // Expand the path
                        pathTracker.link(child: next, parent: current)
                        
                        // Check if this corner should be set as a part of the horizon.
                        // Special consideration has to be taken with regards to Lakes:
                        // Lakes are not part of the horizon, but their border corners are.
                        // A Lake can be found if either:
                        // a) the corner is an outflow for a lake
                        // b) the corner touches a lakeCenter
                        if let lake = next.lake {
                            // By design, if we encounter a lake we have found the endpoint of this path.
                            // This also means we have found the outflow for this lake, since once we do
                            // encounter a lake, its border corners will be added to the pathTracker as rootPaths
                            // and possibly added to the horizon.
                            outflowRequest(lake, next)
                            
                            // Lake borders should be evaluated as possible parts of the horizon
                            // NOTE: Should be possible to remove the filtering on 'unprocessed' since we should 
                            //       allways have unprocessed corners in lake border.
                            let lakeBorders = lake.border
                                .filter{ unprocessed.contains($0) &&  $0 != next }
                            
                            // Add a new pathRoot for each of the border corners
                            lakeBorders.forEach{ pathTracker.add(root: $0) }
                            
                            // Add to horizon as needed
                            lakeBorders
                                .filter{ isHorizonFilter($0, unprocessed) }
                                .forEach{ horizon.push(element: $0) }
                            
                            
                            // Finaly, we remove ALL lake corners from unprocessed
                            // The design forces the first corner of the lake to be discovered to also act as its outflow,
                            // we can remove all other "localMimima" as they are considered to "flow" through the outflow.
                            unprocessed.subtract(lake.corners)
                            let toRemove = lake.corners.subtracting([next])
                            localMinima.subtract(toRemove)
                        }
                        else {
                            // Add to horizon as needed
                            if isHorizonFilter(next, unprocessed) {
                                horizon.push(element: next)
                            }
                            
                        }
                        // Finaly, mark the corner as processed
                        try markAsProcessed(corner: next)
                }
            }
        }
        
        guard unprocessed.count == 0 else { throw DrainageBasinError.UnprocessedCornersInNetwork(unprocessed: unprocessed) }
        guard localMinima.count == 0 else { throw DrainageBasinError.FailedToHandleLocalMinima(minima: localMinima) }
    }
    
    private func markAsProcessed(corner: Corner) throws {
        if localMinima.contains(corner) {
            try processLocalMinima(at: corner)
        }
        unprocessed.remove(corner)
    }
    
    private func processLocalMinima(at corner: Corner) throws {
        if localMinima.contains(corner) {
            let minimaElevation = corner.elevation
            guard minimaElevation > 0 else { throw DrainageBasinError.LocalMinimaAtZeroElevation(corner: corner) }
            
            let path = pathTracker.pathToRoot(from: corner)
            guard path.count > 0 else { throw DrainageBasinError.LocalMinimaWithoutRootPath(corner: corner) }
            
            if let carvePath = CarvePath(path: path, minimaElevation: minimaElevation) {
                try execute(carvePath: carvePath)
            }
            else {
                let forcePath = try ForceCarvePath(path: path, minimaElevation: minimaElevation)
                try execute(carvePath: forcePath)
            }
            
            localMinima.remove(corner)
        }
    }
    
    private func execute<Path: CarvePathType where Path.Location == Corner>(carvePath: Path) throws {
        var currentElevation = carvePath.minimaElevation
        try carvePath.path.forEach{
            if let lake = $0.lake {
                if currentElevation != lake.elevation {
                    if $0 == carvePath.destination {
                        // Update with new elevation
                        lake.corners.forEach{
                            elevationRequest($0, currentElevation)
                        }
                        
                        // Make sure we do not get a new local minima at lake outflow
                        if let outflow = lake.outflow {
                            if outflow.downslope == outflow {
                                //print("DrainageBasin AFTER Carve: Lake outflow is localMin | Border? \(outflow.isBorder)")
                                // Add to localMinima and try to process it
                                localMinima.insert(outflow)
                                try markAsProcessed(corner: outflow)
                            }
                        }
                    }
                }
                
            }
            else {
                // BUGFIX: Hackish fix for rounding errors with very small stepElevation
                // The bug would set elevation to "almost but not quite 0"
                if $0.isOcean && $0 == carvePath.destination && currentElevation > 0 {
                    currentElevation = 0
                }
                elevationRequest($0, currentElevation)
            }
            currentElevation -= carvePath.stepElevation
        }
    }
}


