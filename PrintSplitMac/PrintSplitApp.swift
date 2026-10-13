//
//  PrintSplitApp.swift
//  PrintSplitMac
//
//  Created by Niko Pietinen on 13.10.2026.
//

import SwiftUI

@main
struct PrintSplitApp: App {
    var body: some Scene {
        WindowGroup("PrintSplit & Pin — 3D Model Slicer & Dowel Pin Generator") {
            ContentView()
                .preferredColorScheme(.light)
        }
        .defaultSize(width: 1340, height: 980)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .appInfo) {
                Button("About PrintSplit & Pin") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.applicationName: "PrintSplit & Pin",
                            NSApplication.AboutPanelOptionKey.version: "1.0",
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(string: "Crafted for 3D printing makers by Niko Pietinen.")
                        ]
                    )
                }
            }
        }
    }
}
