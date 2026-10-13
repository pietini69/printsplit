//
//  PinGenerator.swift
//  PrintSplitMac
//
//  Created by Niko Pietinen on 13.10.2026.
//

import Foundation

public struct Vector2: Equatable, Hashable {
    public var x: Float
    public var y: Float
    
    public init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }
    
    public static func + (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(lhs.x + rhs.x, lhs.y + rhs.y)
    }
    
    public static func - (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(lhs.x - rhs.x, lhs.y - rhs.y)
    }
    
    public static func * (lhs: Vector2, rhs: Float) -> Vector2 {
        Vector2(lhs.x * rhs, lhs.y * rhs)
    }
    
    public var lengthSquared: Float {
        x * x + y * y
    }
    
    public var length: Float {
        sqrtf(lengthSquared)
    }
}

public enum PinType: String, CaseIterable, Identifiable {
    case cylinder = "Round Cylinder"
    case hexagon = "Hexagonal (Anti-twist)"
    
    public var id: String { rawValue }
}

public struct PinConfig {
    public var type: PinType = .cylinder
    public var pinCount: Int = 2
    public var radius: Float = 3.5 // mm (7mm diameter dowel)
    public var length: Float = 16.0 // mm
    public var clearance: Float = 0.20 // mm (3D printing tolerance)
    public var createSeparatePins: Bool = true // Print pins separately vs attached to Part A
    
    public init(
        type: PinType = .cylinder,
        pinCount: Int = 2,
        radius: Float = 3.5,
        length: Float = 16.0,
        clearance: Float = 0.20,
        createSeparatePins: Bool = true
    ) {
        self.type = type
        self.pinCount = pinCount
        self.radius = radius
        self.length = length
        self.clearance = clearance
        self.createSeparatePins = createSeparatePins
    }
}

public struct PinResult {
    public var partAWithSockets: MeshModel
    public var partBWithSockets: MeshModel
    public var separatePins: MeshModel?
    public var printablePins: MeshModel?
    public var pinPositions: [Vector3]
}

public class PinGenerator {
    
    // MARK: - Main Pin & Socket Generator
    
    /// Generates dowel pin locations, physical socket cavities in Part A and Part B, and separate dowel pins
    public static func generatePins(
        cutResult: CutResult,
        config: PinConfig
    ) -> PinResult {
        let normal = cutResult.cutPlaneNormal.normalized
        let center = cutResult.cutPlaneCenter
        
        // Find tangent axes orthogonal to normal
        var tangent: Vector3
        if abs(normal.x) < 0.9 {
            tangent = normal.cross(Vector3(1, 0, 0)).normalized
        } else {
            tangent = normal.cross(Vector3(0, 1, 0)).normalized
        }
        let bitangent = normal.cross(tangent).normalized
        
        // Spacing based on cut size
        let spacing: Float = max(config.radius * 3.5, 18.0)
        var positions: [Vector3] = []
        
        switch config.pinCount {
        case 1:
            positions.append(center)
        case 2:
            positions.append(center + tangent * spacing)
            positions.append(center - tangent * spacing)
        case 3:
            positions.append(center + tangent * spacing)
            positions.append(center - tangent * (spacing * 0.5) + bitangent * (spacing * 0.866))
            positions.append(center - tangent * (spacing * 0.5) - bitangent * (spacing * 0.866))
        default: // 4+ pins
            positions.append(center + tangent * spacing + bitangent * spacing)
            positions.append(center - tangent * spacing + bitangent * spacing)
            positions.append(center - tangent * spacing - bitangent * spacing)
            positions.append(center + tangent * spacing - bitangent * spacing)
        }
        
        // Generate separate CAD dowel pins for visualization
        var pinTriangles: [Triangle] = []
        let pinSegments = config.type == .hexagon ? 6 : 24
        for pos in positions {
            let pinMesh = makeCylinder(
                center: pos,
                normal: normal,
                radius: config.radius,
                height: config.length,
                segments: pinSegments,
                chamferEnds: true
            )
            pinTriangles.append(contentsOf: pinMesh.triangles)
        }
        let pinsCADModel = MeshModel(triangles: pinTriangles)
        
        // Generate printable pins standing on build bed
        let printablePins = makePrintablePins(count: positions.count, config: config)
        
        // Now generate physical socket cavities in Part A and Part B
        let socketResult = carveSockets(
            cutResult: cutResult,
            positions: positions,
            config: config,
            normal: normal,
            center: center,
            tangent: tangent,
            bitangent: bitangent
        )
        
        return PinResult(
            partAWithSockets: socketResult.partA,
            partBWithSockets: socketResult.partB,
            separatePins: pinsCADModel,
            printablePins: printablePins,
            pinPositions: positions
        )
    }
    
