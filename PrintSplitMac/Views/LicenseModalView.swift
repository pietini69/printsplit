//
//  LicenseModalView.swift
//  PrintSplitMac
//
//  Created by Niko Pietinen on 13.10.2026.
//

import SwiftUI

public struct LicenseModalView: View {
    @ObservedObject var licenseManager = LicenseManager.shared
    @Binding var isPresented: Bool
    
    @State private var inputKey: String = ""
    @State private var errorMessage: String? = nil
    @State private var isSuccess: Bool = false
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "puzzlepiece.extension.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("PrintSplit & Pin Pro")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    Text("Lifetime Commercial License • €24")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Features
            VStack(alignment: .leading, spacing: 10) {
                FeatureRow(icon: "bolt.fill", text: "Unlimited high-speed 3D model splitting")
                FeatureRow(icon: "pin.fill", text: "Automated dowel pins & anti-twist hexagon sockets")
                FeatureRow(icon: "slider.horizontal.3", text: "Micro-tolerance clearance control for perfect fit")
                FeatureRow(icon: "printer.fill", text: "1-Click direct bridge to OrcaSlicer & Bambu Studio")
                FeatureRow(icon: "network.slash", text: "100% Offline algorithmic license (Zero cloud / subscriptions)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(red: 0.96, green: 0.97, blue: 0.98))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            
            // Purchase Button (PayPal Direct)
            VStack(spacing: 6) {
                Link(destination: URL(string: "https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=niko.pietinen%40gmail.com&item_name=PrintSplit+Pro+Lifetime+License&amount=24.00&currency_code=EUR&no_shipping=1")!) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                        Text("Buy Pro License via PayPal (€24)")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                Text("Your license key will be delivered automatically to your PayPal email.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // License Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Already have a license key?")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("PSPL-XXXX-XXXX-XXXX", text: $inputKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    
                    Button("Activate") {
                        if licenseManager.activate(key: inputKey) {
                            isSuccess = true
                            errorMessage = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                isPresented = false
                            }
                        } else {
                            errorMessage = "Invalid license key format. Please check and try again."
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                
                if let err = errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                if isSuccess {
                    Text("✓ PrintSplit Pro activated successfully!")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }
        }
        .padding(26)
        .frame(width: 480)
        .background(Color.white)
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.footnote)
                .foregroundColor(.primary)
        }
    }
}
