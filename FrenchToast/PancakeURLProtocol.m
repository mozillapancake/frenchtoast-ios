/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "PancakeURLProtocol.h"

@interface Evaluator : NSObject {
    @private
    UIWebView* _webView;
    NSString* _javaScript;
    NSString* _result;
}

- (void) evaluate;

@property (readonly) NSString* result;

@end

@implementation Evaluator

@synthesize result = _result;

- (id) initWithWebView: (UIWebView*) webView javaScript: (NSString*) javaScript
{
    if ((self = [super init]) != nil) {
        _webView = [webView retain];
        _javaScript = [javaScript retain];
    }
    return self;
}

- (void) dealloc
{
    [_webView release];
    [_javaScript release];
    [_result release];
    [super dealloc];
}

- (void) evaluate
{
    _result = [[_webView stringByEvaluatingJavaScriptFromString: _javaScript] copy];
}

@end

#pragma mark -

static NSMutableDictionary* sWebViews = nil;
static NSMutableDictionary* sNativeHandlers = nil;
static NSURL* sApplicationURL = nil;
static NSMutableSet* sAppViews = nil;

#pragma mark -

@implementation PancakeURLProtocol

+ (void) registerPancakeProtocol
{
    static BOOL initialized = NO;
    if (initialized == NO)
    {
        [NSURLProtocol registerClass: [PancakeURLProtocol class]];
        
        sWebViews = [NSMutableDictionary new];
        sNativeHandlers = [NSMutableDictionary new];
        sAppViews = [NSMutableSet new];
        
        initialized = YES;
    }
}

+ (void) registerWebView: (UIWebView*) webView withName: (NSString*) name
{
    @synchronized (self) {
        [sWebViews setObject: webView forKey: name];
    }
}

+ (void) registerAppView: (NSString*) url
{
    @synchronized (self) {
        [sAppViews addObject: url];
    }
}

+ (void) registerNativeHandler: (id<PancakeCallHandler>) handler withName: (NSString*) name
{
    @synchronized (self) {
        [sNativeHandlers setObject: handler forKey: name];
    }
}

+ (UIWebView*) lookupWithViewWithName: (NSString*) name
{
    @synchronized (self) {
        return [sWebViews objectForKey: name];
    }
}

+ (id) lookupNativeHandlerWithName: (NSString*) name
{
    @synchronized (self) {
        return [sNativeHandlers objectForKey: name];
    }
}

+ (void) setApplicationURL: (NSURL*) applicationURL
{
    @synchronized (self) {
        if (sApplicationURL != nil) {
            [sApplicationURL release];
            sApplicationURL = nil;
        }
        sApplicationURL = [applicationURL copy];
    }
}

+ (BOOL) canInitWithRequest: (NSURLRequest*) request
{
    //NSLog(@"%@ received %@ with url='%@' and scheme='%@' path='%@' mainDocumentURL='%@'", self, NSStringFromSelector(_cmd), [[request URL] absoluteString], [[request URL] scheme], [[request URL] path], [[request mainDocumentURL] absoluteString]);
    
    // Check if we should intercept this request
    
    if ([request.HTTPMethod isEqualToString: @"POST"] && [[request.URL absoluteString] isEqualToString: @"http://localhost:1234/prefix/send"])
    {
        // Check the mainDocumentURL to be sure this request is originating from one of our own pages
        
        NSURL* url = [request mainDocumentURL];
//        if ([url.scheme isEqualToString: sApplicationURL.scheme] && [url.host isEqualToString: sApplicationURL.host] && ((url.port == nil && sApplicationURL.port == nil) || [url.port isEqualToNumber: sApplicationURL.port])) {
        if ([sAppViews containsObject: [url absoluteString]]) {
            return YES;
        }
    }

    return NO;
}

+ (NSURLRequest*) canonicalRequestForRequest: (NSURLRequest*) request
{
    //NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    return request;
}

- (void) createServerErrorWithReason: (NSString*) reason
{
    //NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));

    // TODO Send back real response

    NSMutableDictionary* responseDictionary = [NSMutableDictionary dictionary];
    [responseDictionary setObject: [NSNumber numberWithBool: NO] forKey: @"success"];
    [responseDictionary setObject: reason forKey: @"reason"];
    
    NSError* error = nil;
    NSData* responseData = [NSJSONSerialization dataWithJSONObject: responseDictionary options: NSJSONWritingPrettyPrinted error: &error];
    if (responseData)
    {
        NSURLResponse *response = [[[NSURLResponse alloc] initWithURL: [[self request] URL] MIMEType: @"application/json" expectedContentLength: [responseData length]  textEncodingName: nil] autorelease];
        if (response)
        {
            id<NSURLProtocolClient> client = [self client];

            [client URLProtocol: self didReceiveResponse: response cacheStoragePolicy: NSURLCacheStorageNotAllowed];
            [client URLProtocol: self didLoadData: responseData];
            [client URLProtocolDidFinishLoading: self];
        }
    }
}

