//
//  PlaneSlicer.swift
//  PrintSplitMac
//
//  Created by Niko Pietinen on 13.10.2026.
//

import Foundation

public struct CutResult {
    public var partA: MeshModel // Positive side of cut plane
    public var partB: MeshModel // Negative side of cut plane
    public var cutPlaneCenter: Vector3
    public var cutPlaneNormal: Vector3
    public var cutAreaApprox: Float
    public var cutEdges: [(Vector3, Vector3)]
    public var uncappedTrianglesA: [Triangle]
    public var uncappedTrianglesB: [Triangle]
}

public class PlaneSlicer {
    
    public enum CutAxis {
        case x
        case y
        case z
        
        public var normal: Vector3 {
            switch self {
            case .x: return Vector3(1, 0, 0)
            case .y: return Vector3(0, 1, 0)
            case .z: return Vector3(0, 0, 1)
            }
        }
    }
    
    /// Splits mesh along a plane defined by a point and a normal vector
    public static func slice(mesh: MeshModel, planeOrigin: Vector3, planeNormal: Vector3, capHoles: Bool = true) -> CutResult {
        let normal = planeNormal.normalized
        var trisA: [Triangle] = []
        var trisB: [Triangle] = []
        var cutEdges: [(Vector3, Vector3)] = []
        
        for tri in mesh.triangles {
            let d1 = normal.dot(tri.v1 - planeOrigin)
            let d2 = normal.dot(tri.v2 - planeOrigin)
            let d3 = normal.dot(tri.v3 - planeOrigin)
            
            let eps: Float = 0.0001
            let sign1 = d1 > eps ? 1 : (d1 < -eps ? -1 : 0)
            let sign2 = d2 > eps ? 1 : (d2 < -eps ? -1 : 0)
            let sign3 = d3 > eps ? 1 : (d3 < -eps ? -1 : 0)
            
            // All vertices on positive side
            if sign1 >= 0 && sign2 >= 0 && sign3 >= 0 {
                trisA.append(tri)
                continue
            }
            // All vertices on negative side
            if sign1 <= 0 && sign2 <= 0 && sign3 <= 0 {
                trisB.append(tri)
                continue
            }
            
            // Triangle straddles the plane -> split it
            splitTriangle(tri, d1: d1, d2: d2, d3: d3, trisA: &trisA, trisB: &trisB, cutEdges: &cutEdges)
        }
        
        var cutArea: Float = 0.0
        var capTrianglesB: [Triangle] = []
        var capTrianglesA: [Triangle] = []
        
        // Cap the planar cut face so both parts are watertight
        if capHoles && !cutEdges.isEmpty {
            let capTriangles = triangulatePlanarCut(cutEdges: cutEdges, planeNormal: normal, planeOrigin: planeOrigin)
            for t in capTriangles {
                cutArea += 0.5 * (t.v2 - t.v1).cross(t.v3 - t.v1).length
                // Add forward cap to Part B, inverted cap to Part A
                capTrianglesB.append(Triangle(v1: t.v1, v2: t.v2, v3: t.v3, normal: normal))
                capTrianglesA.append(Triangle(v1: t.v1, v2: t.v3, v3: t.v2, normal: normal * -1.0))
            }
        }
        
        return CutResult(
            partA: MeshModel(triangles: trisA + capTrianglesA),
            partB: MeshModel(triangles: trisB + capTrianglesB),
            cutPlaneCenter: planeOrigin,
            cutPlaneNormal: normal,
            cutAreaApprox: cutArea,
            cutEdges: cutEdges,
            uncappedTrianglesA: trisA,
            uncappedTrianglesB: trisB
        )
    }
    
    private static func splitTriangle(
        _ tri: Triangle,
        d1: Float, d2: Float, d3: Float,
        trisA: inout [Triangle],
        trisB: inout [Triangle],
        cutEdges: inout [(Vector3, Vector3)]
    ) {
        // Group vertices by side
        let verts = [tri.v1, tri.v2, tri.v3]
        let dists = [d1, d2, d3]
        
        var posIndices: [Int] = []
        var negIndices: [Int] = []
        
        for i in 0..<3 {
            if dists[i] >= 0 {
                posIndices.append(i)
            } else {
                negIndices.append(i)
            }
        }
        
        guard !posIndices.isEmpty && !negIndices.isEmpty else { return }
        
        if posIndices.count == 1 {
            // 1 vertex on pos side, 2 on neg side
            let pIdx = posIndices[0]
            let n1Idx = (pIdx + 1) % 3
            let n2Idx = (pIdx + 2) % 3
            
            let vP = verts[pIdx]
            let vN1 = verts[n1Idx]
            let vN2 = verts[n2Idx]
            
            let i1 = intersect(vP, vN1, dP: dists[pIdx], dN: dists[n1Idx])
            let i2 = intersect(vP, vN2, dP: dists[pIdx], dN: dists[n2Idx])
            
            // Part A gets 1 triangle
            trisA.append(Triangle(v1: vP, v2: i1, v3: i2, normal: tri.normal))
            // Part B gets 2 triangles
            trisB.append(Triangle(v1: vN1, v2: vN2, v3: i2, normal: tri.normal))
            trisB.append(Triangle(v1: vN1, v2: i2, v3: i1, normal: tri.normal))
            
            cutEdges.append((i1, i2))
        } else if posIndices.count == 2 {
            // 2 vertices on pos side, 1 on neg side
            let nIdx = negIndices[0]
            let p1Idx = (nIdx + 1) % 3
            let p2Idx = (nIdx + 2) % 3
            
            let vN = verts[nIdx]
            let vP1 = verts[p1Idx]
            let vP2 = verts[p2Idx]
            
            let i1 = intersect(vN, vP1, dP: dists[nIdx], dN: dists[p1Idx])
            let i2 = intersect(vN, vP2, dP: dists[nIdx], dN: dists[p2Idx])
            
            // Part B gets 1 triangle
            trisB.append(Triangle(v1: vN, v2: i1, v3: i2, normal: tri.normal))
            // Part A gets 2 triangles
            trisA.append(Triangle(v1: vP1, v2: vP2, v3: i2, normal: tri.normal))
            trisA.append(Triangle(v1: vP1, v2: i2, v3: i1, normal: tri.normal))
            
            cutEdges.append((i2, i1))
        }
    }
    
    private static func intersect(_ p1: Vector3, _ p2: Vector3, dP: Float, dN: Float) -> Vector3 {
        let denom = dP - dN
        let t: Float = abs(denom) > 0.00001 ? (dP / denom) : 0.5
        let clamped = max(0.0, min(1.0, t))
        return p1 + (p2 - p1) * clamped
    }
    
    /// Triangulates the cut boundary into planar cap triangles
    private static func triangulatePlanarCut(cutEdges: [(Vector3, Vector3)], planeNormal: Vector3, planeOrigin: Vector3) -> [Triangle] {
        guard cutEdges.count >= 3 else { return [] }
        
        // Approximate planar centroid
        var center = Vector3.zero
        for edge in cutEdges {
            center = center + edge.0 + edge.1
        }
        center = center / Float(cutEdges.count * 2)
        
        var capTriangles: [Triangle] = []
        for edge in cutEdges {
            if (edge.0 - edge.1).lengthSquared > 0.001 {
                capTriangles.append(Triangle(v1: center, v2: edge.0, v3: edge.1, normal: planeNormal))
            }
        }
        return capTriangles
    }
}
