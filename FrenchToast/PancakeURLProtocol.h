/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>

@protocol PancakeCallHandler
- (id) handleCallWithName: (NSString*) name arguments: (NSArray*) arguments;
@end

@interface PancakeURLProtocol : NSURLProtocol

+ (void) registerPancakeProtocol;

+ (void) registerAppView: (NSString*) url;
+ (void) registerWebView: (UIWebView*) webView withName: (NSString*) name;
+ (void) registerNativeHandler: (id<PancakeCallHandler>) handler withName: (NSString*) name;

+ (UIWebView*) lookupWithViewWithName: (NSString*) name;
+ (id) lookupNativeHandlerWithName: (NSString*) name;

+ (void) setApplicationURL: (NSURL*) applicationURL;

@end
