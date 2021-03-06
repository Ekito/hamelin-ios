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
@property (weak, nonatomic) IBOutlet UIView *connectedView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingSpinningWheel;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (weak, nonatomic) IBOutlet UIButton *participeButton;
@property (weak, nonatomic) IBOutlet UIButton *liveButton;

@property (strong) AFNetworkReachabilityManager *reachManagerHeroku;

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
    
    self.connectedView.alpha = 0.0f;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSLog(@"Hello");
    
    [self configureUIBasedOnConnectivity];
}

- (void) configureUIBasedOnConnectivity {
    self.reachManagerHeroku = [AFNetworkReachabilityManager managerForDomain:@"hamelin.herokuapp.com"];

    __weak ViewController *weakSelf = self;
    
    [self.reachManagerHeroku setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusNotReachable || status == AFNetworkReachabilityStatusNotReachable) {
            // On est pas connectable à Heroku - On essaye d'afficher la page Hamelin
            NSLog(@"Non connectable Heroku");
            [weakSelf.reachManagerHeroku stopMonitoring];
            
            NSString * const kURLOfWebPageToLoad = @"http://192.168.5.106:8080/mobile.html";
            weakSelf.urlOfWebView = [NSURL URLWithString:kURLOfWebPageToLoad];
            [weakSelf didReceiveURLOfWebView];
            
        } else {
            // On est connectable à Heroku, on affiche la page Heroku
            [weakSelf.reachManagerHeroku stopMonitoring];
            NSLog(@"Connectable Heroku");

            NSString * const kURLOfWebPageToLoad = @"http://hamelin.herokuapp.com/mobile-demo.html";
            weakSelf.urlOfWebView = [NSURL URLWithString:kURLOfWebPageToLoad];
            [weakSelf didReceiveURLOfWebView];
        }
    }];

    [self.reachManagerHeroku startMonitoring];
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

- (void) showConnectedView {
    [UIView animateWithDuration:0.5 animations:^{
        self.connectedView.alpha = 1.0f;
        if ([self.webView.request.URL.host isEqualToString:@"hamelin.herokuapp.com"]) {
            self.liveButton.enabled = YES;
        } else {
            self.liveButton.enabled = NO;
        }
    }];
}


- (void) hideConnectedView {
    [UIView animateWithDuration:0.5 animations:^{
        self.connectedView.alpha = 0.0f;
    }];
}

- (void) showLoadingComponents {
    self.loadingLabel.hidden = NO;
    self.loadingSpinningWheel.hidden = NO;
    self.participeButton.hidden = YES;
    [self.loadingSpinningWheel startAnimating];
}

- (void) hideLoadingComponents {
    self.loadingLabel.hidden = YES;
    [self.loadingSpinningWheel startAnimating];
    self.loadingSpinningWheel.hidden = YES;
    self.participeButton.hidden = NO;
}



- (void) didReceiveURLOfWebView {
    [self showLoadingComponents];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.urlOfWebView]];
}

- (IBAction)participeButtonTap:(id)sender {
    [self configureUIBasedOnConnectivity];
}

- (IBAction)liveButtonTap:(id)sender {
    [self configureUIBasedOnConnectivity];
}

#pragma mark -
#pragma mark UIWebViewDelegate


- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"Did start loading");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self hideConnectToWifiView];
    [self showConnectedView];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    if ([error.domain isEqualToString:NSURLErrorDomain]
        && error.code == NSURLErrorCannotConnectToHost) {
        NSLog(@"Could not connect to host");
    }

    NSLog(@"Error: %@ - \n\n%@", error, [error description]);

    [self hideLoadingComponents];
    [self showConnectToWifiView];
    [self hideConnectedView];
}


@end
