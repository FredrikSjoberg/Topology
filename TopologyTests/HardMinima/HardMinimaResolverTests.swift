//
//  HardMinimaResolverTests.swift
//  Topology
//
//  Created by Fredrik Sjöberg on 20/12/16.
//  Copyright © 2016 KnightsFee. All rights reserved.
//

import Foundation
import Nimble
import Quick
@testable import Topology

class HardMinimaResolverTests: QuickSpec {
    override func spec() {
        describe("Init") {
            it("should init correctly") {
                let resolver = HardMinimaResolver<TestCorner>(corners: [])
                expect(resolver.isEmpty).to(beTrue())
                
                var result: HardMinimaSolution<TestCorner>!
                expect { result = try resolver.process() }.toNot(throwError())
                expect(result).to(beNil())
            }
        }
        
        
//           c1 1.3
//     c0 1 *----*
//          |\   /\
//          | \0/  \
//     c4 0 *--*---* 1.6 c2
//           \ |  /
//            \| /
//             */
//            1.5 c3
        
        
        var minima: TestCorner!
        var c0: TestCorner!
        var c1: TestCorner!
        var c2: TestCorner!
        var c3: TestCorner!
        var c4: TestCorner!
        var corners: [TestCorner]!
        
        beforeEach {
            minima = TestCorner()
            c0 = TestCorner(elevation: 1)
            c1 = TestCorner(elevation: 1.3)
            c2 = TestCorner(elevation: 1.6)
            c3 = TestCorner(elevation: 1.5)
            c4 = TestCorner(elevation: 2)
            minima.adjacent = [c0,c1,c2,c3,c4]
            c0.adjacent = [c1,minima,c4]
            c1.adjacent = [c2,minima,c0]
            c2.adjacent = [c3,minima,c1]
            c3.adjacent = [c2,minima,c4]
            c4.adjacent = [c0,minima,c3]
            
            corners = [minima,c0,c1,c2,c3,c4]
        }
        
        describe("Simple Solution") {
            it("should resolve simple minima") {
                let resolver = HardMinimaResolver(corners: corners)
                expect(resolver.isEmpty).to(beFalse())
                
                var result: HardMinimaSolution<TestCorner>!
                expect { result = try resolver.process() }.toNot(throwError())
                expect(result).toNot(beNil())
                expect(result!.elevation).to(equal(1))
                result!.corner.elevation = result!.elevation
                
                var next: HardMinimaSolution<TestCorner>!
                expect{ next = try resolver.process() }.toNot(throwError())
                expect(next).to(beNil())
                expect(resolver.isEmpty).to(beTrue())
            }
        }
        
        describe("Linked Minima") {
            it("should resolve linked minima") {
                c4.elevation = 0
                
                let resolver = HardMinimaResolver(corners: corners)
                expect(resolver.isEmpty).to(beFalse())
                
                var result: HardMinimaSolution<TestCorner>!
                expect { result = try resolver.process() }.toNot(throwError())
                expect(result).toNot(beNil())
                expect(result!.elevation).to(equal(0.9))
                result!.corner.elevation = result!.elevation
                
                var next: HardMinimaSolution<TestCorner>!
                expect{ next = try resolver.process() }.toNot(throwError())
                expect(next).toNot(beNil())
                expect(next!.elevation).to(equal(0.9*0.9))
                next!.corner.elevation = next!.elevation
                
                expect(resolver.isEmpty).to(beTrue())
            }
        }
        
        describe("Add Corners") {
            it("should only add corners to unprocessed list that are hard zero elevation minimas") {
                let c5 = TestCorner()
                let c6 = TestCorner(elevation: 1.2)
                c2.adjacent.insert(c5)
                c5.adjacent.insert(c2)
                c5.adjacent.insert(c6)
                c6.adjacent.insert(c3)
                
                let resolver = HardMinimaResolver(corners: corners)
                resolver.addCorners(corners: [c5, c6])
                
                expect(resolver.isEmpty).to(beFalse())
                
                var result: HardMinimaSolution<TestCorner>!
                expect{ result = try resolver.process() }.toNot(throwError())
                
                expect(result).toNot(beNil())
                result!.corner.elevation = result!.elevation
                expect(resolver.isEmpty).to(beFalse())
                
                var next: HardMinimaSolution<TestCorner>!
                expect{ next = try resolver.process() }.toNot(throwError())
                expect(next).toNot(beNil())
                next!.corner.elevation = next!.elevation
                
                expect(resolver.isEmpty).to(beTrue())
                
            }
        }
        
        describe("Errors") {
            it("Should throw error if minima is ocean") {
                minima.isOcean = true
                let resolver = HardMinimaResolver(corners: corners)
                
                expect(resolver.isEmpty).to(beFalse())
                expect{ try resolver.process() }.to(throwError(errorType: HardMinimaResolverError<TestCorner>.self))
            }
            
            it("should throw error if all corners are hard minima") {
                corners.forEach{ $0.elevation = 0 }
                
                let resolver = HardMinimaResolver(corners: corners)
                
                expect(resolver.isEmpty).to(beFalse())
                expect{ try resolver.process() }.to(throwError(errorType: HardMinimaResolverError<TestCorner>.self))
            }
        }
    }
}
