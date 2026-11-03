import CoreHaptics
import Foundation

/// Хаптик сплеша VK Видео, вариант «Взлёт · 02.11».
///
/// Одна непрерывная вибрация на первый цикл анимации логотипа (1 с): плавный разгон, пока свет бежит по контуру,
/// один выраженный пик, когда распускается красный неон (650 мс), и звонкий выход — гаснет к ~940 мс вместе со светом.
/// Те же точки лежат в `VKVideoSplash-Vzlet-0211.ahap` — можно взять файл вместо этого кода.
///
/// Использование:
///     VKVideoSplashHaptic.shared.prepare()  // заранее, при старте приложения: холодный движок опаздывает
///     VKVideoSplashHaptic.shared.play()     // в момент, когда на экране первый кадр анимации
///
/// Хаптик играет один раз. Если загрузка дольше и анимация повторяется, повторы идут без вибрации.
@MainActor
final class VKVideoSplashHaptic {
    static let shared = VKVideoSplashHaptic()

    private var engine: CHHapticEngine?
    /// Плеер живёт, пока играет паттерн.
    private var player: CHHapticPatternPlayer?
    private var hasPlayed = false
    private lazy var pattern: CHHapticPattern? = try? VKVideoSplashPattern.make()

    func prepare() {
        guard engine == nil, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        guard let engine = try? CHHapticEngine() else { return }
        engine.playsHapticsOnly = true
        engine.resetHandler = { [weak engine] in try? engine?.start() }
        try? engine.start()
        self.engine = engine
        _ = pattern
    }

    func play() {
        guard !hasPlayed else { return }
        hasPlayed = true
        prepare()
        guard let engine, let pattern else { return }
        try? engine.start()
        guard let player = try? engine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
        self.player = player
        // Сплеш больше не повторит хаптик: движок можно отпустить, как только паттерн доиграет.
        engine.notifyWhenPlayersFinished { _ in .stopEngine }
    }
}

/// Паттерн «Взлёта»: одно непрерывное событие и две кривые по 16 точек — столько Core Haptics берёт на кривую.
enum VKVideoSplashPattern {
    /// От первого кадра анимации, с. Ощущается с ~20 до ~940 мс, дальше остаток меньше 3%.
    static let duration = 1.01

    /// Сила 0…1. Пик 0.62 на 650 мс, когда распускается красный неон.
    static let intensity: [(time: Double, value: Float)] = [
        (0, 0.02), (0.042, 0.04), (0.142, 0.16), (0.233, 0.25),
        (0.475, 0.40), (0.517, 0.45), (0.6, 0.59), (0.625, 0.62),
        (0.65, 0.62), (0.683, 0.60), (0.717, 0.55), (0.75, 0.46),
        (0.833, 0.22), (0.892, 0.09), (0.942, 0.03), (1.01, 0.00),
    ]

    /// Звонкость 0…1: тёплый разгон ~0.28–0.41, на неоне 0.48, к концу темнеет до 0.32.
    /// Первые ~100 мс светлее (0.73 → 0.42) — короткое мерцание, когда свет появляется в углу, но сила там ещё почти ноль.
    static let sharpness: [(time: Double, value: Float)] = [
        (0, 0.73), (0.042, 0.63), (0.117, 0.42), (0.142, 0.36),
        (0.167, 0.31), (0.2, 0.28), (0.225, 0.28), (0.258, 0.29),
        (0.408, 0.40), (0.442, 0.41), (0.533, 0.40), (0.625, 0.47),
        (0.667, 0.48), (0.742, 0.46), (0.9, 0.36), (1.01, 0.32),
    ]

    static func make() throws -> CHHapticPattern {
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

    private static func curve(_ id: CHHapticDynamicParameter.ID, _ points: [(time: Double, value: Float)],
                              _ map: (Float) -> Float) -> CHHapticParameterCurve {
        CHHapticParameterCurve(parameterID: id,
                               controlPoints: points.map { .init(relativeTime: $0.time, value: map($0.value)) },
                               relativeTime: 0)
    }
}
