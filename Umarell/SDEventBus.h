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

#import <Foundation/Foundation.h>

typedef void (^ PublishSubscribeBlock)(id _Nonnull publishedObject);
typedef void (^ PublishSubscribeKVOBlock)(id _Nonnull changedObject, NSString* _Nonnull keypath);

/**
 *   Persistence options of the object after that it's published on the channel.
 */
typedef NS_ENUM (NSUInteger, PublishOption)
{
    kPublishOptionNone                  = 0,    // The object is not persisted
    kPublishOptionKeepInMemory          = 1,    // Persistence in memory
    kPublishOptionPersistOnUserDefaults = 2     // Persistence into NSUserDefaults (the object must conform NSCoding protocol)
};

/**
 *  Options for subscribers.
 */
typedef NS_ENUM (NSUInteger, SubscribeOption)
{
    kSubscribeOptionNone                  = 0,  // the subscriber will be notified only if an object is published in the channel after his subscription
    kSubscribeOptionReadPrevious          = 1,  // the subscriber is immediately notified with the last object previously published on channel.
};

@interface SDEventBus : NSObject

#pragma mark - Singleton Pattern

/**
 *  Retrieves and returns the singleton instance.
 *
 *  @return The SDEventBus singleton.
 */
+ (_Nullable instancetype) sharedInstance;


#pragma mark Subscribers

/**
 *  Add a subscriber to the given channel.
 *
 *  @param subscriber   The object that subscribes to the channel.
 *  @param channelName  The name of the channel.
 *  @param options      Option for the subscription. See `SubscribeOption` enum for more infos.
 *  @param completion   Block called when an object is published through the channel.
 */
- (void) addSubscriber:(id _Nonnull)subscriber toChannelWithName:(NSString* _Nonnull)channelName options:(SubscribeOption)option withCompletion:(PublishSubscribeBlock _Nullable)completion;

/**
 *  Add a subscriber to the given channel.
 *
 *  @param subscriber   The object that subscribes to the channel.
 *  @param channelName  The name of the channel.
 *  @param completion   Block called when an object is published through the channel.
 */
- (void) addSubscriber:(id _Nonnull)subscriber toChannelWithName:(NSString* _Nonnull)channelName withCompletion:(PublishSubscribeBlock _Nullable)completion;

/**
 *  Remove the subscriber from the given channel.
 *
 *  @discussion It's not necessary to remove the subscriber before its deallocation.
 *
 *  @param subscriber  The object that unsubscribe to the channel.
 *  @param channelName The channel name.
 */
- (void) removeSubscriber:(id _Nonnull)subscriber toChannelWithName:(NSString* _Nonnull)channelName;

/**
 *  Remove the subscriber from all channels.
 *
 *  @param subscriber The object that unsubscribe to all channels.
 */
- (void) removeSubscriber:(id _Nonnull)subscriber;


/**
 *  Retrieves the last object published on the given channel.
 *
 *  @param channelName     The name of the channel.
 *
 *  @return The last object published on the channel.
 */
- (id _Nullable) getPublishedObjectOnChannelWithName:(NSString* _Nonnull)channelName;



#pragma mark Publishers

/**
 *  Publish an object on the given channel.
 *
 *  @param object      The object to publish
 *  @param channelName The name of the channel.
 *  @param option      The persistence option for the published object (see `PublishOption` for more infos).
 */
- (void) publishObject:(id _Nonnull)object onChannelWithName:(NSString* _Nonnull)channelName options:(PublishOption)option;

/**
 *  Publish an object on the given channel.
 *
 *  @param object      The object to publish
 *  @param channelName The name of the channel.
 *
 *  @discussion         This method use the `kPublishOptionNone` persistence option.
 */
- (void) publishObject:(id _Nonnull)object onChannelWithName:(NSString* _Nonnull)channelName;


#pragma mark Flush

/**
 *  Remove the persisted object for the given channel. The object is removed from memory or from NSUserDefaults, depending by the persistence option used when the object was published.
 *
 *  @param channelName  The name of the channel.
 */
- (void) flushObjectOfChannelWithName:(NSString* _Nonnull)channelName;

/**
 *  Remove all the persisted object from memory and NSUserDefaults.
 */
- (void) flushAllObjects;



#pragma mark KVO Wrapper

/**
 *  Adds a subscriber to an object's keypath. This method automatically creates a channel dedicated to the pair `object-keyPath` if it doesn't exist yet.
 *
 *  @param subscriber The subscriber to KVO channel.
 *  @param object     The object to observe.
 *  @param keyPath    The keypath to observe.
 *  @param completion The block called at every value change.
 */
- (void) addSubscriber:(id _Nonnull)subscriber toObject:(id _Nonnull)object keyPath:(NSString* _Nonnull)keyPath withCompletion:(PublishSubscribeKVOBlock _Nullable)completion;


/**
 *  Adds a subscriber to an object's keypaths list. This method automatically creates a dedicated channel for every keypath in the list, if it doesn't exist yet.
 *
 *  @param subscriber The subscriber to KVO channels.
 *  @param object     The object to observe.
 *  @param keyPaths   The list of keypaths to observe.
 *  @param completion The block called at every value change.
 */
- (void) addSubscriber:(id _Nonnull)subscriber toObject:(id _Nonnull)object keyPaths:(NSArray<NSString*>* _Nonnull)keyPaths withCompletion:(PublishSubscribeKVOBlock _Nullable)completion;


/**
 *  Adds a subscriber to all properties of the given object.
 *
 *  @param subscriber The subscriber to KVO channels.
 *  @param object     The object to observe.
 *  @param completion The block called at every value change.
 */
- (void) addSubscriber:(id _Nonnull)subscriber toObject:(id _Nonnull)object withCompletion:(PublishSubscribeBlock _Nullable)completion;


/**
 *  Removes the subscriber from the channel dedicated to the pair `object-keyPath`. The channel will be deleted, if it has no more subscribers.
 *
 *  @param subscriber The subscriber to remove.
 *  @param object     The observed object.
 *  @param keyPath    The observed keypath.
 */
- (void) removeSubscriber:(id _Nonnull)subscriber toObject:(id _Nonnull)object keyPath:(NSString* _Nonnull)keyPath;

/**
 *  Remove the subscriber from all the keyPaths of the given object.
 *
 *  @param subscriber The subscriber to remove.
 *  @param object     The observed object.
 */
- (void) removeSubscriber:(id _Nonnull)subscriber toObject:(id _Nonnull)object;

@end
