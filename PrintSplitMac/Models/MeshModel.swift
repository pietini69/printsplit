//
//  MeshModel.swift
//  PrintSplitMac
//
//  Created by Niko Pietinen on 13.10.2026.
//

import Foundation
import SceneKit

public struct Vector3: Equatable, Hashable, Codable {
    public var x: Float
    public var y: Float
    public var z: Float
    
    public init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    public static let zero = Vector3(0, 0, 0)
    
    public static func + (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    public static func - (lhs: Vector3, rhs: Vector3) -> Vector3 {
        Vector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
    
    public static func * (lhs: Vector3, rhs: Float) -> Vector3 {
        Vector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }
    
    public static func / (lhs: Vector3, rhs: Float) -> Vector3 {
        Vector3(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }
    
    public func dot(_ other: Vector3) -> Float {
        x * other.x + y * other.y + z * other.z
    }
    
    public func cross(_ other: Vector3) -> Vector3 {
        Vector3(
            y * other.z - z * other.y,
            z * other.x - x * other.z,
            x * other.y - y * other.x
        )
    }
    
    public var lengthSquared: Float {
        x * x + y * y + z * z
    }
    
    public var length: Float {
        sqrtf(lengthSquared)
    }
    
    public var normalized: Vector3 {
        let len = length
        return len > 0.00001 ? self / len : Vector3.zero
    }
    
    public func distance(to other: Vector3) -> Float {
        (self - other).length
    }
}

public struct Triangle: Equatable {
    public var v1: Vector3
    public var v2: Vector3
    public var v3: Vector3
    public var normal: Vector3
    
    public init(v1: Vector3, v2: Vector3, v3: Vector3, normal: Vector3? = nil) {
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
        if let n = normal, n.lengthSquared > 0.0001 {
            self.normal = n.normalized
        } else {
            let edge1 = v2 - v1
            let edge2 = v3 - v1
            self.normal = edge1.cross(edge2).normalized
        }
    }
}

public struct BoundingBox {
    public var min: Vector3
    public var max: Vector3
    
    public var size: Vector3 {
        max - min
    }
    
    public var center: Vector3 {
        (min + max) * 0.5
    }
    
    public static let empty = BoundingBox(
        min: Vector3(.infinity, .infinity, .infinity),
        max: Vector3(-.infinity, -.infinity, -.infinity)
    )
}

public struct MeshModel {
    public var triangles: [Triangle]
    public var boundingBox: BoundingBox
    
    public init(triangles: [Triangle]) {
        self.triangles = triangles
        self.boundingBox = MeshModel.calculateBounds(triangles)
    }
    
    public static func calculateBounds(_ triangles: [Triangle]) -> BoundingBox {
        guard !triangles.isEmpty else { return .empty }
        var minX = Float.infinity, minY = Float.infinity, minZ = Float.infinity
        var maxX = -Float.infinity, maxY = -Float.infinity, maxZ = -Float.infinity
        
        for t in triangles {
            for v in [t.v1, t.v2, t.v3] {
                minX = min(minX, v.x); maxX = max(maxX, v.x)
                minY = min(minY, v.y); maxY = max(maxY, v.y)
                minZ = min(minZ, v.z); maxZ = max(maxZ, v.z)
            }
        }
        return BoundingBox(min: Vector3(minX, minY, minZ), max: Vector3(maxX, maxY, maxZ))
    }
    
    public func translated(by offset: Vector3) -> MeshModel {
        let newTriangles = triangles.map { t in
            Triangle(v1: t.v1 + offset, v2: t.v2 + offset, v3: t.v3 + offset, normal: t.normal)
        }
        return MeshModel(triangles: newTriangles)
    }
    
    /// Centers mesh in X and Y, and places bottom surface directly at Z = 0 (build plate surface)
    public func centeredOnBed() -> MeshModel {
        guard !triangles.isEmpty else { return self }
        let bbox = boundingBox
        let offset = Vector3(-bbox.center.x, -bbox.center.y, -bbox.min.z)
        return self.translated(by: offset)
    }
    
    /// Generates SceneKit geometry for interactive 3D rendering
    public func createSCNGeometry(color: NSColor = .systemCyan) -> SCNGeometry {
        guard !triangles.isEmpty else {
            return SCNGeometry()
        }
        
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var indices: [Int32] = []
        
        vertices.reserveCapacity(triangles.count * 3)
        normals.reserveCapacity(triangles.count * 3)
        indices.reserveCapacity(triangles.count * 3)
        
        var index: Int32 = 0
        for t in triangles {
            let n = SCNVector3(t.normal.x, t.normal.z, -t.normal.y)
            vertices.append(SCNVector3(t.v1.x, t.v1.z, -t.v1.y))
            vertices.append(SCNVector3(t.v2.x, t.v2.z, -t.v2.y))
            vertices.append(SCNVector3(t.v3.x, t.v3.z, -t.v3.y))
            
            normals.append(n)
            normals.append(n)
            normals.append(n)
            
            indices.append(index)
            indices.append(index + 1)
            indices.append(index + 2)
            index += 3
        }
        
        let vertexSource = SCNGeometrySource(vertices: vertices)
        let normalSource = SCNGeometrySource(normals: normals)
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        let geometry = SCNGeometry(sources: [vertexSource, normalSource], elements: [element])
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .lambert
        material.isDoubleSided = true
        geometry.materials = [material]
        
        return geometry
    }
    
    /// Demo primitive mesh (Cube with dimensions in mm)
    public static func makeCube(width: Float, depth: Float, height: Float) -> MeshModel {
        let hx = width / 2.0
        let hy = depth / 2.0
        let hz = height / 2.0
        
        let p1 = Vector3(-hx, -hy, -hz)
        let p2 = Vector3( hx, -hy, -hz)
        let p3 = Vector3( hx,  hy, -hz)
        let p4 = Vector3(-hx,  hy, -hz)
        let p5 = Vector3(-hx, -hy,  hz)
        let p6 = Vector3( hx, -hy,  hz)
        let p7 = Vector3( hx,  hy,  hz)
        let p8 = Vector3(-hx,  hy,  hz)
        
        var tris: [Triangle] = []
        // Bottom (z = -hz)
        tris.append(Triangle(v1: p1, v2: p3, v3: p2))
        tris.append(Triangle(v1: p1, v2: p4, v3: p3))
        // Top (z = hz)
        tris.append(Triangle(v1: p5, v2: p6, v3: p7))
        tris.append(Triangle(v1: p5, v2: p7, v3: p8))
        // Front (y = -hy)
        tris.append(Triangle(v1: p1, v2: p2, v3: p6))
        tris.append(Triangle(v1: p1, v2: p6, v3: p5))
        // Back (y = hy)
        tris.append(Triangle(v1: p4, v2: p7, v3: p3))
        tris.append(Triangle(v1: p4, v2: p8, v3: p7))
        // Left (x = -hx)
        tris.append(Triangle(v1: p1, v2: p5, v3: p8))
        tris.append(Triangle(v1: p1, v2: p8, v3: p4))
        // Right (x = hx)
        tris.append(Triangle(v1: p2, v2: p7, v3: p6))
        tris.append(Triangle(v1: p2, v2: p3, v3: p7))
        
        return MeshModel(triangles: tris)
    }
}
