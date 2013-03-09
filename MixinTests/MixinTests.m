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

#import "MixinTests.h"
#import "FRModule.h"

@interface Person : NSObject
@end

@implementation Person
@end

@interface Animal : NSObject
@end

@implementation Animal
- (NSString *)overridableMethod { return @"override"; }
@end

@interface TestModule : FRModule
@end

@implementation TestModule

+ (NSString *)mixedInClassMethod { return @"class"; }
- (NSString *)mixedInInstanceMethod { return @"instance"; }
- (NSString *)overridableMethod {
	// calling super is not possible (it's a compile time value), but we can find the the imp for that method by looking
	// it up from a value that we stored during the process of mixing in this method. the lookup requires the address of
	// the currently executing IMP which we get from the module.
	NSString *(*superIMP)(id self, SEL _cmd) = (void *)[TestModule unextendedMethodForSelector:_cmd object:self];
	return superIMP(self, _cmd);
}

@end


@implementation MixinTests

- (void)testExtendingClass {
	Person *person = [[Person alloc] init];
	STAssertFalse([person respondsToSelector:@selector(mixedInInstanceMethod)], nil);
	STAssertFalse([Person respondsToSelector:@selector(mixedInClassMethod)], nil);
	STAssertFalse([Person respondsToSelector:@selector(extendInstance:)], nil);
	STAssertFalse([Person respondsToSelector:@selector(extendClass:)], nil);
	
	[TestModule extendClass:[Person class]];

	STAssertTrue([person respondsToSelector:@selector(mixedInInstanceMethod)], nil);
	STAssertTrue([Person respondsToSelector:@selector(mixedInClassMethod)], nil);
	STAssertFalse([Person respondsToSelector:@selector(extendInstance:)], nil);
	STAssertFalse([Person respondsToSelector:@selector(extendClass:)], nil);
	STAssertThrows([(id)person overridableMethod], nil);
}

- (void)testExtendingInstance {
	Animal *animal = [[Animal alloc] init];
	STAssertFalse([animal respondsToSelector:@selector(mixedInInstanceMethod)], nil);
	STAssertFalse([Animal respondsToSelector:@selector(mixedInClassMethod)], nil);
	STAssertFalse([Animal respondsToSelector:@selector(extendInstance:)], nil);
	STAssertFalse([Animal respondsToSelector:@selector(extendClass:)], nil);
	
	[TestModule extendInstance:animal];
	
	// responds to selector will not work because the object still thinks that it's class is the animal
	// class (which hides the mixin to some extent). we need to actually call the methods here.
	STAssertEqualObjects([(id)animal mixedInInstanceMethod], @"instance", nil);
	STAssertEqualObjects([(id)animal overridableMethod], @"override", nil);
	STAssertEqualObjects([object_getClass(animal) mixedInClassMethod], @"class", nil);
	STAssertFalse([[animal class] respondsToSelector:@selector(mixedInClassMethod)], nil);
	STAssertFalse([Animal respondsToSelector:@selector(extendInstance:)], nil);
	STAssertFalse([Animal respondsToSelector:@selector(extendClass:)], nil);
	
	Animal *newAnimal = [[Animal alloc] init];
	STAssertThrows([(id)newAnimal mixedInInstanceMethod], nil);
}

@end
