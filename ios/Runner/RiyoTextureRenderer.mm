#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#include "video_engine.h"

@interface RiyoTextureRenderer : NSObject <FlutterTexture>
- (instancetype)initWithPlayer:(void*)player;
- (CVPixelBufferRef)copyPixelBuffer;
@end

@implementation RiyoTextureRenderer {
    void* _player;
}

- (instancetype)initWithPlayer:(void*)player {
    self = [super init];
    if (self) {
        _player = player;
    }
    return self;
}

- (CVPixelBufferRef)copyPixelBuffer {
    // Implement logic to copy frame from C++ to iOS CVPixelBuffer
    return nil;
}

@end
