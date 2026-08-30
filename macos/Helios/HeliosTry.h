#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Fängt NSException aus AVFoundation/DAL, die Swift nicht catchen kann.
BOOL HeliosCatch(void (^block)(void), NSError *_Nullable *_Nullable error);

NS_ASSUME_NONNULL_END
