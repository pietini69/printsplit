//
//  LicenseManager.swift
//  PrintSplitMac
//
//  Created by Niko Pietinen on 13.10.2026.
//

import Foundation
import Combine

public class LicenseManager: ObservableObject {
    public static let shared = LicenseManager()
    
    private let keyStorageKey = "PrintSplit_LicenseKey"
    private let trialCountKey = "PrintSplit_TrialExportsUsed"
    private let salt = "PRINTSPLIT_PRO_LIFETIME_SALT_2026_NIKO"
    
    @Published public var isPro: Bool = false
    @Published public var trialExportsRemaining: Int = 3
    @Published public var currentLicenseKey: String = ""
    
    public init() {
        checkStoredLicense()
    }
    
    public func checkStoredLicense() {
        let storedKey = UserDefaults.standard.string(forKey: keyStorageKey) ?? ""
        if validateKey(storedKey) {
            self.isPro = true
            self.currentLicenseKey = storedKey
        } else {
            self.isPro = false
            let used = UserDefaults.standard.integer(forKey: trialCountKey)
            self.trialExportsRemaining = max(0, 3 - used)
        }
    }
    
    /// Validates offline algorithmic license key format: PSPL-XXXX-XXXX-XXXX
    public func validateKey(_ rawKey: String) -> Bool {
        let cleaned = rawKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let parts = cleaned.components(separatedBy: "-")
        guard parts.count == 4, parts[0] == "PSPL" else { return false }
        
        let block1 = parts[1]
        let block2 = parts[2]
        let checksumBlock = parts[3]
        
        guard block1.count == 4, block2.count == 4, checksumBlock.count == 4 else { return false }
        
        let expectedChecksum = calculateChecksum(b1: block1, b2: block2)
        return checksumBlock == expectedChecksum
    }
    
    /// Activates license with provided key
    public func activate(key: String) -> Bool {
        let cleaned = key.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if validateKey(cleaned) {
            UserDefaults.standard.set(cleaned, forKey: keyStorageKey)
            self.isPro = true
            self.currentLicenseKey = cleaned
            return true
        }
        return false
    }
    
    /// Records an export in trial mode
    public func consumeTrialExport() -> Bool {
        if isPro { return true }
        if trialExportsRemaining > 0 {
            trialExportsRemaining -= 1
            let used = UserDefaults.standard.integer(forKey: trialCountKey)
            UserDefaults.standard.set(used + 1, forKey: trialCountKey)
            return true
        }
        return false
    }
    
    private func calculateChecksum(b1: String, b2: String) -> String {
        let combined = "\(b1)\(salt)\(b2)"
        var hash: UInt32 = 5381
        for byte in combined.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt32(byte)
        }
        let hex = String(format: "%04X", hash & 0xFFFF)
        return hex
    }
    
    /// Helper to generate authentic license keys for purchasing customers
    public static func generateKey() -> String {
        let allowed = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let b1 = String((0..<4).map { _ in allowed.randomElement()! })
        let b2 = String((0..<4).map { _ in allowed.randomElement()! })
        let mgr = LicenseManager()
        let b3 = mgr.calculateChecksum(b1: b1, b2: b2)
        return "PSPL-\(b1)-\(b2)-\(b3)"
    }
}
