//
//  ABTViewController.h
//  Arbitreur
//
//  Created by Rohan Parolkar on 12/13/13.
//  Copyright (c) 2013 Sable Learning. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ABTViewController : UIViewController<NSURLConnectionDataDelegate>

@property (weak, nonatomic) IBOutlet UISlider *amountSlider;
@property (weak, nonatomic) IBOutlet UILabel *purchasePriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *salePriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *profitLabel;
- (IBAction)changedAmount:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UIView *fetchOverlayView;
@property (weak, nonatomic) IBOutlet UILabel *fetchOverlayLabel;

@property (weak, nonatomic) IBOutlet UIImageView *cbeImageView;
@property (weak, nonatomic) IBOutlet UIImageView *cbxImageView;
- (IBAction)pressedSwitchButton:(id)sender;
@end
