#import <React/RCTBridgeModule.h>

// Регистрирует Swift-класс `VKVideoSplashHapticModule` как нативный модуль React Native.
@interface RCT_EXTERN_MODULE(VKVideoSplashHapticModule, NSObject)
RCT_EXTERN_METHOD(prepare)
RCT_EXTERN_METHOD(play)
@end