    // MARK: - Socket Carving Geometry
    
    private static func carveSockets(
        cutResult: CutResult,
        positions: [Vector3],
        config: PinConfig,
        normal: Vector3,
        center: Vector3,
        tangent: Vector3,
        bitangent: Vector3
    ) -> (partA: MeshModel, partB: MeshModel) {
        guard !cutResult.cutEdges.isEmpty else {
            return (cutResult.partA, cutResult.partB)
        }
        
        let socketRadius = config.radius + config.clearance
        let socketDepth = config.length * 0.5 + config.clearance
        let segments = config.type == .hexagon ? 6 : 16
        
        // 1. Convert 3D cutEdges to 2D
        var boundaryEdges2D: [(Vector2, Vector2)] = []
        var boundaryPoints2D: [Vector2] = []
        
        for edge in cutResult.cutEdges {
            let u1 = (edge.0 - center).dot(tangent)
            let v1 = (edge.0 - center).dot(bitangent)
            let u2 = (edge.1 - center).dot(tangent)
            let v2 = (edge.1 - center).dot(bitangent)
            
            let p1 = Vector2(u1, v1)
            let p2 = Vector2(u2, v2)
            boundaryEdges2D.append((p1, p2))
            
            // Use exact boundary vertices so planar cap matches mesh edges with 0 T-junctions
            boundaryPoints2D.append(p1)
            boundaryPoints2D.append(p2)
        }
        
        // 2. Generate 2D hole rim points for each pin
        var holeCenters2D: [Vector2] = []
        var holeRimPoints2D: [[Vector2]] = []
        
        for pos in positions {
            let cu = (pos - center).dot(tangent)
            let cv = (pos - center).dot(bitangent)
            let hc = Vector2(cu, cv)
            holeCenters2D.append(hc)
            
            var rims: [Vector2] = []
            for j in 0..<segments {
                let theta = (Float(j) / Float(segments)) * (Float.pi * 2.0)
                let rimPt = Vector2(cu + cosf(theta) * socketRadius, cv + sinf(theta) * socketRadius)
                rims.append(rimPt)
            }
            holeRimPoints2D.append(rims)
        }
        
        // 3. Deduplicate all 2D points for Delaunay
        var allPoints: [Vector2] = []
        for p in boundaryPoints2D {
            if !allPoints.contains(where: { isClose($0, p) }) {
                allPoints.append(p)
            }
        }
        for rims in holeRimPoints2D {
            for p in rims {
                if !allPoints.contains(where: { isClose($0, p) }) {
                    allPoints.append(p)
                }
            }
        }
        
        // 4. Compute 2D Delaunay triangulation
        let rawTriangles = computeDelaunay(points: allPoints)
        
        // 5. Filter triangles: inside boundary AND outside all holes
        var validCapTriangles: [Triangle2D] = []
        let holeRadiusSq = (socketRadius - 0.05) * (socketRadius - 0.05)
        
        for t in rawTriangles {
            let c = t.centroid
            
            // Discard if inside any hole
            var inHole = false
            for hc in holeCenters2D {
                if (c - hc).lengthSquared < holeRadiusSq {
                    inHole = true
                    break
                }
            }
            if inHole { continue }
            
            // Discard if outside outer boundary
            if !pointInPolygon(c, edges: boundaryEdges2D) {
                continue
            }
            
            validCapTriangles.append(t)
        }
        
        guard !validCapTriangles.isEmpty else {
            // Safe fallback
            return (cutResult.partA, cutResult.partB)
        }
        
        // 6. Convert 2D cap triangles back to 3D with correct winding
        var capTrianglesB: [Triangle] = []
        var capTrianglesA: [Triangle] = []
        
        for t2 in validCapTriangles {
            let vA = center + tangent * t2.a.x + bitangent * t2.a.y
            var vB = center + tangent * t2.b.x + bitangent * t2.b.y
            var vC = center + tangent * t2.c.x + bitangent * t2.c.y
            
            // Check winding: (vB - vA) x (vC - vA) should point along +normal
            let cross = (vB - vA).cross(vC - vA)
            if cross.dot(normal) < 0 {
                swap(&vB, &vC)
            }
            
            // Part B cap faces +normal
            capTrianglesB.append(Triangle(v1: vA, v2: vB, v3: vC, normal: normal))
            // Part A cap faces -normal (inverted winding)
            capTrianglesA.append(Triangle(v1: vA, v2: vC, v3: vB, normal: normal * -1.0))
        }
        
        // 7. Generate 3D cavity walls and bottom caps for each socket
        var socketTrisB: [Triangle] = []
        var socketTrisA: [Triangle] = []
        
        for (idx, pos) in positions.enumerated() {
            let rims2D = holeRimPoints2D[idx]
            
            // Part B: cavity extends down into -normal
            let botCenterB = pos - normal * socketDepth
            var topRimB: [Vector3] = []
            var botRimB: [Vector3] = []
            
            for pt in rims2D {
                let topPt = center + tangent * pt.x + bitangent * pt.y
                topRimB.append(topPt)
                botRimB.append(topPt - normal * socketDepth)
            }
            
            for j in 0..<segments {
                let next = (j + 1) % segments
                // Side wall of hole (inward facing into cavity)
                socketTrisB.append(Triangle(v1: topRimB[j], v2: botRimB[next], v3: botRimB[j]))
                socketTrisB.append(Triangle(v1: topRimB[j], v2: topRimB[next], v3: botRimB[next]))
                // Bottom cap (facing +normal)
                socketTrisB.append(Triangle(v1: botCenterB, v2: botRimB[next], v3: botRimB[j], normal: normal))
            }
            
            // Part A: cavity extends up into +normal
            let botCenterA = pos + normal * socketDepth
            var topRimA: [Vector3] = []
            var botRimA: [Vector3] = []
            
            for pt in rims2D {
                let topPt = center + tangent * pt.x + bitangent * pt.y
                topRimA.append(topPt)
                botRimA.append(topPt + normal * socketDepth)
            }
            
            for j in 0..<segments {
                let next = (j + 1) % segments
                // Side wall of hole (inward facing into cavity)
                socketTrisA.append(Triangle(v1: topRimA[j], v2: botRimA[j], v3: botRimA[next]))
                socketTrisA.append(Triangle(v1: topRimA[j], v2: botRimA[next], v3: topRimA[next]))
                // Bottom cap (facing -normal)
                socketTrisA.append(Triangle(v1: botCenterA, v2: botRimA[j], v3: botRimA[next], normal: normal * -1.0))
            }
        }
        
        let finalPartB = MeshModel(triangles: cutResult.uncappedTrianglesB + capTrianglesB + socketTrisB)
        let finalPartA = MeshModel(triangles: cutResult.uncappedTrianglesA + capTrianglesA + socketTrisA)
        
        return (finalPartA, finalPartB)
    }
    
