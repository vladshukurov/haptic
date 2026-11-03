#import <React/RCTBridgeModule.h>

// Регистрирует Swift-класс `VKSplashHapticModule` как нативный модуль React Native.
@interface RCT_EXTERN_MODULE(VKSplashHapticModule, NSObject)
RCT_EXTERN_METHOD(setVariant:(NSString *)variant)
RCT_EXTERN_METHOD(prepare)
RCT_EXTERN_METHOD(splashDidStart)
RCT_EXTERN_METHOD(appDidLoad)
@end
