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

#import "SDEventBus.h"
#import "NSObject+SDEventBus.h"

// This code is compatible with our logger "Plinio".
#ifdef SD_LOGGER_AVAILABLE
#import "SDLogger.h"
#else
#define SDLogError(frmt, ...)   NSLog(frmt, ##__VA_ARGS__)
#define SDLogWarning(frmt, ...) NSLog(frmt, ##__VA_ARGS__)
#define SDLogInfo(frmt, ...)    NSLog(frmt, ##__VA_ARGS__)
#define SDLogVerbose(frmt, ...) NSLog(frmt, ##__VA_ARGS__)
#endif

// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------

/**
 *  This class represents a single subscription of an object to a channel.
 */
@interface SDEventBusSubscriptionInfo : NSObject

/**
 *  Weak reference to the subscriber.
 */
@property (nonatomic, weak, nullable) id subscriber;

/**
 *  Useful to identify the subscriber during its dealloc (the weak reference is not enough).
 */
@property (nonatomic, strong, nullable) NSString* subscriberIdentifier;

/**
 *  The completion block called when an object is published on the channel.
 */
@property (nonatomic, strong, nullable) PublishSubscribeBlock completionBlock;

/**
 *  The completion block called when the value of the observed property changes.
 */
@property (nonatomic, strong, nullable) PublishSubscribeKVOBlock completionKVOBlock;

@end

// ----------------------------------------------------------------------------------------------------------

@implementation SDEventBusSubscriptionInfo

/**
 *  Calculates and returns the subscriberIdentifier for the given subscriber.
 *
 *  @param subscriber   The subscriber.
 *
 *  @return             The identifier of the subscriber.
 */
+ (NSString*) uniqueIdentifierForSubscriber:(id _Nonnull)subscriber
{
    NSString* identifier;
    if([subscriber respondsToSelector:@selector(instanceUniqueIdentifier)])
    {
        identifier = [subscriber performSelector:@selector(instanceUniqueIdentifier)];
    }
    else
    {
        identifier = [NSString stringWithFormat:@"%lu_%p",(unsigned long)[subscriber hash], subscriber];
    }
    
    return identifier;
}

@end



// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------

/**
 *  This class represents a single channel (simple or KVO).
 */
@interface SDEventBusChannel : NSObject

/**
 *  The channel name. For KVO channels it is setted automatically.
 */
@property (nonatomic, strong, nonnull) NSString* channelName;

/**
 *  The observed object.
 */
@property (nonatomic, strong, nullable) id object;

/**
 *  The persistence option for objects published on the channel.
 */
@property (nonatomic, assign) PublishOption publishOption;

/**
 *  All the subscriptions of this channel.
 */
@property (nonatomic, strong, nonnull) NSMutableArray<SDEventBusSubscriptionInfo*>* subscriptions;

// ----------------------
// Only for KVO channels.
// ----------------------

/**
 *  It indicates if it is a KVO channel.
 */
@property (nonatomic, assign) BOOL kvoActive;

/**
 *  The observed object in case this is a KVO channel.
 */
@property (nonatomic, strong, nullable) id kvoObject;

/**
 *  The observed keyPath in case this is a KVO channel.
 */
@property (nonatomic, strong, nullable) NSString* kvoKeyPath;

/**
 *  Retrieves the subscription for the given subscriber. If requested, it creates a new subscription and stores it in subscriptions list.
 *
 *  @param subscriber  The subscriber.
 *  @param createIfNil If there's no subscriptions for the given subscriber and this flag is YES, the method creates a new subscription e stores it in subscriptions list.
 *
 *  @return The subscription for the given subscriber or `nil`.
 */
- (SDEventBusSubscriptionInfo* _Nullable) infoForSubscriber:(id _Nonnull)subscriber createIfNil:(BOOL)createIfNil;

@end

@implementation SDEventBusChannel

