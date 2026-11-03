import Foundation

/// Мост в React Native к `VKSplashHaptic` (лежит рядом, в `VK/VKSplashHaptic.swift`).
/// В JS модуль называется `VKSplashHapticModule`, его методы вызываются на главной очереди.
@objc(VKSplashHapticModule)
final class VKSplashHapticModule: NSObject {
    @objc static func requiresMainQueueSetup() -> Bool { true }

    /// Хаптик и движок живут на главном потоке.
    @objc var methodQueue: DispatchQueue { .main }

    /// `"main"` — «Основной», `"peakOnly"` — «Только пик».
    @objc func setVariant(_ variant: String) {
        MainActor.assumeIsolated { VKSplashHaptic.shared.variant = variant == "peakOnly" ? .peakOnly : .main }
    }

    @objc func prepare() {
        MainActor.assumeIsolated { VKSplashHaptic.shared.prepare() }
    }

    @objc func splashDidStart() {
        MainActor.assumeIsolated { VKSplashHaptic.shared.splashDidStart() }
    }

    @objc func appDidLoad() {
        MainActor.assumeIsolated { VKSplashHaptic.shared.appDidLoad() }
    }
}
