//
//  ViewController.m
//  FrenchToast
//
//  Created by Stefan Arentz on 2012-09-17.
//  Copyright (c) 2012 Stefan Arentz. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "WebViewController.h"
#import "ViewController.h"



@interface Viewer : NSObject {
    NSUInteger index_;
    NSString* url_;
    BOOL isAppView_;
    UIView* containerView_;
    UIWebView* webView_;
}

- (id) initWithIndex: (NSUInteger) index URL: (NSString*) url isAppView: (BOOL) isAppView;

- (NSUInteger) index;

- (void) load;
- (void) stop;
- (void) reload;

- (void) disable;
- (void) enable;

- (UIWebView*) webView;
- (UIView*) view;

@end

@implementation Viewer

- (id) initWithIndex: (NSUInteger) index URL: (NSString*) url isAppView: (BOOL) isAppView
{
    if ((self = [super init]) != nil)
    {
        index_ = index;
        isAppView_ = isAppView;
        url_ = [url copy];

        containerView_  = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 0, 0)];
        containerView_.backgroundColor = [UIColor lightGrayColor];

        UIImageView* scrubberImageView = [[[UIImageView alloc] initWithImage: [UIImage imageNamed: @"Scrubber.png"]] autorelease];
        scrubberImageView.frame = CGRectMake(0, 0, 13, 0);
        scrubberImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [containerView_ addSubview: scrubberImageView];

        if (index_ != 0)
        {
            containerView_.layer.shadowColor = [[UIColor blackColor] CGColor];
            containerView_.layer.shadowOffset = CGSizeMake(10.0f, 10.0f);
            containerView_.layer.shadowOpacity = 1.0f;
            containerView_.layer.shadowRadius = 10.0f;
        }

        if (index_ == 0) {
            webView_ = [[UIWebView alloc] initWithFrame: CGRectMake(0, 0, 0, 0)];
        } else {
            webView_ = [[UIWebView alloc] initWithFrame: CGRectMake(12, 0, 0, 0)];
        }

        webView_.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

        [containerView_ addSubview: webView_];
        
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
    [containerView_ removeFromSuperview];
    [containerView_ release];
    [super dealloc];
}

- (NSUInteger) index
{
    return index_;
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

- (void) disable
{
    webView_.userInteractionEnabled = NO;
}

- (void) enable
{
    webView_.userInteractionEnabled = YES;
}

- (UIWebView*) webView
{
    return webView_;
}

- (UIView*) view
{
    return containerView_;
}

@end




#pragma mark -

@interface ViewController ()
@end

@implementation ViewController
{
    NSMutableArray* viewers;
    UITapGestureRecognizer* _tapRecognizer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [PancakeURLProtocol registerPancakeProtocol];
    [PancakeURLProtocol registerNativeHandler: self withName: @"native"];

    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(handleTapGesture:)];
    [self.view addGestureRecognizer: _tapRecognizer];
    
	viewers = [NSMutableArray new];
}

- (void) viewWillAppear:(BOOL)animated
{
    if ([viewers count] == 0) {
        NSString* url = [[NSUserDefaults standardUserDefaults] stringForKey: @"URL"];
        [self openAppView: url];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void) handleTapGesture: (UITapGestureRecognizer*) recognizer
{
    if (recognizer.numberOfTouches == 1) {
        CGPoint location = [recognizer locationInView: self.view];
        if (location.x < 136) {
            [self popView];
        }
    }
}

#pragma mark -

- (void) positionViewer: (Viewer*) viewer
{
    // Size the viewer - Level 0 is full screen, all the others are stacking
    
    if ([viewer index] == 0) {
        [[viewer view] setFrame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    } else {
        NSUInteger level = [viewer index];
        CGFloat indent = 136 + (level * 4);
        [[viewer view] setFrame: CGRectMake(indent, 0, self.view.frame.size.width - indent, self.view.frame.size.height)];
    }
}

- (void) openAppView: (NSString*) url
{
    Viewer* viewer = [[[Viewer alloc] initWithIndex: [viewers count] URL: url isAppView: YES] autorelease];
    [viewers addObject: viewer];
    [self positionViewer: viewer];
    [self.view addSubview: viewer.view];

    if ([viewer index] != 0)
    {
        Viewer* mainViewer = [viewers objectAtIndex: 0];
        [mainViewer disable];
    
        CGRect finalFrame = [[viewer view] frame];
        CGRect startFrame = finalFrame; startFrame.origin.x = self.view.frame.size.width;

        [[viewer view] setFrame: startFrame];
        [UIView animateWithDuration: 0.4  animations:^{
            [[viewer view] setFrame: finalFrame];
        }];
    }
    
    [viewer load];
}

- (void) openWebView: (NSString*) url
{
    WebViewController* webViewController = [[WebViewController new] autorelease];
    webViewController.url = url;
    [self presentModalViewController: webViewController animated: YES];

#if 0
    Viewer* viewer = [[[Viewer alloc] initWithIndex: [viewers count] URL: url isAppView: NO] autorelease];
    [viewers addObject: viewer];
    [self positionViewer: viewer];
    [self.view addSubview: viewer.view];

    if ([viewer index] != 0)
    {
        Viewer* mainViewer = [viewers objectAtIndex: 0];
        [mainViewer disable];

        CGRect finalFrame = [[viewer view] frame];
        CGRect startFrame = finalFrame; startFrame.origin.x = self.view.frame.size.width;

        [[viewer view] setFrame: startFrame];
        [UIView animateWithDuration: 0.4  animations:^{
            [[viewer view] setFrame: finalFrame];
        }];
    }

    [viewer load];
#endif
}

- (void) popView
{
    if ([viewers count] > 1)
    {
        Viewer* topViewer = [viewers lastObject];
        [topViewer stop];

        [UIView animateWithDuration: 0.4
            animations: ^{
                CGRect frame = [[topViewer view] frame];
                frame.origin.x = self.view.frame.size.width;
                [[topViewer view] setFrame: frame];
            }
            completion: ^(BOOL completed) {
                [viewers removeLastObject];
                
                // Send out an event to the first layer that something has new focus
                
                Viewer* topViewer = [viewers lastObject];
                Viewer* mainViewer = [viewers objectAtIndex: 0];

                if ([viewers count] == 1) {
                    [mainViewer enable];
                }
                
                NSString* url = [[topViewer webView] stringByEvaluatingJavaScriptFromString: @"window.location.href"];
                NSData* json = [NSJSONSerialization dataWithJSONObject: url options: NSJSONReadingAllowFragments error: NULL];
                NSString* jsonString = [[[NSString alloc] initWithData: json encoding:NSUTF8StringEncoding] autorelease];

                NSString* code = [NSString stringWithFormat: @"FrenchToast.dispatchLayerFocusEvent(%@)", jsonString];
                [[mainViewer webView] stringByEvaluatingJavaScriptFromString: code];
            }];
    
    }
}

#pragma mark -

- (IBAction) pop
{
    [self popView];
}

- (IBAction) reload
{
    Viewer* viewer = [viewers lastObject];
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
        NSLog(@"Unknown call %@: %@", name, arguments);
    }
    
    return nil;
}

@end
