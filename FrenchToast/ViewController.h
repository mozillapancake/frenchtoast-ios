//
//  ViewController.h
//  FrenchToast
//
//  Created by Stefan Arentz on 2012-09-17.
//  Copyright (c) 2012 Stefan Arentz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PancakeURLProtocol.h"

@interface ViewController : UIViewController <PancakeCallHandler>

- (IBAction) pop;
- (IBAction) reload;

@end
