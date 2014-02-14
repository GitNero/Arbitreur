//
//  ABTViewController.m
//  Arbitreur
//
//  Created by Rohan Parolkar on 12/13/13.
//  Copyright (c) 2013 Sable Learning. All rights reserved.
//

#import "ABTViewController.h"
#import "MBProgressHUD.h"
#import "Reachability.h"
#import "UIView+SLAdditions.h"

@interface ABTViewController ()
{
    NSDictionary *campBXDictionary;
    NSDictionary *coinbaseDictionary;
    NSTimer *fetchTimer;
    CGFloat btcAmount;
    
    BOOL hasFetchedCBX;
    BOOL hasFetchedCBE;
    NSTimer *overlayTimer;
    BOOL overlayIsAnimating;
    
    CGFloat buyPrice;
    CGFloat sellPrice;
    
    CGFloat rawBuyPrice;
    CGFloat rawSellPrice;
    
    BOOL buyingOnCBX;
}

@end

@implementation ABTViewController

@synthesize purchasePriceLabel,salePriceLabel,profitLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    fetchTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(fetchPrices) userInfo:Nil repeats:YES];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recalculateProfit) name:@"hasFetched" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self resetScreen];
}

- (void)viewDidAppear:(BOOL)animated
{
    if ([self reachabilityCheck]) [self fetchPrices];
}

- (void)fetchPrices
{
    self.fetchOverlayView.hidden = NO;
    if (!overlayIsAnimating) [self startAnimatingOverlay];
    
    [Reachability reachabilityForInternetConnection];
    NSLog(@"Fetching prices...");
    
    [self fetchCampBXTickerPrices];
    
    if (buyingOnCBX) [self fetchCoinbaseSellPrices];
    else [self fetchCoinbaseBuyPrices];
    
}

- (void)fetchCampBXTickerPrices
{
    [self fetchPricesWithURL:@"http://CampBX.com/api/xticker.php"];
}

- (void)fetchCoinbaseBuyPrices

{
    [self fetchPricesWithURL:@"https://coinbase.com/api/v1/prices/buy"];
}

- (void)fetchCoinbaseSellPrices

{
    [self fetchPricesWithURL:@"https://coinbase.com/api/v1/prices/sell"];
}

- (void)fetchGoogle
{
    [self fetchPricesWithURL:@"http://www.google.com"];
}

- (void)fetchPricesWithURL:(NSString *)urlString
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:10];
    
    [request setHTTPMethod: @"GET"];
    
    NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [urlConnection start];

}

#pragma mark NSURLConnectionDataDelegate

/*this method might be calling more than one times according to incoming data size
*/
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    
    NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSData *jsonData = [response dataUsingEncoding:NSUTF8StringEncoding];
    
    if ([connection.currentRequest.URL.absoluteString rangeOfString:@"CampBX"].location!=NSNotFound)
    {
        hasFetchedCBX = YES;
        campBXDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    }
    else if([connection.currentRequest.URL.absoluteString rangeOfString:@"coinbase"].location!=NSNotFound)
    {
        hasFetchedCBE = YES;
        coinbaseDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    }
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"hasFetched" object:nil];
    [self recalculateProfit];
}
/*
 if there is an error occured, this method will be called by connection
 */
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    
    NSLog(@"%@" , error.description);
}

/*
 if data is successfully received, this method will be called by connection
 */
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    NSLog(@"Connection to %@ finished loading",connection.currentRequest.URL);

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startAnimatingOverlay
{
    overlayTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(animateOverlay) userInfo:nil repeats:YES];
    overlayIsAnimating = YES;
    [MBProgressHUD showHUDAddedTo:self.fetchOverlayView animated:YES];
}

- (void)animateOverlay
{
    if ([self.fetchOverlayLabel.text rangeOfString:@"..."].location == NSNotFound) {
        self.fetchOverlayLabel.text = [self.fetchOverlayLabel.text stringByAppendingString:@"."];
    }
    else
    {
        self.fetchOverlayLabel.text = [self.fetchOverlayLabel.text substringToIndex:self.fetchOverlayLabel.text.length-3];
    }
}