    // MARK: - Printable Dowel Pins (Bed Standing)
    
    /// Generates standalone dowel pins standing upright on the build bed (Z = 0) with entry chamfer
    public static func makePrintablePins(
        count: Int,
        config: PinConfig
    ) -> MeshModel {
        guard count > 0 else { return MeshModel(triangles: []) }
        
        let segments = config.type == .hexagon ? 6 : 24
        let spacing: Float = max(config.radius * 3.0, 16.0)
        let totalSpan = Float(count - 1) * spacing
        let startX = -totalSpan * 0.5
        
        var allTris: [Triangle] = []
        for i in 0..<count {
            let xPos = startX + Float(i) * spacing
            let center = Vector3(xPos, 0, config.length * 0.5)
            let pin = makeCylinder(
                center: center,
                normal: Vector3(0, 0, 1),
                radius: config.radius,
                height: config.length,
                segments: segments,
                chamferEnds: true
            )
            allTris.append(contentsOf: pin.triangles)
        }
        return MeshModel(triangles: allTris)
    }
    
    // MARK: - Cylinder / Prism Mesh Generator
    
    public static func makeCylinder(
        center: Vector3,
        normal: Vector3,
        radius: Float,
        height: Float,
        segments: Int = 24,
        chamferEnds: Bool = false
    ) -> MeshModel {
        var tangent: Vector3
        if abs(normal.x) < 0.9 {
            tangent = normal.cross(Vector3(1, 0, 0)).normalized
        } else {
            tangent = normal.cross(Vector3(0, 1, 0)).normalized
        }
        let bitangent = normal.cross(tangent).normalized
        
        let halfH = height / 2.0
        let bottomCenter = center - normal * halfH
        let topCenter = center + normal * halfH
        
        let chamfer: Float = chamferEnds ? min(0.6, radius * 0.2) : 0.0
        let topChamferCenter = topCenter - normal * chamfer
        let botChamferCenter = bottomCenter + normal * chamfer
        
        var bottomRim: [Vector3] = []
        var botMidRim: [Vector3] = []
        var topMidRim: [Vector3] = []
        var topRim: [Vector3] = []
        
        for i in 0..<segments {
            let theta = (Float(i) / Float(segments)) * (Float.pi * 2.0)
            let cosT = cosf(theta)
            let sinT = sinf(theta)
            
            let radialFull = tangent * (cosT * radius) + bitangent * (sinT * radius)
            let radialChamfer = tangent * (cosT * (radius - chamfer)) + bitangent * (sinT * (radius - chamfer))
            
            bottomRim.append(bottomCenter + radialChamfer)
            botMidRim.append(botChamferCenter + radialFull)
            topMidRim.append(topChamferCenter + radialFull)
            topRim.append(topCenter + radialChamfer)
        }
        
        var tris: [Triangle] = []
        for i in 0..<segments {
            let next = (i + 1) % segments
            
            if chamferEnds && chamfer > 0.05 {
                // Bottom bevel
                tris.append(Triangle(v1: bottomRim[i], v2: botMidRim[i], v3: botMidRim[next]))
                tris.append(Triangle(v1: bottomRim[i], v2: botMidRim[next], v3: bottomRim[next]))
                
                // Main cylinder body
                tris.append(Triangle(v1: botMidRim[i], v2: topMidRim[i], v3: topMidRim[next]))
                tris.append(Triangle(v1: botMidRim[i], v2: topMidRim[next], v3: botMidRim[next]))
                
                // Top bevel
                tris.append(Triangle(v1: topMidRim[i], v2: topRim[i], v3: topRim[next]))
                tris.append(Triangle(v1: topMidRim[i], v2: topRim[next], v3: topMidRim[next]))
                
                // Bottom cap
                tris.append(Triangle(v1: bottomCenter, v2: bottomRim[next], v3: bottomRim[i], normal: normal * -1.0))
                // Top cap
                tris.append(Triangle(v1: topCenter, v2: topRim[i], v3: topRim[next], normal: normal))
            } else {
                // Standard unchamfered cylinder
                tris.append(Triangle(v1: botMidRim[i], v2: topMidRim[i], v3: topMidRim[next]))
                tris.append(Triangle(v1: botMidRim[i], v2: topMidRim[next], v3: botMidRim[next]))
                tris.append(Triangle(v1: bottomCenter, v2: botMidRim[next], v3: botMidRim[i], normal: normal * -1.0))
                tris.append(Triangle(v1: topCenter, v2: topMidRim[i], v3: topMidRim[next], normal: normal))
            }
        }
        
        return MeshModel(triangles: tris)
    }
    
