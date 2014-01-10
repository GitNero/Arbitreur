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

@interface ABTViewController ()
{
    NSDictionary *campBXDictionary;
    NSDictionary *coinbaseDictionary;
    NSTimer *fetchTimer;
}

@end

@implementation ABTViewController

@synthesize marketSegmentedControl,purchasePriceLabel,salePriceLabel,profitLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    fetchTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(fetchPrices) userInfo:Nil repeats:YES];
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
    [Reachability reachabilityForInternetConnection];
    NSLog(@"Fetching prices...");
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [self fetchCampBXTickerPrices];
    if (marketSegmentedControl.selectedSegmentIndex==0) [self fetchCoinbaseSellPrices];
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
    
    if ([connection.currentRequest.URL.absoluteString rangeOfString:@"CampBX"].location!=NSNotFound) campBXDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    else if([connection.currentRequest.URL.absoluteString rangeOfString:@"coinbase"].location!=NSNotFound) coinbaseDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    
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

- (void)recalculateProfit
{
    NSString *buyPrice;
    NSString *sellPrice;
    NSNumber *profit;
    if (marketSegmentedControl.selectedSegmentIndex==0) {
        buyPrice=  [campBXDictionary objectForKey:@"Best Ask"];
        sellPrice = [coinbaseDictionary objectForKey:@"amount"];
        profit = [NSNumber numberWithFloat:sellPrice.floatValue - 1.0055*buyPrice.floatValue];
    }
    else
    {
        buyPrice=  [coinbaseDictionary objectForKey:@"amount"];
        sellPrice = [campBXDictionary objectForKey:@"Best Bid"];
        profit = [NSNumber numberWithFloat:.9945*sellPrice.floatValue - buyPrice.floatValue];
    }
    NSString *profitString = [NSString stringWithFormat:@"%.2f",profit.floatValue];
    
    if (buyPrice.length*sellPrice.length>0) {
        purchasePriceLabel.text = buyPrice;
        salePriceLabel.text=  sellPrice;
        profitLabel.text = profitString;
        if (profit.floatValue<0) [profitLabel setTextColor:[UIColor redColor]];
        else [profitLabel setTextColor:[UIColor greenColor]];
    }
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)resetScreen
{
    [marketSegmentedControl setSelectedSegmentIndex:0];
    purchasePriceLabel.text = @"";
    salePriceLabel.text = @"";
    profitLabel.text = @"";
}

- (IBAction)changedSegmentedControl:(id)sender {
    if ([self reachabilityCheck]) [self fetchPrices];
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
@end
