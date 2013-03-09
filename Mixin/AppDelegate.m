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

#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"
#import "FRBlockDrawingModule.h"

static void FRDrawRoundedGradientBackground(CGFloat hue, CGFloat brightness, CGRect rect);

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
	self.window.rootViewController = [[UIViewController alloc] init];
	
	// create a button, mix in block drawing, and set a drawing block
	CGRect buttonFrame = CGRectMake(0, 0, 200, 80);
	buttonFrame.origin.y = self.window.bounds.size.height - buttonFrame.size.height - 120;
	buttonFrame.origin.x += self.window.bounds.size.width / 2.0 - buttonFrame.size.width / 2.0;
	buttonFrame = CGRectIntegral(buttonFrame);
	UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
	[FRBlockDrawingModule extendInstance:button];
	[(id)button setDrawingBlock:^(UIView *view, CGRect rect) {
		UIButton *button = (id)view;
		if ([button isTracking] && [button isTouchInside]) {
			FRDrawRoundedGradientBackground(0.59, 0.8, button.bounds);
		}
		else {
			FRDrawRoundedGradientBackground(0.59, 1, button.bounds);
		}
	}];
	[button setTitle:NSLocalizedString(@"Mixin Example", nil) forState:UIControlStateNormal];
	
	// create a label with some text so people know to run the tests and look at the code
	NSString *mainText = NSLocalizedString(@"This application does nothing.\n\n", nil);
	NSDictionary *mainAttributes = @{
		NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:1],
		NSFontAttributeName: [UIFont systemFontOfSize:30],
	};
	NSString *extraText = NSLocalizedString(@"Please explore the code (and tests).", nil);
	NSDictionary *extraAttributes = @{
		NSForegroundColorAttributeName: [UIColor colorWithWhite:0.75 alpha:1],
		NSFontAttributeName: [UIFont systemFontOfSize:22],
	};
	NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
	[text appendAttributedString:[[NSAttributedString alloc] initWithString:mainText attributes:mainAttributes]];
	[text appendAttributedString:[[NSAttributedString alloc] initWithString:extraText attributes:extraAttributes]];
	CGRect labelFrame = CGRectInset(self.window.bounds, 40, 40);
	labelFrame.origin.y -= 80;
	UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
	label.backgroundColor = [UIColor blackColor];
	label.textAlignment = NSTextAlignmentCenter;
	label.numberOfLines = 0;
	label.attributedText = text;

	// show the window
	[self.window.rootViewController.view addSubview:label];
	[self.window.rootViewController.view addSubview:button];
    [self.window makeKeyAndVisible];

    return YES;
}

@end

static void FRDrawRoundedGradientBackground(CGFloat hue, CGFloat brightness, CGRect bounds) {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect interiorBounds = CGRectInset(bounds, 1, 1);
	UIBezierPath *borderPath = [UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:8];
	UIBezierPath *interiorPath = [UIBezierPath bezierPathWithRoundedRect:interiorBounds cornerRadius:7];
	[borderPath appendPath:interiorPath];
	[borderPath setUsesEvenOddFillRule:YES];
	
	UIColor *borderColor = [UIColor colorWithHue:hue saturation:1 brightness:0.9 alpha:0.5];
	UIColor *startColor = [UIColor colorWithHue:hue saturation:0.7 brightness:brightness alpha:1];
	UIColor *endColor = [UIColor colorWithHue:hue saturation:0.9 brightness:brightness-0.2 alpha:1];
	
	NSArray *colors = [NSArray arrayWithObjects:(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor, nil];
	CGFloat locations[] = { 0.0, 1.0 };
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
	
	CGFloat left = CGRectGetMinX(interiorBounds);
	CGContextSaveGState(context);
	CGContextAddPath(context, interiorPath.CGPath);
	CGContextClip(context);
	CGContextDrawLinearGradient(context, gradient,
								CGPointMake(left, CGRectGetMinY(interiorBounds)),
								CGPointMake(left, CGRectGetMaxY(interiorBounds)), 0);
	CGContextRestoreGState(context);
	
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);
	
	[borderColor set];
	[borderPath fill];
}
