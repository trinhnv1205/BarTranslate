//
//  ProView.swift
//  BarTranslate
//
//  Pro upgrade UI (settings card + license activation) and the first-run
//  onboarding window.
//

import SwiftUI
import AppKit

// MARK: - Pro Settings Card

/// A compact "BarTranslate Pro" card shown at the top of the Settings tab.
/// Reflects trial / Pro state and hosts license activation.
struct ProSettingsCard: View {
    @ObservedObject private var pro = ProManager.shared
    @State private var showingActivation = false
    @State private var showingDeactivateConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: pro.isPro ? "checkmark.seal.fill" : "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 1) {
                    Text(headline)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(subline)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
            }

            if !pro.isPro {
                HStack(spacing: 8) {
                    Link(destination: URL(string: Constants.Links.proPurchase)!) {
                        Text("Upgrade")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.white))
                    }
                    .buttonStyle(.plain)

                    Button("Enter license key") { showingActivation = true }
                        .font(.system(size: 12, weight: .medium))
                        .buttonStyle(.plain)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().stroke(Color.white.opacity(0.7), lineWidth: 1))
                }
            } else if !pro.licenseKey.isEmpty {
                Button("Deactivate this Mac") { showingDeactivateConfirm = true }
                    .font(.system(size: 11, weight: .medium))
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.9))
                    .help("Remove the license from this Mac so it can be used on another.")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: pro.isPro
                            ? [Color(red: 0.20, green: 0.55, blue: 0.40), Color(red: 0.13, green: 0.42, blue: 0.32)]
                            : [Color(red: 0.36, green: 0.32, blue: 0.86), Color(red: 0.55, green: 0.30, blue: 0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .sheet(isPresented: $showingActivation) {
            LicenseActivationView()
        }
        .confirmationDialog(
            "Deactivate BarTranslate Pro on this Mac?",
            isPresented: $showingDeactivateConfirm,
            titleVisibility: .visible
        ) {
            Button("Deactivate", role: .destructive) { pro.deactivate() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your license key will be removed from this Mac. You can re-activate it here at any time.")
        }
    }

    private var headline: String {
        pro.isPro ? "BarTranslate Pro" : "Upgrade to Pro"
    }

    private var subline: String {
        if pro.isPro { return "Thank you for your support!" }
        if pro.isTrialActive {
            let days = pro.trialDaysRemaining
            return "Trial active · \(days) day\(days == 1 ? "" : "s") left"
        }
        return "Unlock unlimited history, iCloud sync & export"
    }
}

// MARK: - License Activation Sheet

struct LicenseActivationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var pro = ProManager.shared
    @State private var keyInput = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Activate BarTranslate Pro")
                .font(.system(size: 15, weight: .semibold))

            Text("Enter the license key from your purchase confirmation email.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            TextField("BART-XXXX-XXXX-XXXX", text: $keyInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))
                .onSubmit(activate)

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
            }

            HStack {
                Link("Buy a license", destination: URL(string: Constants.Links.proPurchase)!)
                    .font(.system(size: 11))
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Activate", action: activate)
                    .keyboardShortcut(.defaultAction)
                    .disabled(keyInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(18)
        .frame(width: 360)
    }

    private func activate() {
        if pro.activate(licenseKey: keyInput) {
            errorMessage = nil
            dismiss()
        } else {
            errorMessage = "That license key is not valid. Check for typos and try again."
        }
    }
}

// MARK: - Onboarding

/// First-run welcome experience presented in its own window.
struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @State private var targetLang: String = UserDefaults.standard.string(forKey: "lastTargetLang") ?? "vi"

    /// A small, curated set of common target languages shown during onboarding.
    private let languages: [(code: String, name: String)] = [
        ("vi", "Tiếng Việt"), ("en", "English"), ("ja", "日本語"),
        ("ko", "한국어"), ("zh-CN", "中文 (简体)"), ("zh-TW", "中文 (繁體)"),
        ("fr", "Français"), ("de", "Deutsch"), ("es", "Español"),
        ("pt", "Português"), ("ru", "Русский"), ("th", "ไทย")
    ]

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "character.bubble",
            title: "Translate from your menu bar",
            detail: "BarTranslate keeps Google Translate one click — or one hotkey — away, anywhere on your Mac."
        ),
        OnboardingPage(
            systemImage: "keyboard",
            title: "Fast by default",
            detail: "Open with ⌥; , translate the clipboard instantly, and auto-paste results back into the app you were using."
        ),
        OnboardingPage(
            systemImage: "rectangle.stack",
            title: "Learn as you go",
            detail: "Save translations to history and review them as spaced-repetition flashcards to build vocabulary."
        ),
        OnboardingPage(
            systemImage: "sparkles",
            title: "Try Pro free for 14 days",
            detail: "Every premium feature — unlimited history, iCloud sync and CSV export — is unlocked during your trial."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 16) {
                Image(systemName: pages[page].systemImage)
                    .font(.system(size: 46, weight: .light))
                    .foregroundStyle(Color.accentColor)
                    .frame(height: 60)
                Text(pages[page].title)
                    .font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)
                Text(pages[page].detail)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)

                if page == pages.count - 1 {
                    HStack(spacing: 6) {
                        Text("Translate into")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Picker("", selection: $targetLang) {
                            ForEach(languages, id: \.code) { lang in
                                Text(lang.name).tag(lang.code)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 150)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 24)
            Spacer(minLength: 0)

            HStack(spacing: 6) {
                ForEach(pages.indices, id: \.self) { index in
                    Circle()
                        .fill(index == page ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 16)

            Button(action: advance) {
                Text(page == pages.count - 1 ? "Get Started" : "Continue")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 420, height: 380)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.2)) { page += 1 }
        } else {
            // Persist the chosen target language and reload so the first
            // translation already uses it.
            UserDefaults.standard.set(targetLang, forKey: "lastTargetLang")
            AppDelegate.instance?.BT.reloadWebView(for: .google)
            onFinish()
        }
    }
}

private struct OnboardingPage {
    let systemImage: String
    let title: String
    let detail: String
}

// MARK: - Onboarding Window Controller

/// Presents `OnboardingView` once, the first time the app launches.
final class OnboardingController {
    static let shared = OnboardingController()
    private var window: NSWindow?
    private let completedKey = "hasCompletedOnboarding"

    /// Shows onboarding on first launch only.
    func presentIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: completedKey) else { return }
        present()
    }

    func present() {
        guard window == nil else {
            window?.makeKeyAndOrderFront(nil)
            return
        }

        let view = OnboardingView { [weak self] in self?.finish() }
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.title = "Welcome to BarTranslate"
        window.center()
        window.isReleasedWhenClosed = false
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: completedKey)
        window?.close()
        window = nil
    }
}
