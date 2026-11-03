import Foundation

/// Мост в React Native к `VKVideoSplashHaptic` (лежит рядом, в `Handoff/VKVideoSplashHaptic.swift`).
/// В JS модуль называется `VKVideoSplashHapticModule`, его методы вызываются на главной очереди.
@objc(VKVideoSplashHapticModule)
final class VKVideoSplashHapticModule: NSObject {
    @objc static func requiresMainQueueSetup() -> Bool { true }

    /// Хаптик и движок живут на главном потоке.
    @objc var methodQueue: DispatchQueue { .main }

    @objc func prepare() {
        MainActor.assumeIsolated { VKVideoSplashHaptic.shared.prepare() }
    }

    @objc func play() {
        MainActor.assumeIsolated { VKVideoSplashHaptic.shared.play() }
    }
}
