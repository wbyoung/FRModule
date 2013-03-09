// 
// Copyright (c) 2013 Whitney Young
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// 

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

#import "FRBlockDrawingModule.h"

static void *kAssociatedViewKey = &(NSUInteger){0};

@interface FRLayerBlockDrawingModule : FRModule
@end

@implementation FRBlockDrawingModule

- (void (^)(UIView *, CGRect))drawingBlock {
	return objc_getAssociatedObject(self, @selector(drawingBlock));
}

- (void)setDrawingBlock:(void (^)(UIView *, CGRect))drawingBlock {
	// unfortunately we can't just define a drawRect: method here because the layer seems to do some calculation during
	// the first draw (or during initialization) to figure out whether it needs to call the view's drawRect: method. the
	// result of this seems to be cached, so it won't ever call drawRect: if it didn't exist to start with. therefore,
	// we just extend the layer instance with another module to handle the drawing in drawInContext:. that module simply
	// looks back to the view for a drawing block and uses that for drawing.
	id layer = [(id)self layer];
	[layer setNeedsDisplay];
	[FRLayerBlockDrawingModule extendInstance:layer];
	objc_setAssociatedObject(layer, kAssociatedViewKey, self, OBJC_ASSOCIATION_ASSIGN);
	objc_setAssociatedObject(self, @selector(drawingBlock), drawingBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setHighlighted:(BOOL)highlighted {
	// calling super is not possible (it's a compile time value), but we can find the the imp for that method by looking
	// it up from a value that we stored during the process of mixing in this method. the lookup requires the address of
	// the currently executing IMP which we get from the module.
	void (*superIMP)(id, SEL, BOOL) = (void *)[FRBlockDrawingModule unextendedMethodForSelector:_cmd object:self];
	superIMP(self, _cmd, highlighted);
	
	// redraw every time the highlighted state changes
	id layer = [(id)self layer];
	[layer setNeedsDisplay];
}

@end

@implementation FRLayerBlockDrawingModule

- (void)drawInContext:(CGContextRef)ctx {
	id view = objc_getAssociatedObject(self, kAssociatedViewKey);
	void (^drawingBlock)(UIView *, CGRect) = [view drawingBlock];
	if (drawingBlock) {
		UIGraphicsPushContext(ctx);
		drawingBlock(view, [(id)self bounds]);
		UIGraphicsPopContext();
	}
}

@end
