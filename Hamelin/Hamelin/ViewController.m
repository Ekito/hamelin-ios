//
//  ViewController.m
//  Hamelin
//
//  Created by Guillaume Cerquant on 03/04/14.
//  Copyright (c) 2014 ekito. All rights reserved.
//

#import "AFNetworking.h"


#import "ViewController.h"

@interface ViewController ()


@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (strong) NSURL *urlOfWebView;
@property (weak, nonatomic) IBOutlet UIView *connectToWifiView;

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
        
        [self didReceiveURLOfWebView];
    }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         NSLog(@"Could not fetch url. Error: %@", error);
                                         [self retryFetchURLLater];
                                     }];
    [operation start];
    
    
    
}

- (void) retryFetchURLLater {
    [self performSelector:@selector(fetchURLOfWebViewFromRemoteJSONConfigFile) withObject:nil afterDelay:6.0f];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
    [self fetchURLOfWebViewFromRemoteJSONConfigFile];

}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
    
    [self configureUIBasedOnConnectivity];
}

- (void) configureUIBasedOnConnectivity {
//    NSLog(@"Configuring wifi view");
    
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




- (void) didReceiveURLOfWebView {
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.urlOfWebView]];
}


@end
