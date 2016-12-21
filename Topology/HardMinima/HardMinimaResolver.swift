//
//  HardMinimaResolver.swift
//  KnightsFee
//
//  Created by Fredrik Sjöberg on 24/01/16.
//  Copyright © 2016 Knights Fee. All rights reserved.
//

import Foundation
import Utilities

public enum HardMinimaResolverError<Corner: CornerType where Corner.Downslope == Corner, Corner.Adjacent == Corner> : Error {
    case MinimaIsOcean(corner: Corner)
    case NoSolutionPossibleFor(corner: Corner)
}

/// Tries to solve Zero Elevation Local Minima by finding a maximum elevation to raise corners to
public class HardMinimaResolver<Corner: CornerType where Corner.Downslope == Corner, Corner.Adjacent == Corner> {
    private var lineage: Lineage<Corner>?
    private var unprocessed: Set<Corner>
    
    public init(corners: [Corner]) {
        let filtered = corners.filter{ $0.elevation == 0 }
        unprocessed = Set(filtered)
    }
    
    private let deltaEpsilon: Float = 0.9
    
    public var isEmpty: Bool {
        return unprocessed.isEmpty
    }
    
    public func addCorners(corners: [Corner]) {
        let filtered = corners.filter{ $0.elevation == 0 }
        unprocessed.formUnion(filtered)
    }
    
    /// Will first and foremost look for any solution tree that has been generated.
    /// Secondly, it will create a new solution tree from the pool of unprocessed corners.
    /// Returns nil if processing is done!
    public func process() throws -> HardMinimaSolution<Corner>? {
        if let leaf = try solution() {
            return leaf
        }
        
        if !isEmpty {
            let entity = unprocessed.first!
            
            let elevation = try minElevation(for: entity)
            
            if elevation > 0 {
                // Simple case, just raise the elevation
                guard !entity.isOcean else { throw HardMinimaResolverError.MinimaIsOcean(corner: entity) }
                
                unprocessed.remove(entity)
                return HardMinimaSolution(corner: entity, elevation: elevation)
            }
            else {
                lineage = Lineage(element: entity)
                expand(with: lineage!, entity: entity)
                
                return try solution()
            }
        }
        // Complete
        return nil
    }
    
    private func solution() throws -> HardMinimaSolution<Corner>? {
        if let leaf = lineage?.leaves.first {
            // We have a connected graph of entities with leaves that pass the predicate
            // Thus, we can process the leaves in turn gradualy solve the problem
            let elevation = try minElevation(for: leaf){ $0.elevation > 0 }
            
            lineage?.prune(element: leaf)
            unprocessed.remove(leaf)
            
            return HardMinimaSolution(corner: leaf, elevation: elevation  * deltaEpsilon)
        }
        return nil
    }
    
    private func minElevation(for leaf: Corner, predicate: ((Corner) -> Bool)? = nil) throws -> Float {
        let adjacent = (predicate != nil ? Set(leaf.adjacent.filter(predicate!)) : leaf.adjacent)
        let minElevation = adjacent.map{ $0.elevation }.min()
        
        //        let minElevation = leaf.gAdjacent.filter{ $0.elevation > 0 }.map{ $0.elevation }.minElement()
        guard let elevation = minElevation else {
            throw HardMinimaResolverError.NoSolutionPossibleFor(corner: leaf)
        }
        return elevation
    }
    
    private func expand(with lineage: Lineage<Corner>, entity: Corner) {
        // We do not include ocean corners since they are allowed (required) to have elevation == 0
        entity.adjacent
            .filter{ $0.elevation == 0 && !$0.isOcean && !lineage.contains(element: $0) }
            .forEach{
                lineage.link(parent: entity, child: $0)
                expand(with: lineage, entity: $0)
        }
        
    }
}
