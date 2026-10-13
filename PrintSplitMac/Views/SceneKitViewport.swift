//
//  SceneKitViewport.swift
//  PrintSplitMac
//
//  Created by Niko Pietinen on 13.10.2026.
//

import SwiftUI
import SceneKit

public struct SceneKitViewport: NSViewRepresentable {
    public var meshA: MeshModel?
    public var meshB: MeshModel?
    public var pinsMesh: MeshModel?
    public var cutPlaneY: Float
    public var cutAxis: PlaneSlicer.CutAxis
    public var explodeOffset: Float
    public var pinPositions: [Vector3]
    public var pinRadius: Float
    public var bed: PrinterBed
    
    public init(
        meshA: MeshModel?,
        meshB: MeshModel?,
        pinsMesh: MeshModel? = nil,
        cutPlaneY: Float,
        cutAxis: PlaneSlicer.CutAxis,
        explodeOffset: Float = 0.0,
        pinPositions: [Vector3] = [],
        pinRadius: Float = 3.5,
        bed: PrinterBed
    ) {
        self.meshA = meshA
        self.meshB = meshB
        self.pinsMesh = pinsMesh
        self.cutPlaneY = cutPlaneY
        self.cutAxis = cutAxis
        self.explodeOffset = explodeOffset
        self.pinPositions = pinPositions
        self.pinRadius = pinRadius
        self.bed = bed
    }
    
    public func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = SCNScene()
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        // Crisp CAD studio off-white background
        scnView.backgroundColor = NSColor(red: 0.93, green: 0.94, blue: 0.96, alpha: 1.0)
        
        // Lighting
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = NSColor(white: 0.65, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        let dirLight = SCNNode()
        dirLight.light = SCNLight()
        dirLight.light?.type = .directional
        dirLight.light?.color = NSColor(white: 0.85, alpha: 1.0)
        dirLight.position = SCNVector3(120, 240, 180)
        dirLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
        scene.rootNode.addChildNode(dirLight)
        
        // Fill light
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .directional
        fillLight.light?.color = NSColor(white: 0.45, alpha: 1.0)
        fillLight.position = SCNVector3(-140, 140, -120)
        fillLight.eulerAngles = SCNVector3(-Float.pi / 6, -Float.pi / 3, 0)
        scene.rootNode.addChildNode(fillLight)
        
        // Camera: pulled back and positioned higher so bed + large models fit comfortably with room
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 1.0
        cameraNode.camera?.zFar = 3000.0
        cameraNode.position = SCNVector3(0, 260, 480)
        cameraNode.eulerAngles = SCNVector3(-0.46, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        
        updateScene(scene)
        return scnView
    }
    
    public func updateNSView(_ scnView: SCNView, context: Context) {
        guard let scene = scnView.scene else { return }
        updateScene(scene)
    }
    
    private func updateScene(_ scene: SCNScene) {
        // Remove existing dynamic nodes
        scene.rootNode.childNodes.filter { $0.name?.starts(with: "dyn_") == true }.forEach { $0.removeFromParentNode() }
        
        // 1. Printer Bed Boundary (Clean satin light-gray PEI sheet)
        let bedBox = SCNBox(width: CGFloat(bed.width), height: 1.5, length: CGFloat(bed.depth), chamferRadius: 1)
        bedBox.firstMaterial?.diffuse.contents = NSColor(red: 0.82, green: 0.84, blue: 0.88, alpha: 1.0)
        bedBox.firstMaterial?.isDoubleSided = true
        let bedNode = SCNNode(geometry: bedBox)
        bedNode.name = "dyn_bed"
        bedNode.position = SCNVector3(0, -0.75, 0)
        scene.rootNode.addChildNode(bedNode)
        
        // Bed border outline
        let borderBox = SCNBox(width: CGFloat(bed.width + 2), height: 0.5, length: CGFloat(bed.depth + 2), chamferRadius: 0)
        borderBox.firstMaterial?.diffuse.contents = NSColor(red: 0.65, green: 0.68, blue: 0.74, alpha: 1.0)
        let borderNode = SCNNode(geometry: borderBox)
        borderNode.name = "dyn_bed_border"
        borderNode.position = SCNVector3(0, -1.2, 0)
        scene.rootNode.addChildNode(borderNode)
        
        // 2. Part A (Vibrant CAD Royal Blue, translated by explodeOffset along cut normal)
        if let mA = meshA, !mA.triangles.isEmpty {
            let blueColor = NSColor(red: 0.08, green: 0.52, blue: 0.95, alpha: 1.0)
            let nodeA = SCNNode(geometry: mA.createSCNGeometry(color: blueColor))
            nodeA.name = "dyn_partA"
            switch cutAxis {
            case .z:
                nodeA.position = SCNVector3(0, explodeOffset, 0)
            case .y:
                nodeA.position = SCNVector3(0, 0, -explodeOffset)
            case .x:
                nodeA.position = SCNVector3(explodeOffset, 0, 0)
            }
            scene.rootNode.addChildNode(nodeA)
        }
        
        // 3. Part B (Warm CAD Tangerine/Orange)
        if let mB = meshB, !mB.triangles.isEmpty {
            let orangeColor = NSColor(red: 0.98, green: 0.48, blue: 0.12, alpha: 1.0)
            let nodeB = SCNNode(geometry: mB.createSCNGeometry(color: orangeColor))
            nodeB.name = "dyn_partB"
            scene.rootNode.addChildNode(nodeB)
        }
        
        // 4. Dowel Pins 3D Mesh (Glowing emerald green solid dowel pins)
        if let pMesh = pinsMesh, !pMesh.triangles.isEmpty {
            let pinColor = NSColor(red: 0.10, green: 0.85, blue: 0.35, alpha: 1.0)
            let pinGeo = pMesh.createSCNGeometry(color: pinColor)
            pinGeo.firstMaterial?.specular.contents = NSColor.white
            pinGeo.firstMaterial?.shininess = 60.0
            let pinsNode = SCNNode(geometry: pinGeo)
            pinsNode.name = "dyn_pins_mesh"
            scene.rootNode.addChildNode(pinsNode)
        }
        
        
        // 6. Cut Plane Indicator (Show only when not exploded, to prevent visual clutter)
        if explodeOffset < 2.0 && (meshB == nil || pinsMesh == nil) {
            let planeSize: CGFloat = CGFloat(max(bed.width, bed.depth) * 1.15)
            let cutPlaneGeo = SCNPlane(width: planeSize, height: planeSize)
            cutPlaneGeo.firstMaterial?.diffuse.contents = NSColor(red: 0.0, green: 0.65, blue: 0.90, alpha: 0.28)
            cutPlaneGeo.firstMaterial?.isDoubleSided = true
            let cutNode = SCNNode(geometry: cutPlaneGeo)
            cutNode.name = "dyn_cutplane"
            
            switch cutAxis {
            case .z:
                cutNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
                cutNode.position = SCNVector3(0, cutPlaneY, 0)
            case .y:
                cutNode.eulerAngles = SCNVector3(0, 0, 0)
                cutNode.position = SCNVector3(0, 0, -cutPlaneY)
            case .x:
                cutNode.eulerAngles = SCNVector3(0, Float.pi / 2, 0)
                cutNode.position = SCNVector3(cutPlaneY, 0, 0)
            }
            scene.rootNode.addChildNode(cutNode)
        }
    }
}
