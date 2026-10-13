//
//  ControlsSidebarView.swift
//  PrintSplitMac
//
//  Created by Niko Pietinen on 13.10.2026.
//

import SwiftUI

public struct ControlsSidebarView: View {
    @Binding var currentMesh: MeshModel?
    @Binding var partA: MeshModel?
    @Binding var partB: MeshModel?
    @Binding var separatePins: MeshModel?
    @Binding var cutPlaneOffset: Float
    @Binding var cutAxis: PlaneSlicer.CutAxis
    @Binding var explodeOffset: Float
    @Binding var selectedBed: PrinterBed
    @Binding var pinConfig: PinConfig
    @Binding var isLicensePresented: Bool
    
    var onPerformCut: () -> Void
    var onGeneratePins: () -> Void
    var onExportPartA: () -> Void
    var onExportPartB: () -> Void
    var onExportPins: () -> Void
    var onOpenInOrcaSlicer: () -> Void
    var onResetCamera: (() -> Void)? = nil
    
    @ObservedObject var licenseManager = LicenseManager.shared
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 1. Model Info & Printer Bed
                cardContainer {
                    modelInfoSection
                }
                
                // 2. Cut Plane Parameters
                cardContainer {
                    cutPlaneSection
                }
                
                // 3. Dowel Pin & Alignment Connectors
                cardContainer {
                    dowelPinsSection
                }
                
                // 4. Export & Slicer Bridge
                cardContainer {
                    exportSection
                }
            }
            .padding(14)
        }
        .frame(minWidth: 350, idealWidth: 380, maxWidth: 440)
        .background(Color(red: 0.95, green: 0.96, blue: 0.97))
    }
    
    private var cutRange: ClosedRange<Float> {
        guard let mesh = currentMesh else { return -100...100 }
        let bbox = mesh.boundingBox
        switch cutAxis {
        case .z:
            return max(0, bbox.min.z)...max(1.0, bbox.max.z)
        case .y:
            return min(-1.0, bbox.min.y)...max(1.0, bbox.max.y)
        case .x:
            return min(-1.0, bbox.min.x)...max(1.0, bbox.max.x)
        }
    }
    
    // MARK: - Card Container Helper
    
    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
    }
    
    // MARK: - Sections
    
    private var modelInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("3D MODEL & PRINTER BED")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "cube.transparent")
                    .foregroundColor(.blue)
            }
            
            if let mesh = currentMesh {
                let size = mesh.boundingBox.size
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Dimensions:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(String(format: "%.1f × %.1f × %.1f mm", size.x, size.y, size.z))")
                            .font(.system(.footnote, design: .monospaced).bold())
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Triangles:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(mesh.triangles.count)")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                .cornerRadius(8)
                
                // Bed Selector
                HStack {
                    Text("Target Printer:")
                        .font(.caption)
                        .foregroundColor(.primary)
                    Spacer()
                    Picker("", selection: $selectedBed) {
                        ForEach(PrinterPresets.standardPrinters) { bed in
                            Text(bed.name).tag(bed)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Bed Fit Check
                let fit = PrinterPresets.checkFit(mesh: mesh, bed: selectedBed)
                if fit.fits {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Fits within build volume")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 2)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Exceeds build volume!")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                        if fit.overflowZ > 0 {
                            Text("• Z-Height exceeds by \(String(format: "%.1f", fit.overflowZ)) mm")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        if fit.overflowX > 0 {
                            Text("• X-Width exceeds by \(String(format: "%.1f", fit.overflowX)) mm")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        if fit.overflowY > 0 {
                            Text("• Y-Depth exceeds by \(String(format: "%.1f", fit.overflowY)) mm")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.10))
                    .cornerRadius(6)
                }
            } else {
                Text("No STL loaded. Drop a file or use demo model.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var cutPlaneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PLANE CUT SETTINGS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "scissors")
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("Cut Axis:")
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Picker("", selection: $cutAxis) {
                    Text("Z (Height)").tag(PlaneSlicer.CutAxis.z)
                    Text("Y (Depth)").tag(PlaneSlicer.CutAxis.y)
                    Text("X (Width)").tag(PlaneSlicer.CutAxis.x)
                }
                .pickerStyle(.segmented)
                .onChange(of: cutAxis) { newAxis in
                    if let mesh = currentMesh {
                        let bbox = mesh.boundingBox
                        switch newAxis {
                        case .z: cutPlaneOffset = (bbox.min.z + bbox.max.z) / 2.0
                        case .y: cutPlaneOffset = (bbox.min.y + bbox.max.y) / 2.0
                        case .x: cutPlaneOffset = (bbox.min.x + bbox.max.x) / 2.0
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Cut Plane Position:")
                        .font(.caption)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(String(format: "%.1f mm", cutPlaneOffset))")
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundColor(.blue)
                }
                
                Slider(value: $cutPlaneOffset, in: cutRange, step: 0.5)
            }
            
            Button(action: onPerformCut) {
                HStack {
                    Image(systemName: "scissors")
                    Text("Slice Model Across Plane")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
    }
    
    private var dowelPinsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DOWEL PINS & CONNECTORS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "pin.fill")
                    .foregroundColor(.green)
            }
            
            HStack {
                Text("Pin Shape:")
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Picker("", selection: $pinConfig.type) {
                    ForEach(PinType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Stepper("Number of Pins: \(pinConfig.pinCount)", value: $pinConfig.pinCount, in: 1...6)
                .font(.caption)
                .foregroundColor(.primary)
            
            HStack {
                Text("Pin Diameter:")
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(String(format: "%.1f mm", pinConfig.radius * 2))")
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundColor(.primary)
            }
            Slider(value: $pinConfig.radius, in: 1.5...6.0, step: 0.5)
            
            HStack {
                Text("FDM Clearance:")
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(String(format: "%.2f mm", pinConfig.clearance))")
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundColor(.green)
            }
            Slider(value: $pinConfig.clearance, in: 0.10...0.40, step: 0.05)
            
            HStack {
                Text("Pin Length:")
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(String(format: "%.0f mm", pinConfig.length))")
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundColor(.primary)
            }
            Slider(value: $pinConfig.length, in: 8.0...30.0, step: 2.0)
            
            HStack {
                Text("Explode View (Separation):")
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(String(format: "%.0f mm", explodeOffset))")
                    .font(.system(.caption, design: .monospaced).bold())
                    .foregroundColor(.blue)
            }
            Slider(value: $explodeOffset, in: 0...60, step: 1.0)
            
            Button(action: onGeneratePins) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Generate Alignment Pins")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }
    
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EXPORT & SLICER BRIDGE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "printer.fill")
                    .foregroundColor(.orange)
            }
            
            // 1-Click Bridge
            Button(action: onOpenInOrcaSlicer) {
                HStack {
                    Image(systemName: "printer.fill")
                    Text("Open in OrcaSlicer / Bambu")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            
            // Individual Exports
            HStack(spacing: 8) {
                Button("Export Part A", action: onExportPartA)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                Button("Export Part B", action: onExportPartB)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
            
            if separatePins != nil {
                Button(action: onExportPins) {
                    HStack {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Export Dowel Pins STL")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            // License state
            if !licenseManager.isPro {
                HStack {
                    Text("Trial exports: \(licenseManager.trialExportsRemaining)/3")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Unlock Pro (€24)") {
                        isLicensePresented = true
                    }
                    .font(.caption2.bold())
                    .foregroundColor(.blue)
                }
                .padding(.top, 4)
            }
        }
    }
}
