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
                do {
                    let result = try resolver.process()
                    expect(result).to(beNil())
                }
                catch {
                    print(error)
                }
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
        
        let minima = TestCorner()
        let c0 = TestCorner(elevation: 1)
        let c1 = TestCorner(elevation: 1.3)
        let c2 = TestCorner(elevation: 1.6)
        let c3 = TestCorner(elevation: 1.5)
        let c4 = TestCorner(elevation: 2)
        minima.adjacent = [c0,c1,c2,c3,c4]
        c0.adjacent = [c1,minima,c4]
        c1.adjacent = [c2,minima,c0]
        c2.adjacent = [c3,minima,c1]
        c3.adjacent = [c2,minima,c4]
        c4.adjacent = [c0,minima,c3]
        
        let corners = [minima,c0,c1,c2,c3,c4]
        
        describe("Simple Solution") {
            it("should resolve simple minima") {
                let resolver = HardMinimaResolver(corners: corners)
                expect(resolver.isEmpty).to(beFalse())
                do {
                    let result = try resolver.process()
                    expect(result).toNot(beNil())
                    expect(result!.elevation).to(equal(1))
                    result!.corner.elevation = result!.elevation
                    
                    let next = try resolver.process()
                    expect(next).to(beNil())
                    expect(resolver.isEmpty).to(beTrue())
                }
                catch {
                    print(error)
                }
            }
        }
        
        describe("Linked Minima") {
            it("should resolve linked minima") {
                minima.elevation = 0
                c4.elevation = 0
                
                let resolver = HardMinimaResolver(corners: corners)
                expect(resolver.isEmpty).to(beFalse())
                do {
                    let result = try resolver.process()
                    expect(result).toNot(beNil())
                    expect(result!.elevation).to(equal(0.9))
                    result!.corner.elevation = result!.elevation
                    
                    let next = try resolver.process()
                    expect(next).toNot(beNil())
                    expect(next!.elevation).to(equal(0.9*0.9))
                    next!.corner.elevation = next!.elevation
                    
                    expect(resolver.isEmpty).to(beTrue())
                }
                catch {
                    print(error)
                }
            }
        }
    }
}