- (void) startLoading
{
    //NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));

    // Parse the JSON POST data
    
    NSURLRequest* request = [self request];
    
    NSData *postData = [request HTTPBody];
    if (postData == nil) {
        [self createServerErrorWithReason: @"Missing POST data"];
        return;
    }
                        
    NSError* decodeError = nil;
    NSDictionary* requestDictionary = [NSJSONSerialization JSONObjectWithData: postData options: NSJSONReadingAllowFragments error: &decodeError];
    if (requestDictionary == nil || decodeError != nil) {
        [self createServerErrorWithReason: @"Invalid JSON in POST data"];
        return;
    }

    // Validate the request
    
    NSString* webViewName = [requestDictionary objectForKey: @"destination"];
    if (webViewName == nil) {
        [self createServerErrorWithReason: @"Invalid request: missing destination"];
        return;
    }

    // 

    NSData* responseData = nil;

    id<PancakeCallHandler> callHandler = [PancakeURLProtocol lookupNativeHandlerWithName: webViewName];
    if (callHandler != nil)
    {
        id callDictionary = [requestDictionary objectForKey: @"call"];
        if (callDictionary == nil) {
            [self createServerErrorWithReason: @"Invalid request: missing call"];
            return;
        }
        
        id result = nil;

        @try {
            result = [callHandler handleCallWithName: [callDictionary objectForKey: @"name"] arguments: [callDictionary objectForKey: @"arguments"]];
        } @catch (NSException* e) {
            [self createServerErrorWithReason: @"Exception while executing native handler"];
            return;
        }

        NSDictionary* responseDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: YES], @"success", result, @"result", nil];
        responseData = [NSJSONSerialization dataWithJSONObject: responseDictionary options: NSJSONWritingPrettyPrinted error: NULL];
    }

    // Did not find a native handler so maybe we need to send this request to a webview

    else
    {
        UIWebView* webView = [PancakeURLProtocol lookupWithViewWithName: webViewName];
        if (webView == nil) {
            [self createServerErrorWithReason: @"Unknown destination"];
            return;
        }
        
        // Encode the message
        
        id callDictionary = [requestDictionary objectForKey: @"call"];
        if (callDictionary == nil) {
            [self createServerErrorWithReason: @"Invalid request: missing destination"];
            return;
        }
        
        NSError* encodeError = nil;
        NSData* callData = [NSJSONSerialization dataWithJSONObject: callDictionary options: NSJSONWritingPrettyPrinted error: &encodeError];
        if (callData == nil || encodeError != nil) {
            [self createServerErrorWithReason: @"Unable to serialize call"];
            return;
        }
        
        // Call the webView
        
        NSString* callString = [[[NSString alloc] initWithData: callData encoding: NSUTF8StringEncoding] autorelease];
        NSString* javaScript = [NSString stringWithFormat: @"MessageThing.handleCall(%@)", callString];
                    
        Evaluator* evaluator = [[[Evaluator alloc] initWithWebView: webView javaScript: javaScript] autorelease];
        [evaluator performSelectorOnMainThread: @selector(evaluate) withObject: nil waitUntilDone: YES];
                
        // Send back the response
        
        responseData = [evaluator.result dataUsingEncoding: NSUTF8StringEncoding];
    }

    // Send back the response
    
    NSMutableDictionary* headers = [NSMutableDictionary dictionary];
    [headers setObject: @"application/json" forKey: @"Content-Type"];
    [headers setObject: [NSString stringWithFormat: @"%d", [responseData length]] forKey: @"Content-Length"];
    [headers setObject: @"*" forKey: @"Access-Control-Allow-Origin"];
    
    NSHTTPURLResponse* response = [[[NSHTTPURLResponse alloc] initWithURL: [request URL] statusCode: 200 HTTPVersion: @"1.0" headerFields: headers] autorelease];
    if (response)
    {
        id<NSURLProtocolClient> client = [self client];

        [client URLProtocol: self didReceiveResponse: response cacheStoragePolicy: NSURLCacheStorageNotAllowed];
        [client URLProtocol: self didLoadData: responseData];
        [client URLProtocolDidFinishLoading: self];
    }
}

- (void) stopLoading
{
    //NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
}

@end
