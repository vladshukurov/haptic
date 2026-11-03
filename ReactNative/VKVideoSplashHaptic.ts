import { NativeModules, Platform } from 'react-native';

/**
 * Хаптик сплеша VK Видео, вариант «Взлёт · 02.11». Только iOS (Core Haptics); на Android вызовы ничего не делают.
 *
 * - `prepare()` — заранее, как можно раньше после старта: холодный движок опаздывает к первому кадру.
 * - `play()` — в момент, когда на экране первый кадр анимации логотипа. Играет один раз за запуск:
 *   повторы анимации, пока грузится приложение, идут без вибрации.
 */
type NativeHaptic = {
  prepare(): void;
  play(): void;
};

const native: NativeHaptic | undefined =
  Platform.OS === 'ios' ? NativeModules.VKVideoSplashHapticModule : undefined;

export const VKVideoSplashHaptic = {
  prepare(): void {
    native?.prepare();
  },
  play(): void {
    native?.play();
  },
};
