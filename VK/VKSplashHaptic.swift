import CoreHaptics
import Foundation

/// Хаптик сплеша ВК, два варианта на выбор:
/// - «Основной» — одна непрерывная вибрация с первого кадра анимации: набирается, пока свет обегает плитку,
///   пик 0.55 на 717 мс, когда плитку заливает светом, и гаснет вместе с ореолом к ~1,15 с;
/// - «Только пик» — пока приложение грузится, тишина; в момент загрузки — один мягкий пик 0.40 через 450 мс,
///   гаснет к ~830 мс после загрузки.
/// Те же точки лежат в `VKSplash-Main.ahap` и `VKSplash-PeakOnly.ahap`.
///
/// Использование:
///     VKSplashHaptic.shared.variant = .main      // или .peakOnly
///     VKSplashHaptic.shared.prepare()            // заранее, при старте приложения: холодный движок опаздывает
///     VKSplashHaptic.shared.splashDidStart()     // в момент, когда на экране первый кадр анимации сплеша
///     VKSplashHaptic.shared.appDidLoad()         // в момент, когда приложение загрузилось
///
/// Оба события вызываются всегда, а что играть, решает `variant`. Хаптик играет один раз за запуск.
@MainActor
final class VKSplashHaptic {
    enum Variant {
        /// «Основной»: с первого кадра анимации.
        case main
        /// «Только пик»: в момент, когда приложение загрузилось.
        case peakOnly
    }

    static let shared = VKSplashHaptic()

    var variant = Variant.main

    private var engine: CHHapticEngine?
    /// Плеер живёт, пока играет паттерн.
    private var player: CHHapticPatternPlayer?
    private var hasPlayed = false

    func prepare() {
        guard engine == nil, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        guard let engine = try? CHHapticEngine() else { return }
        engine.playsHapticsOnly = true
        engine.resetHandler = { [weak engine] in try? engine?.start() }
        try? engine.start()
        self.engine = engine
    }

    func splashDidStart() {
        if variant == .main { play(.main) }
    }

    func appDidLoad() {
        if variant == .peakOnly { play(.peakOnly) }
    }

    private func play(_ variant: Variant) {
        guard !hasPlayed else { return }
        hasPlayed = true
        prepare()
        guard let engine, let pattern = try? VKSplashPattern.make(variant) else { return }
        try? engine.start()
        guard let player = try? engine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
        self.player = player
        // Больше хаптик не играет: движок можно отпустить, как только паттерн доиграет.
        engine.notifyWhenPlayersFinished { _ in .stopEngine }
    }
}

/// Паттерны ВК: у каждого одно непрерывное событие и две кривые, не больше 16 точек — столько Core Haptics берёт
/// на кривую.
enum VKSplashPattern {
    typealias Curve = [(time: Double, value: Float)]

    /// «Основной», от первого кадра анимации, с. Ощущается с ~20 мс до ~1,15 с; к 1,275 с сила доходит до нуля.
    static let mainDuration = 1.275

    /// Сила 0…1. Пик 0.55 на 717 мс, когда плитку заливает светом.
    static let mainIntensity: Curve = [
        (0, 0.00), (0.017, 0.01), (0.042, 0.08), (0.058, 0.10),
        (0.392, 0.21), (0.492, 0.25), (0.533, 0.30), (0.65, 0.51),
        (0.717, 0.55), (0.792, 0.50), (0.917, 0.29), (1.05, 0.12),
        (1.108, 0.06), (1.167, 0.02), (1.275, 0.00),
    ]

    /// Звонкость 0…1: светлая, 0.50–0.59, к концу темнеет до 0.39. В первые миллисекунды и после 1,24 с она
    /// уходит к 0.30 и ниже, но сила там почти ноль — этого не слышно.
    static let mainSharpness: Curve = [
        (0, 0.30), (0.008, 0.56), (0.117, 0.50), (0.367, 0.57),
        (0.533, 0.51), (0.733, 0.59), (1.067, 0.48), (1.183, 0.39),
        (1.242, 0.30), (1.258, 0.22), (1.267, 0.15), (1.275, 0.05),
    ]

    /// «Только пик», от момента загрузки, с. Ощущается с ~100 до ~830 мс.
    static let peakDuration = 0.95

    /// Сила 0…1. Мягкий подъём за 450 мс до 0.40 и плавный спад за 500 мс.
    static let peakIntensity: Curve = [
        (0, 0.00), (0.058, 0.01), (0.108, 0.04), (0.167, 0.11),
        (0.275, 0.28), (0.325, 0.35), (0.358, 0.38), (0.383, 0.39),
        (0.45, 0.40), (0.5, 0.39), (0.55, 0.35), (0.633, 0.27),
        (0.758, 0.10), (0.817, 0.04), (0.875, 0.01), (0.95, 0.00),
    ]

    /// Звонкость 0…1: светлеет к вершине (0.35 → 0.50) и темнеет на спаде обратно к 0.35. Крайние 0.30 приходятся
    /// на нулевую силу.
    static let peakSharpness: Curve = [
        (0, 0.30), (0.008, 0.30), (0.017, 0.35), (0.075, 0.36),
        (0.125, 0.37), (0.283, 0.46), (0.342, 0.49), (0.392, 0.50),
        (0.45, 0.50), (0.517, 0.50), (0.575, 0.48), (0.808, 0.37),
        (0.867, 0.36), (0.933, 0.35), (0.942, 0.30), (0.95, 0.30),
    ]

    static func make(_ variant: VKSplashHaptic.Variant) throws -> CHHapticPattern {
        switch variant {
        case .main: try make(duration: mainDuration, intensity: mainIntensity, sharpness: mainSharpness)
        case .peakOnly: try make(duration: peakDuration, intensity: peakIntensity, sharpness: peakSharpness)
        }
    }

    private static func make(duration: Double, intensity: Curve, sharpness: Curve) throws -> CHHapticPattern {
        // Базовые значения нейтральные, форму задают кривые: сила — множитель к 1, звонкость — прибавка к 0.5.
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
        ], relativeTime: 0, duration: duration)
        return try CHHapticPattern(events: [event], parameterCurves: [
            curve(.hapticIntensityControl, intensity) { $0 },
            curve(.hapticSharpnessControl, sharpness) { $0 - 0.5 },
        ])
    }

    private static func curve(_ id: CHHapticDynamicParameter.ID, _ points: Curve,
                              _ map: (Float) -> Float) -> CHHapticParameterCurve {
        CHHapticParameterCurve(parameterID: id,
                               controlPoints: points.map { .init(relativeTime: $0.time, value: map($0.value)) },
                               relativeTime: 0)
    }
}
