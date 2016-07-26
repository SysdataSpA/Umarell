# Umarell 
## Summary
> [*Introduction*](#introduction)
> 
> [*The Event Bus*](#the-event-bus)
> 
> > [*Channel subscription*](#channel-subscription)
> > 
> > [*Publish messages on a channel*](#publish-messages-on-a-channel)
>
>	[*SDEventBus as KVO wrapper*](#sdeventbus-as-kvo-wrapper)

Introduction
============

**Umarell** is a easy-to-use library that makes simple the implementation of the Publish-Subscribe pattern in Objective-C. 

The Event Bus
====================
**Umarell** is based on the class SDEventBus that represents an event bus and can be used as a singleton through its class method ```sharedManager```.

Any object can publish a message through a channel and any other object can subscribe to the channel to receive messages inside a block.

In a similar way, SDEventBus wraps KVO to use it with completion blocks, instead of the uncomfortable method provided by the SDK.

### Channel subscription

An object can subscribe to a channel with a name of your choice calling the method of the SDEventBus:

```
- (void) addSubscriber:(id)subscriber toChannelWithName:(NSString*)channelName withCompletion:(PublishSubscribeBlock)completion
```

or in alternative, if you want to indicate a SubscribeOption:

```
- (void) addSubscriber: toChannelWithName:(NSString*)channelName options:(SubscribeOption)option withCompletion:(PublishSubscribeBlock)completion
```

**SubscribeOption** is an enum with two values. The default value is ```kSubscribeOptionNone```. Adding a subscriber, you can indicate the value ```kSubscribeOptionReadPrevious``` and the subscriber will be immediately notified with the last message previously published on the channel, if there's one.
The last message will be notified only if, at the moment of its publishing, the publisher did indicate a **PublishOption** that required some form of persistence.

You can remove a subscription from a single channel calling:

```
- (void) removeSubscriber:(id)subscriber toChannelWithName:(NSString*)channelName
```

To remove the subscription of a subscriber from all channels, use:

```
- (void) removeSubscriber:(id)subscriber
```

It's **not** required to remove a subscription before the subscriber is deallocated.

### Publish messages on a channel

An object can publish a message on a channel calling the method of the SDEventBus:

```
- (void) publishObject:(id)object onChannelWithName:(NSString*)channelName
```

The message can be an object of any class.

Alternatively, if you want to indicate some form of persistence, use the method:

```
- (void) publishObject:(id)object onChannelWithName:(NSString*)channelName options:(PublishOption)option
```

**PublishOption** is an enum with three values. The default is ```kPublishOptionNone``` that indicates no persistence of the message.
The ```kPublishOptionKeepInMemory``` indicates that the message must be persisted in memory.
The ```kPublishOptionPersistOnUserDefaults``` indicates that the message must be persisted in NSUserDefaults.

You can delete a persisted message with ```flush``` methods.

SDEventBus as KVO wrapper
============================

You can use the SDEventBus as a wrapper of Key-Value Observing system provided by the SDK (known as KVO). It has the advantage to receive the changes in a dedicated completion block, that is more comfortable than a separated method. It's **not** required to remove the subscription when the subscriber is deallocated.

Like standard KVO, **you cannot observe the assignment or the *nilification* of the observed object, but only of his properties**.

Instead of a simple channel, the SDEventBus instantiate a KVO channel. KVO channels have only a difference with simple channels:
>	You cannot indicate a name for the channel. The name is automatically created using the pair ***observed_object-keypath***.

To observe a single keypath of an object, use:

```
- (void) addSubscriber:(id)subscriber toObject:(id)object keyPath:(NSString*)keyPath withCompletion:(PublishSubscribeKVOBlock)completion
```

Or you can pass a list of keypaths with:

```
- (void) addSubscriber:(id)subscriber toObject:(id)object keyPaths:(NSArray<NSString*>*)keyPaths withCompletion:(PublishSubscribeKVOBlock)completion
```

Another possibility is to observe all properties of an object:

```
- (void) addSubscriber:(id)subscriber toObject:(id)object withCompletion:(PublishSubscribeBlock)completion
```

To remove the subscription to a KVO channel use one of the two methods:

```
- (void) removeSubscriber:(id)subscriber toObject:(id)object keyPath:(NSString*)keyPath

- (void) removeSubscriber:(id)subscriber toObject:(id)object
```

