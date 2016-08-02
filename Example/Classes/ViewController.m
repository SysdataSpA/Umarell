// Copyright 2016 Sysdata Digital
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "ViewController.h"
#import "SDEventBus.h"

#define TIME_INTERVAL  2
#define CHANNEL_NAME   @"My channel name"
#define CHANNEL_OBJECT @"Channel message, %d"

@interface ViewController () {
    NSTimer* observedTimer;
}

@property (weak, nonatomic) IBOutlet UILabel* observedPropertyLabel;
@property (weak, nonatomic) IBOutlet UILabel* observedChannelLabel;
@property (nonatomic, strong) NSNumber* timerValue;
@end

@implementation ViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.timerValue = @(0);
}

- (IBAction) addSubscriberToProperty:(id)sender
{
    if (!observedTimer)
    {
        observedTimer = [NSTimer scheduledTimerWithTimeInterval:TIME_INTERVAL target:self selector:@selector(timerUpdate) userInfo:nil repeats:YES];
    }
    __weak typeof (self) weakSelf = self;
    [[SDEventBus sharedManager] addSubscriber:self toObject:self keyPath:@"timerValue" withCompletion:^(id _Nonnull changedObject, NSString* _Nonnull keypath) {
        weakSelf.observedPropertyLabel.text = [NSString stringWithFormat:@"Observed property value: %@", weakSelf.timerValue];
    }];
}

- (IBAction) removeSubscriberToProperty:(id)sender
{
    [[SDEventBus sharedManager] removeSubscriber:self toObject:self];
}

- (IBAction) addSubscriberToChannel:(id)sender
{
    __weak typeof (self) weakSelf = self;
    [[SDEventBus sharedManager] addSubscriber:self toChannelWithName:CHANNEL_NAME withCompletion:^(id _Nonnull publishedObject) {
        weakSelf.observedChannelLabel.text = [NSString stringWithFormat:@"Observed channel value:\n%@", publishedObject];
    }];
}

- (IBAction) sendMessageToChannell:(id)sender
{
    [[SDEventBus sharedManager] publishObject:[NSString stringWithFormat:CHANNEL_OBJECT, rand()] onChannelWithName:CHANNEL_NAME options:kPublishOptionNone];
}

- (IBAction) removeSubscriberToChannel:(id)sender
{
    [[SDEventBus sharedManager] removeSubscriber:self toChannelWithName:CHANNEL_NAME];
}

- (void) timerUpdate
{
    self.timerValue = @(self.timerValue.intValue + TIME_INTERVAL);
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
