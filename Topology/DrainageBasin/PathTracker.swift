//
//  PathTracker.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 30/11/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation
import Utilities

class PathTracker<Corner: CornerType> {
    var paths: [Lineage<Corner>] = []
    
    func add(root: Corner) {
        paths.append(Lineage(element: root))
    }
    
    func link(child: Corner, parent: Corner) {
        guard let path = find(node: parent) else { return }
        path.link(parent: parent, child: child)
    }
    
    // Path is from 'node' -> 'root'
    func pathToRoot(from node: Corner) -> [Corner] {
        guard let path = find(node: node) else { return [] }
        return path.rootPath(from: node)
    }
    
    private func find(node: Corner) -> Lineage<Corner>? {
        for path in paths {
            if path.contains(element: node) {
                return path
            }
        }
        return nil
    }
}
