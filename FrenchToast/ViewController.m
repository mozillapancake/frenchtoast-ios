//
//  ViewController.m
//  FrenchToast
//
//  Created by Stefan Arentz on 2012-09-17.
//  Copyright (c) 2012 Stefan Arentz. All rights reserved.
//

#import "ViewController.h"



@interface Viewer : NSObject {
    NSString* url_;
    BOOL isAppView_;
    UIWebView* webView_;
}

- (id) initWithURL: (NSString*) url isAppView: (BOOL) isAppView;
- (void) load;
- (void) stop;
- (void) reload;
- (UIView*) view;

@end

@implementation Viewer

- (id) initWithURL: (NSString*) url isAppView: (BOOL) isAppView
{
    if ((self = [super init]) != nil)
    {
        isAppView_ = isAppView;
        url_ = [url copy];
        webView_ = [[UIWebView alloc] initWithFrame: CGRectZero];
        
        if (isAppView_) {
            [PancakeURLProtocol registerAppView: url];
        }
    }
    
    return self;
}

- (void) dealloc
{
    [url_ release];
    [webView_ removeFromSuperview];
    [webView_ release];
    [super dealloc];
}

- (void) load
{
    [webView_ loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: url_]]];
}

- (void) stop
{
    [webView_ stopLoading];
}

- (void) reload
{
    [webView_ reload];
}

- (UIView*) view
{
    return webView_;
}

@end




#pragma mark -

@interface ViewController ()
@end

@implementation ViewController
{
    NSMutableArray* viewers;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [PancakeURLProtocol registerPancakeProtocol];
    [PancakeURLProtocol registerNativeHandler: self withName: @"native"];
    
	viewers = [NSMutableArray new];
}

- (void) viewDidAppear:(BOOL)animated
{
    NSString* url = [[NSUserDefaults standardUserDefaults] stringForKey: @"URL"];
    [self openAppView: url];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void) openAppView: (NSString*) url
{
    Viewer* viewer = [[[Viewer alloc] initWithURL: url isAppView: YES] autorelease];
    [viewers addObject: viewer];
    [[viewer view] setFrame: CGRectMake(0, 80, self.view.frame.size.width, self.view.frame.size.height - 80)];
    [self.view addSubview: viewer.view];
    [viewer load];
}

- (void) openWebView: (NSString*) url
{
    Viewer* viewer = [[[Viewer alloc] initWithURL: url isAppView: NO] autorelease];
    [viewers addObject: viewer];
    [[viewer view] setFrame: CGRectMake(0, 80, self.view.frame.size.width, self.view.frame.size.height - 80)];
    [self.view addSubview: viewer.view];
    [viewer load];
}

- (void) popView
{
    Viewer* viewer = [viewers lastObject];
    if (viewer != nil)
    {
        [viewer stop];
        [viewers removeLastObject];
    }
}

- (Viewer*) peekView
{
    return [viewers lastObject];
}

#pragma mark -

- (IBAction) pop
{
    [self popView];
}

- (IBAction) reload
{
    Viewer* viewer = [self peekView];
    if (viewer != nil) {
        [viewer reload];
    }
}

#pragma mark -

- (id) handleCallWithName: (NSString*) name arguments: (NSArray*) arguments
{
    if ([name isEqualToString: @"openAppView"]) {
        NSLog(@"openAppView(%@)", [arguments objectAtIndex: 0]);
        [self performSelectorOnMainThread: @selector(openAppView:) withObject: [arguments objectAtIndex: 0] waitUntilDone: NO];
    }
    
    else if ([name isEqualToString: @"openWebView"]) {
        NSLog(@"openWebView(%@)", [arguments objectAtIndex: 0]);
        [self performSelectorOnMainThread: @selector(openWebView:) withObject: [arguments objectAtIndex: 0] waitUntilDone: NO];
    }
    
    else {
        NSLog(@"Unknown call %@", name);
    }
    
    return nil;
}

@end
