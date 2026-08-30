#import "HeliosTry.h"

BOOL HeliosCatch(void (^block)(void), NSError *_Nullable *_Nullable error) {
    @try {
        block();
        return YES;
    } @catch (NSException *ex) {
        if (error != NULL) {
            NSMutableDictionary *info = [NSMutableDictionary dictionary];
            if (ex.reason) {
                info[NSLocalizedDescriptionKey] = ex.reason;
            } else {
                info[NSLocalizedDescriptionKey] = ex.name;
            }
            *error = [NSError errorWithDomain:@"Helios" code:1 userInfo:info];
        }
        return NO;
    }
}