    // MARK: - 2D Delaunay Helper
    
    private struct Triangle2D {
        var a: Vector2
        var b: Vector2
        var c: Vector2
        
        func circumcircleContains(_ p: Vector2) -> Bool {
            let ax = a.x, ay = a.y
            let bx = b.x, by = b.y
            let cx = c.x, cy = c.y
            let d = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
            if abs(d) < 0.000001 { return false }
            let ux = ((ax * ax + ay * ay) * (by - cy) + (bx * bx + by * by) * (cy - ay) + (cx * cx + cy * cy) * (ay - by)) / d
            let uy = ((ax * ax + ay * ay) * (cx - bx) + (bx * bx + by * by) * (ax - cx) + (cx * cx + cy * cy) * (bx - ax)) / d
            let rSq = (ax - ux) * (ax - ux) + (ay - uy) * (ay - uy)
            let distSq = (p.x - ux) * (p.x - ux) + (p.y - uy) * (p.y - uy)
            return distSq < (rSq - 0.0001)
        }
        
        var centroid: Vector2 {
            Vector2((a.x + b.x + c.x) / 3.0, (a.y + b.y + c.y) / 3.0)
        }
    }
    
    private static func computeDelaunay(points: [Vector2]) -> [Triangle2D] {
        guard points.count >= 3 else { return [] }
        
        var minX = points[0].x, maxX = points[0].x
        var minY = points[0].y, maxY = points[0].y
        for p in points {
            minX = min(minX, p.x); maxX = max(maxX, p.x)
            minY = min(minY, p.y); maxY = max(maxY, p.y)
        }
        let dx = maxX - minX
        let dy = maxY - minY
        let deltaMax = max(dx, dy) * 4.0 + 100.0
        let midX = (minX + maxX) * 0.5
        let midY = (minY + maxY) * 0.5
        
        let st1 = Vector2(midX - 2.0 * deltaMax, midY - deltaMax)
        let st2 = Vector2(midX + 2.0 * deltaMax, midY - deltaMax)
        let st3 = Vector2(midX, midY + 2.0 * deltaMax)
        
        var triangles = [Triangle2D(a: st1, b: st2, c: st3)]
        
        for p in points {
            var badTris: [Triangle2D] = []
            var remainingTris: [Triangle2D] = []
            for t in triangles {
                if t.circumcircleContains(p) {
                    badTris.append(t)
                } else {
                    remainingTris.append(t)
                }
            }
            
            var polygon: [(Vector2, Vector2)] = []
            for t in badTris {
                let edges = [(t.a, t.b), (t.b, t.c), (t.c, t.a)]
                for e in edges {
                    var shared = false
                    for other in badTris {
                        if other.a == t.a && other.b == t.b && other.c == t.c { continue }
                        let otherEdges = [(other.a, other.b), (other.b, other.c), (other.c, other.a)]
                        for oe in otherEdges {
                            if (isClose(e.0, oe.0) && isClose(e.1, oe.1)) || (isClose(e.0, oe.1) && isClose(e.1, oe.0)) {
                                shared = true
                                break
                            }
                        }
                        if shared { break }
                    }
                    if !shared {
                        polygon.append(e)
                    }
                }
            }
            
            triangles = remainingTris
            for e in polygon {
                triangles.append(Triangle2D(a: e.0, b: e.1, c: p))
            }
        }
        
        func isSuperVert(_ v: Vector2) -> Bool {
            isClose(v, st1) || isClose(v, st2) || isClose(v, st3)
        }
        
        return triangles.filter { !isSuperVert($0.a) && !isSuperVert($0.b) && !isSuperVert($0.c) }
    }
    
    private static func pointInPolygon(_ pt: Vector2, edges: [(Vector2, Vector2)]) -> Bool {
        var inside = false
        for (p1, p2) in edges {
            if ((p1.y > pt.y) != (p2.y > pt.y)) {
                let denom = p2.y - p1.y
                if abs(denom) > 0.00001 {
                    let xIntersect = (p2.x - p1.x) * (pt.y - p1.y) / denom + p1.x
                    if pt.x < xIntersect {
                        inside.toggle()
                    }
                }
            }
        }
        return inside
    }
    
    private static func isClose(_ p1: Vector2, _ p2: Vector2) -> Bool {
        (p1 - p2).lengthSquared < 0.0004
    }
}