- (id) init
{
    self = [super init];
    if (self)
    {
        _subscriptions = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (SDEventBusSubscriptionInfo*) infoForSubscriber:(id)subscriber createIfNil:(BOOL)createIfNil
{
    NSString* subscriberIdentifier = [SDEventBusSubscriptionInfo uniqueIdentifierForSubscriber:subscriber];
    SDEventBusSubscriptionInfo* info = [self.subscriptions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"subscriberIdentifier = %@", subscriberIdentifier]].firstObject;
    
    if (!info && createIfNil)
    {
        info = [SDEventBusSubscriptionInfo new];
        info.subscriber = subscriber;
        info.subscriberIdentifier = [SDEventBusSubscriptionInfo uniqueIdentifierForSubscriber:subscriber];
        
        [self.subscriptions addObject:info];
    }
    
    return info;
}

@end



// -----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------


@interface SDEventBus ()

/**
 *  List of channels. The key is the name of the channel.
 */
@property (nonatomic, strong, nonnull) NSMutableDictionary<NSString*, SDEventBusChannel*> * channels;

@end

@implementation SDEventBus


#pragma mark - Singleton Pattern

+ (instancetype) sharedInstance
{
    static dispatch_once_t pred;
    static id sharedInstance_ = nil;
    
    dispatch_once(&pred, ^{
        sharedInstance_ = [[self alloc] init];
    });
    
    return sharedInstance_;
}

#pragma mark - Load methods

- (id) init
{
    self = [super init];
    if (self)
    {
        _channels = [NSMutableDictionary new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

/**
 *  Retrieves the channel with the given name.
 *
 *  @param channelName The name of the channel.
 *  @param createIfNil If YES and the channel doesn't exist yet, the method creates a new channel with the given name.
 *
 *  @return The channel or `nil`.
 */
- (SDEventBusChannel* _Nullable) channelWithName:(NSString* _Nonnull)channelName createIfNil:(BOOL)createIfNil
{
    SDEventBusChannel* channel = [self.channels objectForKey:channelName];
    
    if (!channel && createIfNil)
    {
        // if it doesn't exist, it creates a new channel.
        channel = [self createChannelWithName:channelName];
    }
    return channel;
}

/**
 *  Creates a new channel with the given name.
 *
 *  @param channelName The name of the channel.
 *
 *  @return The new channel.
 */
- (SDEventBusChannel* _Nonnull) createChannelWithName:(NSString* _Nonnull)channelName
{
    SDEventBusChannel* channel = [SDEventBusChannel new];
    
    channel.channelName = channelName;
    [self.channels setObject:channel forKey:channelName];
    
    return channel;
}

/**
 *  Deletes a channel if it has no more subscriptions.
 *
 *  @param channel The channel to delete if it's unused.
 */
- (void) releaseIfUnusedChannel:(SDEventBusChannel* _Nonnull)channel
{
    if (channel.subscriptions.count == 0)
    {
        if (channel.kvoActive)
        {
            // If it's a KVO channel, remove the observer before deleting the channel.
            [self deleteAutomaticPublisherChannelOnObject:channel.kvoObject keyPath:channel.kvoKeyPath];
        }
        
        [self.channels removeObjectForKey:channel.channelName];
        SDLogVerbose(@"Channel with 0 subscribers deleted: channel=%@", channel.channelName);
    }
}

/**
 *  Releases the subscriptions of the given channel that have no subscriber (because it has been deallocated)
 *
 *  @param channel The channel to clean.
 */
- (void) releaseSubscriptionInfosWithoutSubscriberOnChannel:(SDEventBusChannel* _Nonnull)channel
{
    NSMutableArray* infosCopy = [channel.subscriptions mutableCopy];
    
    for (SDEventBusSubscriptionInfo* info in channel.subscriptions)
    {
        if (!info.subscriber)
        {
            // The subscriber has been deallocated, remove the subscription.
            [infosCopy removeObject:info];
        }
    }
    channel.subscriptions = infosCopy;
}

/**
 *  Creates the name for a KVO channel.
 *
 *  @param object  The object observer on the channel.
 *  @param keyPath The keyPath observed on the channel.
 *
 *  @return The name for the KVO channel.
 */
- (NSString* _Nullable) getChannelNameForObject:(id _Nullable)object keyPath:(NSString* _Nullable)keyPath
{
    if (!keyPath || !object)
    {
        return nil;
    }
    return [NSString stringWithFormat:@"%lu_%@", [object hash], keyPath];
}

/**
 *  Retrieves the KVO channel for a pair `object-keyPath`.
 *
 *  @param object  The kvoObject of the channel.
 *  @param keyPath The kvoKeyPath of the channel.
 *
 *  @return The channel for the given pair or `nil`.
 */
- (SDEventBusChannel* _Nullable) getChannelForObject:(id _Nonnull)object keyPath:(NSString* _Nonnull)keyPath
{
    SDEventBusChannel* channel = [self.channels.allValues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"kvoObject = %@ && kvoKeyPath = %@", object, keyPath]].firstObject;
    
    return channel;
}

/**
 *  Retrieves all the KVO channels for the given object.
 *
 *  @param object The kvoObject.
 *
 *  @return A list of all the channels that have the given object as "kvoObject".
 */
- (NSArray<SDEventBusChannel*>*) getAllChannelsForObject:(id _Nonnull)object
{
    return [self.channels.allValues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"kvoObject = %@", object]];
}

#pragma mark Subscribers


- (void) addSubscriber:(id _Nonnull)subscriber toChannelWithName:(NSString* _Nonnull)channelName withCompletion:(PublishSubscribeBlock _Nullable)completion
{
    [self addSubscriber:subscriber toChannelWithName:channelName options:kSubscribeOptionNone withCompletion:completion];
}

- (void) addSubscriber:(id _Nonnull)subscriber toChannelWithName:(NSString* _Nonnull)channelName options:(SubscribeOption)option withCompletion:(PublishSubscribeBlock _Nullable)completion
{
    [self addSubscriber:subscriber toChannelWithName:channelName options:option completion:completion kvoCompletion:nil];
}

/**
 *  Internal method to add a subscriber to the given channel.
 *
 *  @param subscriber       The object that subscribes the channel.
 *  @param channelName      The name of the channel.
 *  @param options          Option for the subscription. See `SubscribeOption` enum for more infos.
 *  @param completion       Block called when an object is published through the channel.
 *  @param kvoCompletion    Block called when the value of the observer keyPath changes.
 */
- (void) addSubscriber:(id _Nonnull)subscriber toChannelWithName:(NSString* _Nonnull)channelName options:(SubscribeOption)option completion:(PublishSubscribeBlock _Nullable)completion kvoCompletion:(PublishSubscribeKVOBlock _Nullable)kvoCompletion
{
    SDEventBusChannel* channel = [self channelWithName:channelName createIfNil:YES];
    SDEventBusSubscriptionInfo* info = [channel infoForSubscriber:subscriber createIfNil:YES];
    
    info.completionBlock = completion;
    info.completionKVOBlock = kvoCompletion;
    
    if (option == kSubscribeOptionReadPrevious)
    {
        // in this case it publishes the last published object to the subscriber.
        id previousObject = [self getPublishedObjectOnChannelWithName:channelName];
        if (completion)
        {
            completion(previousObject);
        }
    }
    SDLogVerbose(@"Subscriber added to channel: subscriber=%@ channel=%@", subscriber, channelName);
}

- (void) removeSubscriber:(id _Nonnull)subscriber toChannelWithName:(NSString* _Nonnull)channelName
{
    SDEventBusChannel* channel = [self channelWithName:channelName createIfNil:NO];
    
    if (channel)
    {
        [self removeSubscriber:subscriber toChannel:channel];
    }
}

- (void) removeSubscriber:(id _Nonnull)subscriber
{
    for (SDEventBusChannel* channel in self.channels.allValues)
    {
        [self removeSubscriber:subscriber toChannel:channel];
    }
}

/**
 *  Internal method to remove a subscriber from the given channel.
 *
 *  @param subscriber The subscriber to remove.
 *  @param channel    The channel.
 */
- (void) removeSubscriber:(id _Nonnull)subscriber toChannel:(SDEventBusChannel* _Nonnull)channel
{
    SDEventBusSubscriptionInfo* info = [channel infoForSubscriber:subscriber createIfNil:NO];
    
    if (info)
    {
        [channel.subscriptions removeObject:info];
        SDLogVerbose(@"Subscriber removed from channel: subscriber=%@ channel=%@", subscriber, channel.channelName);
    }
    
    // check if it's the case to release the channel
    if (channel.publishOption == kPublishOptionNone)
    {
        [self releaseIfUnusedChannel:channel];
    }
}

- (id _Nullable) getPublishedObjectOnChannelWithName:(NSString* _Nonnull)channelName
{
    SDEventBusChannel* channel = [self channelWithName:channelName createIfNil:NO];
    
    id retreivedObject = channel.object;
    if (!retreivedObject)
    {
        // try to retrieve from NSUserDefaults
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        id unarchivedObject = [userDefaults objectForKey:channelName];
        if (unarchivedObject)
        {
            retreivedObject = [NSKeyedUnarchiver unarchiveObjectWithData:unarchivedObject];
            channel.object = retreivedObject;
            channel.publishOption = kPublishOptionPersistOnUserDefaults;
            
            SDLogVerbose(@"Object retrieved from NSUserDefaults for channel %@", channelName);
        }
    }
    
    return retreivedObject;
}

/**
 *  It notifies all subscribers of the given channel.
 *
 *  @param channel The channel.
 */
- (void) notifySubscribersOfChannel:(SDEventBusChannel* _Nonnull)channel
{
    if (channel.object)
    {
        for (SDEventBusSubscriptionInfo* info in channel.subscriptions.copy)
        {
            if (info.subscriber)
            {
                if (info.completionBlock)
                {
                    info.completionBlock(channel.object);
                }
                
                if (info.completionKVOBlock)
                {
                    info.completionKVOBlock(channel.object, channel.kvoKeyPath);
                }
            }
        }
        
        SDLogVerbose(@"Notification for subscribers of channel %@", channel.channelName);
    }
}

#pragma mark Publishers

- (void) publishObject:(id _Nullable)object onChannelWithName:(NSString* _Nonnull)channelName
{
    [self publishObject:object onChannelWithName:channelName options:kPublishOptionNone];
}

- (void) publishObject:(id _Nullable)object onChannelWithName:(NSString* _Nonnull)channelName options:(PublishOption)option
{
    if (!object)
    {
        SDLogError(@"Cannot publish a nil object! Channel: %@", channelName);
        return;
    }
    
    SDEventBusChannel* channel = [self channelWithName:channelName createIfNil:YES];
    channel.object = object;
    channel.publishOption = option;
    
    [self notifySubscribersOfChannel:channel];
    
    // clean the channel
    [self releaseSubscriptionInfosWithoutSubscriberOnChannel:channel];
    
    // if required, it save the object into NSUserDefaults
    if (option == kPublishOptionPersistOnUserDefaults)
    {
        if ([object conformsToProtocol:@protocol(NSCoding)])
        {
            id archivedObject = [NSKeyedArchiver archivedDataWithRootObject:object];
            if (archivedObject)
            {
                NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
                [userDefaults setObject:archivedObject forKey:channelName];
                [userDefaults synchronize];
                
                SDLogVerbose(@"Object saved into NSUserDefaults for channel %@", channelName);
            }
        }
        else
        {
            SDLogWarning(@"It's not possible to save an object that doesn't conforms NSCoding into NSUserDefaults. The object's class should implement `initWithCoder:` and `encodeWithCoder:`");
        }
    }
    // if the object must not be persisted, delete it.
    else if (option == kPublishOptionNone)
    {
        channel.object = nil;
        
        // and then it checks if the channel must be deleted.
        [self releaseIfUnusedChannel:channel];
    }
}

#pragma mark Flush

- (void) flushObjectOfChannelWithName:(NSString* _Nonnull)channelName
{
    SDEventBusChannel* channel = [self channelWithName:channelName createIfNil:NO];
    
    [self flushObjectOfChannel:channel];
}

- (void) flushAllObjects
{
    for (SDEventBusChannel* channel in self.channels.allValues)
    {
        [self flushObjectOfChannel:channel];
    }
}

/**
 *  Remove the persisted object from the given channel.
 *
 *  @param channel The channel.
 */
- (void) flushObjectOfChannel:(SDEventBusChannel* _Nonnull)channel
{
    if (channel)
    {
        channel.object = nil;
        
        // remove the object from NSUserDefaults too.
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults removeObjectForKey:channel.channelName];
        [userDefaults synchronize];
        
        SDLogVerbose(@"Flush of channel %@", channel.channelName);
    }
}

// --------------------------------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------------------------------------------------------


#pragma mark KVO Wrapper

/**
 *  Internal method that creates a KVO channel for the given pair `object-keyPath`, if needed.
 *
 *  @param object  The object to observe.
 *  @param keyPath The keyPath to observe.
 *
 *  @discussion    The SDEventBus adds itself as observer using the standard KVO and creates a KVO channel where it will publish every change it observes.
 */
- (void) createAutomaticPublisherChannelOnObject:(id _Nonnull)object keyPath:(NSString* _Nonnull)keyPath
{
    // Checks if a channel already exists for the given pair.
    SDEventBusChannel* channel = [self getChannelForObject:object keyPath:keyPath];
    
    if (!channel)
    {
        // Retrieves the new channel name
        NSString* channelName = [self getChannelNameForObject:object keyPath:keyPath];
        
        if (!channelName)
        {
            SDLogWarning(@"You're trying to create a KVO channel with a nil object or a nil keypath.");
            return;
        }
        
        // Adds itself as observer
        [object addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:nil];
        
        // Creates the channel
        SDEventBusChannel* channel = [self channelWithName:channelName createIfNil:YES];
        channel.kvoActive = YES;
        channel.kvoKeyPath = keyPath;
        channel.kvoObject = object;
        channel.publishOption = kPublishOptionNone;
        
        SDLogVerbose(@"KVO channel created: %@ - Keypath: %@", channel.channelName, keyPath);
    }
}

/**
 *  Rimuove il KVO sul keypath dell'oggetto
 *
 *  @param object  oggetto di cui rimuovere il kvo
 *  @param keyPath keypath da cui rimuovere il kvo
 */

/**
 *  Internal method that removes the KVO channel for the given pair `object-keyPath`.
 *
 *  @param object  The object of the pair.
 *  @param keyPath The keypath of the pair.
 */
- (void) deleteAutomaticPublisherChannelOnObject:(id _Nonnull)object keyPath:(NSString* _Nonnull)keyPath
{
    SDEventBusChannel* channel = [self getChannelForObject:object keyPath:keyPath];
    
    if (channel.kvoActive)
    {
        // remove itself as observer
        [object removeObserver:self forKeyPath:keyPath];
        
        [self flushObjectOfChannel:channel];
        
        SDLogVerbose(@"KVO channel deleted %@ - Keypath: %@", channel.channelName, keyPath);
    }
}

- (void) addSubscriber:(id _Nonnull)subscriber toObject:(id _Nonnull)object keyPath:(NSString* _Nonnull)keyPath withCompletion:(PublishSubscribeKVOBlock _Nullable)completion
{
    NSString* channelName = [self getChannelNameForObject:object keyPath:keyPath];
    
    if (channelName)
    {
        // creates the KVO channel if needed
        [self createAutomaticPublisherChannelOnObject:object keyPath:keyPath];
        
        // adds the subscriber to the channel
        [self addSubscriber:subscriber toChannelWithName:channelName options:kSubscribeOptionNone completion:nil kvoCompletion:completion];
        
        SDLogVerbose(@"Subscriber added to KVO channel: subscriber=%@ channel=%@ keyPath=%@", subscriber, channelName, keyPath);
    }
}

- (void) addSubscriber:(id _Nonnull)subscriber toObject:(id _Nonnull)object keyPaths:(NSArray<NSString*>* _Nonnull)keyPaths withCompletion:(PublishSubscribeKVOBlock _Nullable)completion
{
    for (NSString* keyPath in keyPaths)
    {
        [self addSubscriber:subscriber toObject:object keyPath:keyPath withCompletion:completion];
    }
}

- (void) addSubscriber:(id _Nonnull)subscriber toObject:(id _Nonnull)object withCompletion:(PublishSubscribeBlock _Nullable)completion
{
    NSString* keyPath = EVENTBUS_OBSERV_ALL_PROPERTIES_KEYS;
    NSString* channelName = [self getChannelNameForObject:object keyPath:keyPath];
    
    if (channelName)
    {
        // creates the KVO channel if needed
        [self createAutomaticPublisherChannelOnObject:object keyPath:keyPath];
        
        // adds the subscriber to the channel
        [self addSubscriber:subscriber toChannelWithName:channelName options:kSubscribeOptionNone completion:completion kvoCompletion:nil];
        
        SDLogVerbose(@"Subscriber added to KVO for all the properties: subscriber=%@ channel=%@", subscriber, channelName);
    }
}

- (void) removeSubscriber:(id _Nonnull)subscriber toObject:(id _Nonnull)object keyPath:(NSString* _Nonnull)keyPath
{
    SDEventBusChannel* channel = [self getChannelForObject:object keyPath:keyPath];
    
    if (channel)
    {
        [self removeSubscriber:subscriber toChannel:channel];
    }
}

- (void) removeSubscriber:(id _Nonnull)subscriber toObject:(id _Nonnull)object
{
    NSArray* channels = [self getAllChannelsForObject:object];
    
    for (SDEventBusChannel* channel in channels)
    {
        [self removeSubscriber:subscriber toChannel:channel];
    }
}

#pragma mark KVO

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    SDLogVerbose(@"Change observed through KVO on object %@ - keyPath %@", object, keyPath);
    SDEventBusChannel* channel = [self getChannelForObject:object keyPath:keyPath];
    if (channel)
    {
        [self publishObject:object onChannelWithName:channel.channelName options:channel.publishOption];
    }
}

#pragma mark Dealloc

- (void) didReceiveMemoryWarning
{
    SDLogWarning(@"Memory warning received: release all channels without subscribers.");
    for (SDEventBusChannel* channel in self.channels.allValues)
    {
        [self releaseSubscriptionInfosWithoutSubscriberOnChannel:channel];
        [self releaseIfUnusedChannel:channel];
    }
}

- (void) dealloc
{
    SDLogVerbose(@"SDEventBus deallocated");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    
    for (SDEventBusChannel* channel in self.channels.allValues)
    {
        if (channel.kvoActive)
        {
            // remove itself as kvo observer for every KVO channel
            [channel.kvoObject removeObserver:self forKeyPath:channel.kvoKeyPath];
        }
    }
}

@end

