//
//  PrinterPresets.swift
//  PrintSplitMac
//
//  Created by Niko Pietinen on 13.10.2026.
//

import Foundation

public struct PrinterBed: Identifiable, Hashable {
    public var id: String { name }
    public var name: String
    public var width: Float  // X (mm)
    public var depth: Float  // Y (mm)
    public var height: Float // Z (mm)
    
    public init(name: String, width: Float, depth: Float, height: Float) {
        self.name = name
        self.width = width
        self.depth = depth
        self.height = height
    }
}

public struct BedFitResult {
    public var fits: Bool
    public var overflowX: Float
    public var overflowY: Float
    public var overflowZ: Float
    public var recommendedAxis: PlaneSlicer.CutAxis
}

public class PrinterPresets {
    public static let standardPrinters: [PrinterBed] = [
        PrinterBed(name: "Bambu Lab X1C / P1S / A1 (256³)", width: 256, depth: 256, height: 256),
        PrinterBed(name: "Bambu Lab A1 Mini (180³)", width: 180, depth: 180, height: 180),
        PrinterBed(name: "Prusa MK4 / MK3S+ (250×210×220)", width: 250, depth: 210, height: 220),
        PrinterBed(name: "Prusa XL (360³)", width: 360, depth: 360, height: 360),
        PrinterBed(name: "Creality Ender 3 / V3 (220×220×250)", width: 220, depth: 220, height: 250),
        PrinterBed(name: "Voron 2.4 350 (350³)", width: 350, depth: 350, height: 350),
        PrinterBed(name: "Elegoo Neptune 4 (225×225×265)", width: 225, depth: 225, height: 265),
    ]
    
    /// Tests whether a mesh fits inside the specified printer build volume
    public static func checkFit(mesh: MeshModel, bed: PrinterBed) -> BedFitResult {
        let size = mesh.boundingBox.size
        let diffX = max(0, size.x - bed.width)
        let diffY = max(0, size.y - bed.depth)
        let diffZ = max(0, size.z - bed.height)
        
        let fits = diffX <= 0.01 && diffY <= 0.01 && diffZ <= 0.01
        
        // Recommend cutting across the dimension with the largest overflow
        var axis: PlaneSlicer.CutAxis = .z
        if diffX >= diffY && diffX >= diffZ {
            axis = .x
        } else if diffY >= diffX && diffY >= diffZ {
            axis = .y
        } else {
            axis = .z
        }
        
        return BedFitResult(
            fits: fits,
            overflowX: diffX,
            overflowY: diffY,
            overflowZ: diffZ,
            recommendedAxis: axis
        )
    }
}
