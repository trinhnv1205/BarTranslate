//
//  ProManager.swift
//  BarTranslate
//
//  Freemium / Pro entitlement management.
//
//  BarTranslate ships as a free app with a 14-day trial that unlocks every
//  premium capability. After the trial, premium features require a one-time
//  Pro unlock. Unlocking is done with an offline license key today and is
//  structured so a StoreKit in-app purchase can drive the same entitlement
//  later (see `setPurchased(_:)`).
//

import Foundation
import Combine
import CryptoKit
import AppKit
import StoreKit

// MARK: - Pro Features

/// Catalog of capabilities reserved for the Pro tier. Anything not listed here
/// is always available on the free tier.
enum ProFeature: String, CaseIterable, Identifiable {
    case unlimitedHistory
    case iCloudSync
    case dataExport
    case prioritySupport

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unlimitedHistory: return "Unlimited history"
        case .iCloudSync:       return "iCloud sync"
        case .dataExport:       return "Export & backup"
        case .prioritySupport:  return "Priority support"
        }
    }

    var subtitle: String {
        switch self {
        case .unlimitedHistory:
            return "Keep up to 200 translations instead of \(ProManager.freeHistoryLimit)."
        case .iCloudSync:
            return "Sync history and favorites across all your Macs."
        case .dataExport:
            return "Export your history to CSV or a full JSON backup."
        case .prioritySupport:
            return "Get faster help and shape the roadmap."
        }
    }

    var systemImage: String {
        switch self {
        case .unlimitedHistory: return "clock.arrow.circlepath"
        case .iCloudSync:       return "icloud"
        case .dataExport:       return "square.and.arrow.up"
        case .prioritySupport:  return "bolt.heart"
        }
    }
}

// MARK: - Pro Manager

/// Central source of truth for the freemium model. Observe `ProManager.shared`
/// to react to entitlement changes from SwiftUI.
final class ProManager: ObservableObject {
    static let shared = ProManager()

    /// Length of the free trial, during which all Pro features are unlocked.
    static let trialDuration: TimeInterval = 14 * 24 * 60 * 60

    /// Maximum number of history items retained on the free tier.
    static let freeHistoryLimit = 50

    // UserDefaults keys
    private let licenseKeyDefault = "proLicenseKey"
    private let firstLaunchDefault = "firstLaunchDate"
    private let purchasedDefault = "proPurchased"

    /// `true` when the user owns Pro (valid license or completed purchase).
    @Published private(set) var isPro: Bool = false
    /// The currently stored license key, if any.
    @Published private(set) var licenseKey: String = ""

    private let defaults = UserDefaults.standard

    private init() {
        if defaults.object(forKey: firstLaunchDefault) == nil {
            defaults.set(Date(), forKey: firstLaunchDefault)
        }
        licenseKey = defaults.string(forKey: licenseKeyDefault) ?? ""
        refreshEntitlements()
    }

    // MARK: Trial

    var firstLaunchDate: Date {
        defaults.object(forKey: firstLaunchDefault) as? Date ?? Date()
    }

    var trialEndDate: Date {
        firstLaunchDate.addingTimeInterval(Self.trialDuration)
    }

    var isTrialActive: Bool {
        Date() < trialEndDate
    }