- (void)hideOverlay
{
    [overlayTimer invalidate];
    self.fetchOverlayView.hidden = YES;
    overlayIsAnimating = NO;
}

- (void)recalculateProfit
{
    if (hasFetchedCBX && hasFetchedCBE) {
        
        if (!self.fetchOverlayView.hidden) [self hideOverlay];
        
        self.amountLabel.text = [NSString stringWithFormat:@"BTC %.2f",btcAmount];
        
        if (buyingOnCBX) {
            
            rawBuyPrice = [(NSString *)[campBXDictionary objectForKey:@"Best Ask"] floatValue];
            buyPrice =  1.0055      // trading feeds on CBX are 0.55%
            * btcAmount             // principal
            * rawBuyPrice; //  raw price

            rawSellPrice = [[[coinbaseDictionary objectForKey:@"subtotal"] objectForKey:@"amount"] floatValue];
            sellPrice =  0.99      // trading feeds on CBE are 1%
            * btcAmount             // principal
            * rawSellPrice; //  raw price
        }
        else
        {
            
            rawBuyPrice = [[[coinbaseDictionary objectForKey:@"subtotal"] objectForKey:@"amount"] floatValue];
            buyPrice =  1.01      // trading feeds on CBE are 1%
            * btcAmount             // principal
            * rawBuyPrice; //  raw price
            
            rawSellPrice = [(NSString *)[campBXDictionary objectForKey:@"Best Bid"] floatValue];
            sellPrice = 0.9945       // trading feeds on CBX are 0.55%
            * btcAmount             // principal
            * rawSellPrice; //  raw price
        }
        
        purchasePriceLabel.text = [NSString stringWithFormat:@"$ %.2f",rawBuyPrice];
        salePriceLabel.text = [NSString stringWithFormat:@"$ %.2f",rawSellPrice];
        
        CGFloat profit = sellPrice-buyPrice-0.15; // CBE charges a bank fee for all purchases and sales
        profitLabel.text = [NSString stringWithFormat:@"$ %.2f",profit];
        NSLog(@"After fees: Buy @ %f, Sell @ %f",buyPrice,sellPrice);
        
        if (profit<0) [profitLabel setTextColor:[UIColor redColor]];
        else [profitLabel setTextColor:[UIColor greenColor]];
        
        [MBProgressHUD hideAllHUDsForView:self.fetchOverlayView animated:YES];
    }
}

- (void)resetScreen
{
    buyingOnCBX = NO;
    [UIView animateWithDuration:1 animations:^(void)
     {
         self.cbeImageView.left = 29;
         self.cbxImageView.left = 190;
         purchasePriceLabel.text = @"";
         salePriceLabel.text = @"";
         profitLabel.text = @"";
         btcAmount = pow(10,self.amountSlider.value);
     }];
}

- (IBAction)changedSegmentedControl:(id)sender {
    if ([self reachabilityCheck]) [self fetchPrices];
}

- (IBAction)changedAmount:(id)sender {
    
    btcAmount = pow(10,self.amountSlider.value);
    self.amountLabel.text = [NSString stringWithFormat:@"BTC %.2f",btcAmount];
    [self recalculateProfit];
}


-(BOOL)reachabilityCheck
{
    Reachability* wifiReach = [Reachability reachabilityWithHostName:@"www.google.com"];
    NetworkStatus netStatus = [wifiReach currentReachabilityStatus];
    
    if (netStatus==NotReachable) {
        UIAlertView *connectionError = [[UIAlertView alloc] initWithTitle:@"Connection Error" message:@"Unable to establish internet connection." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [connectionError setTag:1];
        [connectionError show];
        return NO;
    }
    return YES;
}
- (IBAction)pressedSwitchButton:(id)sender {
    
    buyingOnCBX = !buyingOnCBX;
    
    CGFloat cbxLeft = self.cbeImageView.left;
    CGFloat cbeLeft = self.cbxImageView.left;
    
    [UIView animateWithDuration:0.3 animations:^(void)
    {
        self.cbeImageView.left = cbeLeft;   //  29
        self.cbxImageView.left = cbxLeft;   // 190
    }];
    
    [self fetchPrices];
}
@end
