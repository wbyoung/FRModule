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

@interface FRModule : NSObject

/*!
 \brief		Extend a class
 \details	Extend a class by adding all the methods from the receiver to it. Using the same module to extend a class
			with an ancestor or descendant class that has already been extended with that module will result in
			undefined behavior (at this point).
 */
+ (void)extendClass:(Class)class;

/*!
 \brief		Extend an instance
 \details	Extend an instance by adding all methods from the receiver to it. Using the same module to extend an
			instance whose class has an ancestor or descendant class that has already been extended with that module
			will result in undefined behavior (at this point).
 */
+ (void)extendInstance:(id)instance;

/*!
 \brief		Get the original method for an extension method
 \details	This allows an extension method to dynamically look up which method it replaced. This is handy when defining
			methods in modules that are intended to override methods in the class they will extend since you can't
			simply call super.
 */
+ (IMP)unextendedMethodForSelector:(SEL)selector object:(id)object;

@end