    var trialDaysRemaining: Int {
        guard isTrialActive else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: trialEndDate).day ?? 0
        return max(0, days + 1)
    }

    // MARK: Entitlements

    /// `true` when the user may use premium features, whether through a purchase
    /// or because the free trial is still running.
    var hasFullAccess: Bool { isPro || isTrialActive }

    /// Convenience for gating an individual feature.
    func isUnlocked(_ feature: ProFeature) -> Bool { hasFullAccess }

    /// Returns `true` when a feature may run. When access is missing, presents a
    /// short paywall prompt and returns `false`. Safe to call from any layer.
    @discardableResult
    func requireFullAccess(for feature: ProFeature) -> Bool {
        if hasFullAccess { return true }
        presentPaywallAlert(for: feature)
        return false
    }

    // MARK: Activation

    /// Activate Pro from a license key. Returns `false` for malformed keys.
    @discardableResult
    func activate(licenseKey rawKey: String) -> Bool {
        let key = LicenseValidator.normalize(rawKey)
        guard LicenseValidator.isValid(key) else { return false }
        defaults.set(key, forKey: licenseKeyDefault)
        defaults.set(true, forKey: purchasedDefault)
        licenseKey = key
        refreshEntitlements()
        return true
    }

    /// Remove the stored license and revoke Pro (e.g. "Deactivate this Mac").
    func deactivate() {
        defaults.removeObject(forKey: licenseKeyDefault)
        defaults.set(false, forKey: purchasedDefault)
        licenseKey = ""
        refreshEntitlements()
    }

    /// Entry point for a StoreKit in-app purchase or restore flow. Marks Pro as
    /// owned without requiring a license key.
    func setPurchased(_ purchased: Bool) {
        defaults.set(purchased, forKey: purchasedDefault)
        refreshEntitlements()
    }

    private func refreshEntitlements() {
        let purchased = defaults.bool(forKey: purchasedDefault)
        // A purchase is honored if it came from a StoreKit flow (empty stored
        // key) or is backed by a still-valid license key.
        let licenseValid = licenseKey.isEmpty || LicenseValidator.isValid(licenseKey)
        let entitled = purchased && licenseValid
        if entitled != isPro { isPro = entitled }
    }

    /// Show a one-time nudge the first launch after the trial has ended. Does
    /// nothing for Pro users, during the trial, or once already shown.
    func presentTrialExpiryIfNeeded() {
        let notifiedKey = "trialExpiryNotified"
        guard !isPro, !isTrialActive, !defaults.bool(forKey: notifiedKey) else { return }
        defaults.set(true, forKey: notifiedKey)

        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Your BarTranslate Pro trial has ended".loc
            alert.informativeText = "You can keep using BarTranslate for free. Upgrade to Pro to restore unlimited history, iCloud sync, and export/backup.".loc
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Upgrade".loc)
            alert.addButton(withTitle: "Maybe Later".loc)
            if alert.runModal() == .alertFirstButtonReturn,
               let url = URL(string: Constants.Links.proPurchase) {
                NSWorkspace.shared.open(url)
            }
        }
    }

    // MARK: Paywall prompt

    private func presentPaywallAlert(for feature: ProFeature) {
        DispatchQueue.main.async {
            let title = feature.title.loc
            let alert = NSAlert()
            if Localization.isVietnamese {
                alert.messageText = "\(title) là tính năng Pro"
                alert.informativeText = "Mở khóa BarTranslate Pro để dùng \(title.lowercased()) và nhiều hơn nữa. Vào Cài đặt ▸ BarTranslate Pro để nâng cấp hoặc nhập mã bản quyền."
            } else {
                alert.messageText = "\(title) is a Pro feature"
                alert.informativeText = "Unlock BarTranslate Pro to use \(title.lowercased()) and more. Open Settings ▸ BarTranslate Pro to upgrade or enter your license key."
            }
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Learn More".loc)
            alert.addButton(withTitle: "Not Now".loc)
            if alert.runModal() == .alertFirstButtonReturn,
               let url = URL(string: Constants.Links.proPurchase) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// MARK: - License Validation

/// Offline license-key validation.
///
/// Keys look like `BART-XXXX-XXXX-CCCC`, where the final group is a checksum
/// derived from the payload. This keeps casual sharing in check for a template;
/// a production build should additionally verify a server signature or a signed
/// StoreKit receipt before granting entitlements.
enum LicenseValidator {
    static let prefix = "BART"
    private static let salt = "BarTranslate.Pro.v1"
    private static let groupLength = 4

    /// Uppercase, trim, and strip stray whitespace from user input.
    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
    }

    static func isValid(_ key: String) -> Bool {
        let parts = key.split(separator: "-").map(String.init)
        guard parts.count == 4,
              parts[0] == prefix,
              parts[1].count == groupLength,
              parts[2].count == groupLength,
              parts[3].count == groupLength else { return false }
        let payload = parts[1] + parts[2]
        return parts[3] == checksum(for: payload)
    }

    /// Deterministic checksum used to both generate and verify keys.
    static func checksum(for payload: String) -> String {
        let digest = SHA256.hash(data: Data((payload + salt).utf8))
        let hex = digest.map { String(format: "%02X", $0) }.joined()
        return String(hex.prefix(groupLength))
    }

    /// Generate a valid license key from an arbitrary seed (used by the vendor
    /// when issuing keys; never shipped to end users).
    static func generate(seed: String) -> String {
        let digest = SHA256.hash(data: Data((seed + salt).utf8))
        let hex = digest.map { String(format: "%02X", $0) }.joined()
        let g1 = String(hex.prefix(groupLength))
        let g2 = String(hex.dropFirst(groupLength).prefix(groupLength))
        return "\(prefix)-\(g1)-\(g2)-\(checksum(for: g1 + g2))"
    }
}

// MARK: - Rating Prompter

/// Requests an App Store rating after the user has gotten value from the app,
/// and at most once per app version. macOS decides whether to actually show
/// the dialog; outside the App Store this is a harmless no-op.
enum RatingPrompter {
    private static let countKey = "ratingTranslationCount"
    private static let lastPromptedVersionKey = "ratingLastPromptedVersion"
    private static let threshold = 15

    /// Call once per successful translation.
    static func recordSuccessfulTranslation() {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: countKey) + 1
        defaults.set(count, forKey: countKey)

        guard count >= threshold else { return }

        let version = Bundle.main.appVersionLong
        guard defaults.string(forKey: lastPromptedVersionKey) != version else { return }

        defaults.set(version, forKey: lastPromptedVersionKey)
        defaults.set(0, forKey: countKey)

        DispatchQueue.main.async {
            SKStoreReviewController.requestReview()
        }
    }
}
