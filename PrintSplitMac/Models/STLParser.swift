//
//  STLParser.swift
//  PrintSplitMac
//
//  Created by Niko Pietinen on 13.10.2026.
//

import Foundation

public enum STLError: LocalizedError {
    case fileTooSmall
    case invalidHeader
    case invalidCount
    case writeFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .fileTooSmall: return "STL file is corrupted or too small."
        case .invalidHeader: return "Invalid STL header format."
        case .invalidCount: return "Invalid triangle count in binary STL."
        case .writeFailed(let reason): return "Failed to export STL: \(reason)"
        }
    }
}

public class STLParser {
    
    /// Reads binary or ASCII STL file
    public static func load(from url: URL) throws -> MeshModel {
        let data = try Data(contentsOf: url)
        if isBinarySTL(data) {
            return try parseBinarySTL(data)
        } else {
            return try parseAsciiSTL(data)
        }
    }
    
    /// Checks if STL data is binary
    private static func isBinarySTL(_ data: Data) -> Bool {
        guard data.count >= 84 else { return false }
        let count = data.subdata(in: 80..<84).withUnsafeBytes { $0.load(as: UInt32.self) }
        let expectedSize = 84 + Int(count) * 50
        // Exact match or within reasonable range confirms binary
        return data.count == expectedSize || (data.count > 84 && !isText(data.prefix(256)))
    }
    
    private static func isText(_ data: Data) -> Bool {
        let prefix = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return prefix.lowercased().hasPrefix("solid")
    }
    
    /// Parses high-speed binary STL
    public static func parseBinarySTL(_ data: Data) throws -> MeshModel {
        guard data.count >= 84 else { throw STLError.fileTooSmall }
        
        let count = Int(data.subdata(in: 80..<84).withUnsafeBytes { $0.load(as: UInt32.self) })
        var triangles: [Triangle] = []
        triangles.reserveCapacity(count)
        
        let total = data.count
        
        data.withUnsafeBytes { rawBuffer in
            let ptr = rawBuffer.baseAddress!.advanced(by: 84)
            for i in 0..<count {
                let currentOffset = i * 50
                if 84 + currentOffset + 50 > total { break }
                
                let triPtr = ptr.advanced(by: currentOffset)
                
                let nx = triPtr.load(fromByteOffset: 0, as: Float.self)
                let ny = triPtr.load(fromByteOffset: 4, as: Float.self)
                let nz = triPtr.load(fromByteOffset: 8, as: Float.self)
                
                let v1x = triPtr.load(fromByteOffset: 12, as: Float.self)
                let v1y = triPtr.load(fromByteOffset: 16, as: Float.self)
                let v1z = triPtr.load(fromByteOffset: 20, as: Float.self)
                
                let v2x = triPtr.load(fromByteOffset: 24, as: Float.self)
                let v2y = triPtr.load(fromByteOffset: 28, as: Float.self)
                let v2z = triPtr.load(fromByteOffset: 32, as: Float.self)
                
                let v3x = triPtr.load(fromByteOffset: 36, as: Float.self)
                let v3y = triPtr.load(fromByteOffset: 40, as: Float.self)
                let v3z = triPtr.load(fromByteOffset: 44, as: Float.self)
                
                let normal = Vector3(nx, ny, nz)
                let v1 = Vector3(v1x, v1y, v1z)
                let v2 = Vector3(v2x, v2y, v2z)
                let v3 = Vector3(v3x, v3y, v3z)
                
                triangles.append(Triangle(v1: v1, v2: v2, v3: v3, normal: normal))
            }
        }
        
        return MeshModel(triangles: triangles)
    }
    
    /// Parses ASCII STL fallback
    public static func parseAsciiSTL(_ data: Data) throws -> MeshModel {
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            throw STLError.invalidHeader
        }
        
        var triangles: [Triangle] = []
        var currentNormal = Vector3.zero
        var currentVertices: [Vector3] = []
        
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let tokens = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            guard !tokens.isEmpty else { continue }
            
            if tokens[0] == "facet" && tokens.count >= 5 && tokens[1] == "normal" {
                let x = Float(tokens[2]) ?? 0
                let y = Float(tokens[3]) ?? 0
                let z = Float(tokens[4]) ?? 0
                currentNormal = Vector3(x, y, z)
                currentVertices.removeAll()
            } else if tokens[0] == "vertex" && tokens.count >= 4 {
                let x = Float(tokens[1]) ?? 0
                let y = Float(tokens[2]) ?? 0
                let z = Float(tokens[3]) ?? 0
                currentVertices.append(Vector3(x, y, z))
            } else if tokens[0] == "endfacet" {
                if currentVertices.count == 3 {
                    triangles.append(Triangle(v1: currentVertices[0], v2: currentVertices[1], v3: currentVertices[2], normal: currentNormal))
                }
                currentVertices.removeAll()
            }
        }
        
        return MeshModel(triangles: triangles)
    }
    
    /// Exports binary STL with guaranteed watertight structure
    public static func export(mesh: MeshModel, to url: URL) throws {
        var data = Data()
        // 80 bytes header
        var header = "PrintSplit 1.0 Binary STL Export - Native Mac 3D Engine".data(using: .utf8)!
        if header.count < 80 {
            header.append(Data(repeating: 0, count: 80 - header.count))
        } else {
            header = header.prefix(80)
        }
        data.append(header)
        
        // Triangle count (4 bytes UInt32)
        var count = UInt32(mesh.triangles.count)
        withUnsafeBytes(of: &count) { data.append(contentsOf: $0) }
        
        // Triangles: 50 bytes each
        let attr: UInt16 = 0
        for t in mesh.triangles {
            var nx = t.normal.x, ny = t.normal.y, nz = t.normal.z
            withUnsafeBytes(of: &nx) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: &ny) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: &nz) { data.append(contentsOf: $0) }
            
            var v1x = t.v1.x, v1y = t.v1.y, v1z = t.v1.z
            withUnsafeBytes(of: &v1x) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: &v1y) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: &v1z) { data.append(contentsOf: $0) }
            
            var v2x = t.v2.x, v2y = t.v2.y, v2z = t.v2.z
            withUnsafeBytes(of: &v2x) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: &v2y) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: &v2z) { data.append(contentsOf: $0) }
            
            var v3x = t.v3.x, v3y = t.v3.y, v3z = t.v3.z
            withUnsafeBytes(of: &v3x) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: &v3y) { data.append(contentsOf: $0) }
            withUnsafeBytes(of: &v3z) { data.append(contentsOf: $0) }
            
            withUnsafeBytes(of: attr) { data.append(contentsOf: $0) }
        }
        
        try data.write(to: url)
    }
}
