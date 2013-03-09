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

#import "FRModule.h"

static void class_extendWithMethodsFromClass(Class destination, Class source);
static IMP class_getUnextendedMethodImplementation(Class class, IMP imp);

@implementation FRModule

+ (void)extendInstance:(id)instance {
	@autoreleasepool {
		// create a new class dynamically if we need to to hold the module's methods. this class will be a sublcass of
		// the instance's class.
		Class baseClass = [instance class];
		NSString *dynamicClassName = [NSString stringWithFormat:@"%@_%s", baseClass, class_getName(self)];
		Class dynamicClass = NSClassFromString(dynamicClassName);
		if (!dynamicClass) {
			// allocate and register class pair for dynamic class if it doesn't exist
			dynamicClass = objc_allocateClassPair([instance class], [dynamicClassName UTF8String], 0);
			objc_registerClassPair(dynamicClass);
			
			// add an instance method that returns the base class (so the object still looks just like it did before to
			// most objective-c methods).
			SEL className = @selector(class);
			Method classMethod = class_getInstanceMethod(baseClass, className);
			const char *classTypes = method_getTypeEncoding(classMethod);
			IMP classOverride = imp_implementationWithBlock(^Class { return baseClass; });
			class_addMethod(dynamicClass, className, classOverride, classTypes);
			
			[self extendClass:dynamicClass];
		}
		
		// once we have the dynamic class, set the class on the instance
		object_setClass(instance, dynamicClass);
	}
}

+ (void)extendClass:(Class)class {
	Class moduleRoot = [FRModule class];
	Class module = self;
	
	// move up through the module class hierarchy adding instance & class methods until reaching the root class
	while (module && module != moduleRoot) {
		class_extendWithMethodsFromClass(class, module);
		class_extendWithMethodsFromClass(object_getClass(class), object_getClass(module));
		module = class_getSuperclass(module);
	}
}

+ (IMP)unextendedMethodForSelector:(SEL)selector object:(id)object {
	// get the class and extended imp values so we can look up the unexteded imp
	Class class = object_getClass(object);
	IMP imp = class_isMetaClass(class) ?
		[self methodForSelector:selector] :
		[self instanceMethodForSelector:selector];
	return class_getUnextendedMethodImplementation(class, imp);
}

@end

static SEL sel_nameForUnextendedIMP(IMP imp);
static SEL sel_nameForUnextendedIMP(IMP imp) {
	@autoreleasepool {
		return NSSelectorFromString([NSString stringWithFormat:@"unextendedImplementationFor_%p", imp]);
	}
}

static void class_extendWithMethodsFromClass(Class class, Class source) {
	// this method adds the methods from the source into the class, and also stores the original imp under a new name so
	// it can be looked up later.
	unsigned int count = 0;
	Ivar *ivars = class_copyIvarList(source, &count);
	BOOL invalid = (count > 0);
	free(ivars);
	
	if (invalid) {
		[NSException raise:NSInternalInconsistencyException format:
		 @"Classes (%@) used to extend other classes (%@) cannot have instance variables", source, class];
	}
	
	Method *methods = class_copyMethodList(source, &count);
	for (unsigned int i = 0; i < count; i++) {
		Method method = methods[i];
		SEL name = method_getName(method);
		IMP imp = method_getImplementation(method);
		const char *types = method_getTypeEncoding(method);
		IMP original = class_getMethodImplementation(class, name);
		class_replaceMethod(class, name, imp, types);
		class_addMethod(class, sel_nameForUnextendedIMP(imp), original, types);
	}
	free(methods);
}

static IMP class_getUnextendedMethodImplementation(Class class, IMP imp) {
	// look up methods that were stored during class_extendWithMethodsFromClass.
	return class_getMethodImplementation(class, sel_nameForUnextendedIMP(imp));
}
