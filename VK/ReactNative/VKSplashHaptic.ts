import { NativeModules, Platform } from 'react-native';

/**
 * Хаптик сплеша ВК. Только iOS (Core Haptics); на Android вызовы ничего не делают.
 *
 * - `setVariant()` — какой вариант играть: `'main'` — «Основной», `'peakOnly'` — «Только пик».
 * - `prepare()` — заранее, как можно раньше после старта: холодный движок опаздывает.
 * - `splashDidStart()` — в момент, когда на экране первый кадр анимации сплеша.
 * - `appDidLoad()` — в момент, когда приложение загрузилось.
 *
 * Оба события вызываются всегда, а что играть, решает вариант. Хаптик играет один раз за запуск.
 */
export type VKSplashVariant = 'main' | 'peakOnly';

type NativeHaptic = {
  setVariant(variant: VKSplashVariant): void;
  prepare(): void;
  splashDidStart(): void;
  appDidLoad(): void;
};

const native: NativeHaptic | undefined =
  Platform.OS === 'ios' ? NativeModules.VKSplashHapticModule : undefined;

export const VKSplashHaptic = {
  setVariant(variant: VKSplashVariant): void {
    native?.setVariant(variant);
  },
  prepare(): void {
    native?.prepare();
  },
  splashDidStart(): void {
    native?.splashDidStart();
  },
  appDidLoad(): void {
    native?.appDidLoad();
  },
};
