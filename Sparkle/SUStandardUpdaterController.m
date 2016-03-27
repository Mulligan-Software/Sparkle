//
//  SUStandardUpdaterController.m
//  Sparkle
//
//  Created by Mayur Pawashe on 2/28/16.
//  Copyright © 2016 Sparkle Project. All rights reserved.
//

#import "SUStandardUpdaterController.h"
#import "SUUpdater.h"
#import "SUHost.h"
#import "SUStandardUserDriver.h"
#import "SUConstants.h"
#import "SULog.h"
#import "SUStandardUserDriver.h"

static NSString *const SUUpdaterDefaultsObservationContext = @"SUUpdaterDefaultsObservationContext";

@interface SUStandardUpdaterController ()

@property (nonatomic) SUUpdater *updater;
@property (nonatomic) id <SUStandardUserDriver> userDriver;
@property (nonatomic) BOOL initializedUpdater;

@end

@implementation SUStandardUpdaterController

@synthesize updater = _updater;
@synthesize userDriver = _userDriver;
@synthesize updaterDelegate = _updaterDelegate;
@synthesize userDriverDelegate = _userDriverDelegate;
@synthesize initializedUpdater = _initializedUpdater;

- (instancetype)initWithUpdater:(SUUpdater *)updater userDriver:(id<SUUserDriver, SUStandardUserDriver>)userDriver
{
    self = [self init]; // note: call our own init here rather than super's
    if (self != nil) {
        self.updater = updater;
        self.userDriver = userDriver;
        self.initializedUpdater = YES;
    }
    return self;
}

// Invoked from being instantiated in a nib
- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        // Register as an observer here to match unregistering in -dealloc
        [self registerAsObserver];
    }
    return self;
}

- (void)awakeFromNib
{
    // awakeFromNib might be called more than once; guard against that
    // We have to use awakeFromNib otherwise the delegate outlets may not be connected yet,
    // and we aren't a proper window or view controller, so we don't have a proper "did load" point
    if (!self.initializedUpdater) {
        self.initializedUpdater = YES;
        
        NSBundle *hostBundle = [NSBundle mainBundle];
        id <SUUserDriver, SUStandardUserDriver> userDriver = [[SUStandardUserDriver alloc] initWithHostBundle:hostBundle delegate:self.userDriverDelegate];
        self.updater = [[SUUpdater alloc] initWithHostBundle:hostBundle userDriver:userDriver delegate:self.updaterDelegate];
        self.userDriver = userDriver;
    }
}

- (void)dealloc
{
    [self unregisterAsObserver];
}

- (IBAction)checkForUpdates:(id)__unused sender
{
    [self.updater checkForUpdates];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    if ([item action] == @selector(checkForUpdates:)) {
        return !self.userDriver.updateInProgress;
    }
    return YES;
}

- (void)registerAsObserver
{
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:SUScheduledCheckIntervalKey] options:(NSKeyValueObservingOptions)0 context:(__bridge void *)(SUUpdaterDefaultsObservationContext)];
    
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:[@"values." stringByAppendingString:SUEnableAutomaticChecksKey] options:(NSKeyValueObservingOptions)0 context:(__bridge void *)(SUUpdaterDefaultsObservationContext)];
}

- (void)unregisterAsObserver
{
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[@"values." stringByAppendingString:SUScheduledCheckIntervalKey]];
    [[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:[@"values." stringByAppendingString:SUEnableAutomaticChecksKey]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == (__bridge void *)(SUUpdaterDefaultsObservationContext)) {
        // Allow a small delay, because perhaps the user or developer wants to change both preferences. This allows the developer to interpret a zero check interval as a sign to disable automatic checking.
        // Or we may get this from the developer and from our own KVO observation, this will effectively coalesce them.
        [self.updater resetUpdateCycleAfterShortDelay];
    } else {
        if ([super respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]) {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
}

@end
