# Objective-C Mixins for Classes & Instances

This repository includes code demonstrating an implementation of mixins in Objective-C. While many mixin implementations exist, many lack the ability to use mixins for individual instances.

With `FRMixin`, you can do the following:

	@interface FRTimeAgo : FRModule
	@end
	@implementation FRTimeAgo
	- (NSString *)timeAgo { // more code would go in here
	  NSTimeInterval seconds = -[self.creationDate timeIntervalSinceNow];
	  return [NSString stringWithFormat:@"%i hours ago", seconds / 3600];
	}
	@end
	
	[FRTimeAgo extendClass:[FRArticle class]];
	[FRTimeAgo extendInstance:a];
	

While this specific example may be more easily accomplished as a category on `NSDate`, mixins still can be an extremely useful tool for composing classes and methods in Objective-C.

This example was created to accompany [a presentation](http://wbyoung.github.com/objective_c_runtime.pdf). There are no known issues with it, but please thoroughly test anything you use from this example before using it in production.
