//
//  ABTViewController.h
//  Arbitreur
//
//  Created by Rohan Parolkar on 12/13/13.
//  Copyright (c) 2013 Sable Learning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ABTViewController : UIViewController<NSURLConnectionDataDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *marketSegmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *purchasePriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *salePriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *profitLabel;
- (IBAction)changedSegmentedControl:(id)sender;
@end
