//
//  WebViewController.h
//  FrenchToast
//
//  Created by Stefan Arentz on 2012-09-20.
//  Copyright (c) 2012 Stefan Arentz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController

@property (retain, nonatomic) NSString* url;
@property (retain, nonatomic) IBOutlet UIWebView *webView;

- (IBAction)done:(id)sender;

@end
