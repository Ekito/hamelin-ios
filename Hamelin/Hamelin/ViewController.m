//
//  ViewController.m
//  Hamelin
//
//  Created by Guillaume Cerquant on 03/04/14.
//  Copyright (c) 2014 ekito. All rights reserved.
//

#import "AFNetworking.h"


#import "ViewController.h"

@interface ViewController () <UIWebViewDelegate>


@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (strong) NSURL *urlOfWebView;
@property (weak, nonatomic) IBOutlet UIView *connectToWifiView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingSpinningWheel;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;

@end

@implementation ViewController



- (void) fetchURLOfWebViewFromRemoteJSONConfigFile {
    NSURL *URL = [NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/75375533/hamelin.json"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    operation.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
    
    
    [AFHTTPRequestOperationManager manager].responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        
        if (! [responseObject isKindOfClass:NSDictionary.class]) {
            NSLog(@"Expecting a dictionary in json object ; aborting");
            [self retryFetchURLLater];
            return;
        }
     
     
        
        NSDictionary *dictionaryObject = responseObject;
        
        if (! [dictionaryObject valueForKey:@"url"]) {
            NSLog(@"No url value in dictionary received ; aborting");
            [self retryFetchURLLater];

            return;
        }
        
        self.urlOfWebView = [NSURL URLWithString:[dictionaryObject valueForKey:@"url"]];
        
        if (! self.urlOfWebView) {
            NSLog(@"Fetched url is nil, this is unexpected ; aborting");
            [self retryFetchURLLater];
            return;
        }
        
        [self didReceiveURLOfWebView];
    }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         NSLog(@"Could not fetch url. Error: %@", error);
                                         [self retryFetchURLLater];
                                     }];
    [operation start];
    
    
    
}

- (void) retryFetchURLLater {
    [self performSelector:@selector(fetchURLOfWebViewFromRemoteJSONConfigFile) withObject:nil afterDelay:3.0f];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Temporary disabled
//    [self fetchURLOfWebViewFromRemoteJSONConfigFile];

}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSLog(@"Hello");
    
    [self configureUIBasedOnConnectivity];
    
    //    instead:
    NSString * const kURLOfWebPageToLoad = @"http://192.168.5.106:8080/mobile.html"; // @"http://www.google.fr"; // 
    
    self.urlOfWebView = [NSURL URLWithString:kURLOfWebPageToLoad];
    [self didReceiveURLOfWebView];
}

- (void) configureUIBasedOnConnectivity {
    NSLog(@"Currently disabled");
    return;
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];

    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        if ([AFNetworkReachabilityManager sharedManager].isReachableViaWiFi ) {
            [self hideConnectToWifiView];
        } else {
            [self showConnectToWifiView];
        }
        
    }];

}

- (void) showConnectToWifiView {
    [UIView animateWithDuration:0.5 animations:^{
        self.connectToWifiView.alpha = 1.0f;
    }];
}


- (void) hideConnectToWifiView {
    [UIView animateWithDuration:0.5 animations:^{
        self.connectToWifiView.alpha = 0.0f;
    }];
}

- (void) showLoadingComponents {
    self.loadingLabel.hidden = NO;
    self.loadingSpinningWheel.hidden = NO;
    [self.loadingSpinningWheel startAnimating];
}

- (void) hideLoadingComponents {
    self.loadingLabel.hidden = YES;
    [self.loadingSpinningWheel startAnimating];
    self.loadingSpinningWheel.hidden = YES;
}



- (void) didReceiveURLOfWebView {
    [self showLoadingComponents];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.urlOfWebView]];
}


#pragma mark -
#pragma mark UIWebViewDelegate


- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"Did start loading");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self hideConnectToWifiView];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    if ([error.domain isEqualToString:NSURLErrorDomain]
        && error.code == NSURLErrorCannotConnectToHost) {
        NSLog(@"Could not connect to host");
    }

    NSLog(@"Error: %@ - \n\n%@", error, [error description]);

    [self hideLoadingComponents];
    [self showConnectToWifiView];
    [self retryFetchURLLater];


}


@end
