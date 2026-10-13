//
//  ContentView.swift
//  PrintSplitMac
//
//  Created by Niko Pietinen on 13.10.2026.
//

import SwiftUI
import UniformTypeIdentifiers

public struct ContentView: View {
    @State private var originalMesh: MeshModel? = nil
    @State private var partA: MeshModel? = nil
    @State private var partB: MeshModel? = nil
    @State private var separatePins: MeshModel? = nil
    
    @State private var cutPlaneOffset: Float = 90.0
    @State private var cutAxis: PlaneSlicer.CutAxis = .z
    @State private var explodeOffset: Float = 0.0
    @State private var selectedBed: PrinterBed = PrinterPresets.standardPrinters[0]
    @State private var pinConfig: PinConfig = PinConfig()
    @State private var pinPositions: [Vector3] = []
    
    @State private var isLicensePresented: Bool = false
    @State private var statusMessage: String = "Ready. Load an STL file or click 'Demo Model'."
    
    @ObservedObject var licenseManager = LicenseManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar Header
            toolbarHeader
            
            Divider()
            
            // Main workspace
            HSplitView {
                // 3D Viewport
                ZStack {
                    SceneKitViewport(
                        meshA: partA ?? originalMesh,
                        meshB: partB,
                        pinsMesh: separatePins,
                        cutPlaneY: cutPlaneOffset,
                        cutAxis: cutAxis,
                        explodeOffset: explodeOffset,
                        pinPositions: pinPositions,
                        pinRadius: pinConfig.radius,
                        bed: selectedBed
                    )
                    
                    // Floating Status Pill at bottom
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                Text(statusMessage)
                                    .font(.system(.footnote, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                            
                            Spacer()
                        }
                        .padding(14)
                    }
                }
                .frame(minWidth: 650, minHeight: 500)
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers)
                }
                
                // Controls Sidebar
                ControlsSidebarView(
                    currentMesh: $originalMesh,
                    partA: $partA,
                    partB: $partB,
                    separatePins: $separatePins,
                    cutPlaneOffset: $cutPlaneOffset,
                    cutAxis: $cutAxis,
                    explodeOffset: $explodeOffset,
                    selectedBed: $selectedBed,
                    pinConfig: $pinConfig,
                    isLicensePresented: $isLicensePresented,
                    onPerformCut: { performCut() },
                    onGeneratePins: generatePins,
                    onExportPartA: { exportMesh(partA?.centeredOnBed(), name: "Part_A.stl") },
                    onExportPartB: { exportMesh(partB?.centeredOnBed(), name: "Part_B.stl") },
                    onExportPins: {
                        let printable = PinGenerator.makePrintablePins(count: pinPositions.count, config: pinConfig)
                        exportMesh(printable, name: "Dowel_Pins.stl")
                    },
                    onOpenInOrcaSlicer: openInOrcaSlicer
                )
            }
        }
        .frame(minWidth: 1100, minHeight: 880)
        .background(Color(red: 0.95, green: 0.96, blue: 0.97))
        .sheet(isPresented: $isLicensePresented) {
            LicenseModalView(isPresented: $isLicensePresented)
        }
        .onAppear {
            loadDemoModel()
        }
    }
    
    // MARK: - Toolbar Header
    
    private var toolbarHeader: some View {
        HStack(spacing: 14) {
            Image(systemName: "puzzlepiece.extension.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 1) {
                Text("PrintSplit & Pin")
                    .font(.headline.bold())
                    .foregroundColor(.primary)
                Text("Precision 3D Mesh Slicer & Alignment Pin Generator")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: openFileDialog) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.badge.plus")
                    Text("Open STL...")
                }
            }
            .buttonStyle(.bordered)
            
            Button(action: loadDemoModel) {
                HStack(spacing: 6) {
                    Image(systemName: "cube.transparent")
                    Text("Demo Model")
                }
            }
            .buttonStyle(.bordered)
            
            // License status badge
            if licenseManager.isPro {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("PRO")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green.opacity(0.12))
                .cornerRadius(6)
            } else {
                Button(action: { isLicensePresented = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                        Text("TRIAL (\(licenseManager.trialExportsRemaining) left) • Upgrade")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.white)
    }
    
    // MARK: - Actions
    
    private func loadDemoModel() {
        // Creates a tall enclosure block (120 x 80 x 180 mm) resting on the build plate
        let mesh = MeshModel.makeCube(width: 120, depth: 80, height: 180).centeredOnBed()
        self.originalMesh = mesh
        self.partA = nil
        self.partB = nil
        self.separatePins = nil
        self.pinPositions = []
        self.explodeOffset = 0.0
        self.cutPlaneOffset = 90.0 // Cut exactly in the middle (height 180 mm / 2)
        self.statusMessage = "Demo block loaded (120 × 80 × 180 mm). Sits on bed. Click 'Slice' or 'Generate Alignment Pins'."
    }
    
    @discardableResult
    private func performCut() -> (MeshModel, MeshModel)? {
        guard let mesh = originalMesh else { return nil }
        let normal = cutAxis.normal
        let origin = normal * cutPlaneOffset
        
        let result = PlaneSlicer.slice(mesh: mesh, planeOrigin: origin, planeNormal: normal, capHoles: true)
        self.partA = result.partA
        self.partB = result.partB
        self.separatePins = nil
        self.pinPositions = []
        self.explodeOffset = 15.0
        self.statusMessage = "Sliced into Part A (\(result.partA.triangles.count) tris) and Part B (\(result.partB.triangles.count) tris)."
        return (result.partA, result.partB)
    }
    
    private func generatePins() {
        guard let mesh = originalMesh else {
            statusMessage = "No model loaded. Please load an STL or demo model."
            return
        }
        
        let normal = cutAxis.normal
        let origin = normal * cutPlaneOffset
        let cutResult = PlaneSlicer.slice(mesh: mesh, planeOrigin: origin, planeNormal: normal, capHoles: true)
        
        let result = PinGenerator.generatePins(cutResult: cutResult, config: pinConfig)
        self.partA = result.partAWithSockets
        self.partB = result.partBWithSockets
        self.separatePins = result.separatePins
        self.pinPositions = result.pinPositions
        self.explodeOffset = 25.0
        self.statusMessage = "Generated \(result.pinPositions.count) \(pinConfig.type.rawValue) pins with physical sockets (Exploded view active)."
    }
    
    private func exportMesh(_ mesh: MeshModel?, name: String) {
        guard let m = mesh else {
            statusMessage = "Nothing to export for \(name)."
            return
        }
        
        if !licenseManager.consumeTrialExport() {
            isLicensePresented = true
            return
        }
        
        let savePanel = NSSavePanel()
        if let stlType = UTType(filenameExtension: "stl") {
            savePanel.allowedContentTypes = [stlType]
        }
        savePanel.allowsOtherFileTypes = false
        savePanel.canSelectHiddenExtension = false
        savePanel.isExtensionHidden = false
        let defaultName = name.hasSuffix(".stl") ? name : "\(name).stl"
        savePanel.nameFieldStringValue = defaultName
        
        if savePanel.runModal() == .OK, var url = savePanel.url {
            if url.pathExtension.lowercased() != "stl" {
                url = url.appendingPathExtension("stl")
            }
            do {
                try STLParser.export(mesh: m, to: url)
                statusMessage = "Successfully exported \(url.lastPathComponent)!"
            } catch {
                statusMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func findSlicerApplication() -> URL? {
        // 1. Direct path to OrcaSlicer in /Applications
        let directOrca = URL(fileURLWithPath: "/Applications/OrcaSlicer.app")
        if FileManager.default.fileExists(atPath: directOrca.path) {
            return directOrca
        }
        
        // 2. Official OrcaSlicer bundle ID
        if let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.orcaslicer.OrcaSlicer") {
            return app
        }
        
        // 3. Alternative/legacy OrcaSlicer bundle ID
        if let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.softfever.orcaslicer") {
            return app
        }
        
        // 4. Bambu Studio bundle IDs and paths
        let directBambu = URL(fileURLWithPath: "/Applications/Bambu Studio.app")
        if FileManager.default.fileExists(atPath: directBambu.path) {
            return directBambu
        }
        let directBambuAlt = URL(fileURLWithPath: "/Applications/BambuStudio.app")
        if FileManager.default.fileExists(atPath: directBambuAlt.path) {
            return directBambuAlt
        }
        if let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.bambulab.bambu-studio") {
            return app
        }
        
        // 5. PrusaSlicer
        let directPrusa = URL(fileURLWithPath: "/Applications/PrusaSlicer.app")
        if FileManager.default.fileExists(atPath: directPrusa.path) {
            return directPrusa
        }
        if let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.prusa3d.slic3r") {
            return app
        }
        
        return nil
    }
    
    private func openInOrcaSlicer() {
        guard let pA = partA, let pB = partB else {
            performCut()
            openInOrcaSlicer()
            return
        }
        
        if !licenseManager.consumeTrialExport() {
            isLicensePresented = true
            return
        }
        
        let tmpDir = FileManager.default.temporaryDirectory
        let fileA = tmpDir.appendingPathComponent("PrintSplit_PartA.stl")
        let fileB = tmpDir.appendingPathComponent("PrintSplit_PartB.stl")
        
        // Sits both parts flat on build plate (z_min = 0)
        let partBOnBed = pB.centeredOnBed()
        let bBoxB = partBOnBed.boundingBox
        
        let partAOnBed = pA.centeredOnBed()
        let bBoxA = partAOnBed.boundingBox
        
        let partWidthB = bBoxB.size.x
        let partWidthA = bBoxA.size.x
        let partDepthB = bBoxB.size.y
        let partDepthA = bBoxA.size.y
        
        let bedW = selectedBed.width
        let bedD = selectedBed.depth
        let spacing: Float = 16.0
        
        let placedPartB: MeshModel
        let placedPartA: MeshModel
        let placedPins: MeshModel?
        
        // Check if side-by-side in X fits within the printer bed
        let totalSpanX = partWidthB + partWidthA + spacing
        
        if totalSpanX <= (bedW - 16.0) {
            // Arrange along X (left to right)
            let shiftXB = -(partWidthB * 0.5 + spacing * 0.5)
            let shiftXA = +(partWidthA * 0.5 + spacing * 0.5)
            placedPartB = partBOnBed.translated(by: Vector3(shiftXB, 0, 0))
            placedPartA = partAOnBed.translated(by: Vector3(shiftXA, 0, 0))
            
            if let _ = separatePins, !pinPositions.isEmpty {
                let printable = PinGenerator.makePrintablePins(count: pinPositions.count, config: pinConfig)
                let pinShiftY = -(max(partDepthB, partDepthA) * 0.5 + 18.0)
                placedPins = printable.translated(by: Vector3(0, pinShiftY, 0))
            } else {
                placedPins = nil
            }
        } else {
            // Arrange along Y (front to back) - fits much more compactly!
            let shiftYB = -(partDepthB * 0.5 + spacing * 0.5)
            let shiftYA = +(partDepthA * 0.5 + spacing * 0.5)
            placedPartB = partBOnBed.translated(by: Vector3(0, shiftYB, 0))
            placedPartA = partAOnBed.translated(by: Vector3(0, shiftYA, 0))
            
            if let _ = separatePins, !pinPositions.isEmpty {
                let printable = PinGenerator.makePrintablePins(count: pinPositions.count, config: pinConfig)
                let pinShiftX = +(max(partWidthB, partWidthA) * 0.5 + 18.0)
                placedPins = printable.translated(by: Vector3(pinShiftX, 0, 0))
            } else {
                placedPins = nil
            }
        }
        
        do {
            try STLParser.export(mesh: placedPartB, to: fileB)
            try STLParser.export(mesh: placedPartA, to: fileA)
            
            var filesToOpen = [fileB, fileA]
            if let pins = placedPins {
                let filePins = tmpDir.appendingPathComponent("PrintSplit_DowelPins.stl")
                try STLParser.export(mesh: pins, to: filePins)
                filesToOpen.append(filePins)
            }
            
            if let slicerURL = findSlicerApplication() {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                NSWorkspace.shared.open(filesToOpen, withApplicationAt: slicerURL, configuration: config) { _, error in
                    DispatchQueue.main.async {
                        if let err = error {
                            self.statusMessage = "Could not launch slicer: \(err.localizedDescription)"
                        } else {
                            self.statusMessage = "Loaded parts into \(slicerURL.deletingPathExtension().lastPathComponent) (Pre-arranged on plate)!"
                        }
                    }
                }
            } else {
                // Fallback: reveal in Finder instead of opening Xcode!
                NSWorkspace.shared.activateFileViewerSelecting(filesToOpen)
                statusMessage = "OrcaSlicer not detected in /Applications. Exported STLs revealed in Finder."
            }
        } catch {
            statusMessage = "Slicer bridge failed: \(error.localizedDescription)"
        }
    }
    
    private func openFileDialog() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType(filenameExtension: "stl") ?? .data]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            loadFile(url)
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    self.loadFile(url)
                }
            }
        }
        return true
    }
    
    private func loadFile(_ url: URL) {
        do {
            let mesh = try STLParser.load(from: url).centeredOnBed()
            self.originalMesh = mesh
            self.partA = nil
            self.partB = nil
            self.separatePins = nil
            self.pinPositions = []
            self.explodeOffset = 0.0
            let size = mesh.boundingBox.size
            self.cutPlaneOffset = size.z / 2.0
            self.statusMessage = "Loaded \(url.lastPathComponent) (\(mesh.triangles.count) triangles)."
        } catch {
            self.statusMessage = "Failed to load STL: \(error.localizedDescription)"
        }
    }
}
