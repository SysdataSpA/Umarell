Umarell
=======

[![Version](https://img.shields.io/cocoapods/v/Umarell.svg?style=flat)](http://cocoapods.org/pods/Umarell)
[![License](https://img.shields.io/cocoapods/l/Umarell.svg?style=flat)](http://cocoapods.org/pods/Umarell)
[![Platform](https://img.shields.io/cocoapods/p/Umarell.svg?style=flat)](http://cocoapods.org/pods/Umarell)

![Alt text](/Icon.png)

Summary
-------

>   [Introduction](#introduction)

>   [The Event Bus](#the-event-bus)

>   [Channel subscription](#channel-subscription)

>   [Publish messages on a channel](#publish-messages-on-a-channel)

>   [SDEventBus as KVO wrapper](#sdeventbus-as-kvo-wrapper)

![Example](/umarell_example.gif)

Introduction
============

**Umarell** is a easy-to-use library that makes simple the implementation of the
Publish-Subscribe pattern in Objective-C.

Installation
=============
You can use both in your Objective-c or Swift App using last available pod

```
pod 'Umarell'
```

If you want to use our logger framework Blabber, use subpod
```
pod 'Umarell/Blabber'
```
With Blabber you can manage all log messages or use CocoaLumberjack. In this case import also the corresponding subpod. [See more](https://github.com/SysdataSpA/Blabber) details...
```
pod 'Umarell/Blabber'
pod 'Blabber/CocoaLumberjack'
```


The Event Bus
=============

**Umarell** is based on the class SDEventBus that represents an event bus and
can be used as a singleton through its class method `sharedInstance`.

Any object can publish a message through a channel and any other object can
subscribe to the channel to receive messages inside a block.

In a similar way, SDEventBus wraps KVO to use it with completion blocks, instead
of the uncomfortable method provided by the SDK.

### Channel subscription

An object can subscribe to a channel with a name of your choice calling the
method of the SDEventBus:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) addSubscriber:(id)subscriber toChannelWithName:(NSString*)channelName withCompletion:(PublishSubscribeBlock)completion
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*swift version*

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
addSubscriber(Any, toChannelWithName: String, withCompletion: PublishSubscribeBlock?)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

or in alternative, if you want to indicate a SubscribeOption:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) addSubscriber: toChannelWithName:(NSString*)channelName options:(SubscribeOption)option withCompletion:(PublishSubscribeBlock)completion
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*swift version*

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
addSubscriber(Any, toChannelWithName: String, options: SubscribeOption, withCompletion: PublishSubscribeBlock?)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

**SubscribeOption** is an enum with two values. The default value is
`kSubscribeOptionNone`. Adding a subscriber, you can indicate the value
`kSubscribeOptionReadPrevious` and the subscriber will be immediately notified
with the last message previously published on the channel, if there's one. The
last message will be notified only if, at the moment of its publishing, the
publisher did indicate a **PublishOption** that required some form of
persistence.

You can remove a subscription from a single channel calling:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) removeSubscriber:(id)subscriber toChannelWithName:(NSString*)channelName
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*swift version*

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
removeSubscriber(Any, toChannelWithName: String)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

To remove the subscription of a subscriber from all channels, use:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) removeSubscriber:(id)subscriber
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*swift version*

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
removeSubscriber(Any)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

It's **not** required to remove a subscription before the subscriber is
deallocated.

### Publish messages on a channel

An object can publish a message on a channel calling the method of the
SDEventBus:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) publishObject:(id)object onChannelWithName:(NSString*)channelName
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*swift version*

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
publishObject(Any?, onChannelWithName: String)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

The message can be an object of any class.

Alternatively, if you want to indicate some form of persistence, use the method:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) publishObject:(id)object onChannelWithName:(NSString*)channelName options:(PublishOption)option
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*swift version*

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
publishObject(Any?, onChannelWithName: String, options: PublishOption)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

**PublishOption** is an enum with three values. The default is
`kPublishOptionNone` that indicates no persistence of the message. The
`kPublishOptionKeepInMemory` indicates that the message must be persisted in
memory. The `kPublishOptionPersistOnUserDefaults` indicates that the message
must be persisted in NSUserDefaults.

You can delete a persisted message with `flush` methods.

 

SDEventBus as KVO wrapper
=========================

You can use the SDEventBus as a wrapper of Key-Value Observing system provided
by the SDK (known as KVO). It has the advantage to receive the changes in a
dedicated completion block, that is more comfortable than a separated method.
It's **not** required to remove the subscription when the subscriber is
deallocated.

Like standard KVO, **you cannot observe the assignment or the nilification of
the observed object, but only of his properties**.

If you want to **observe a var in swift,** it has to be marked as dynamic,
**otherwise KVO wont work**!

From Apple documentation:

>   Apply this modifier to any member of a class that can be represented by
>   Objective-C. When you mark a member declaration with the dynamic modifier,
>   access to that member is always dynamically dispatched using the Objective-C
>   runtime. Access to that member is never inlined or devirtualized by the
>   compiler.

>   Because declarations marked with the dynamic modifier are dispatched using
>   the Objective-C runtime, they’re implicitly marked with the objc attribute.

Instead of a simple channel, the SDEventBus instantiate a KVO channel. KVO
channels have only a difference with simple channels: \> You cannot indicate a
name for the channel. The name is automatically created using the pair
**observed_object-keypath**.

To observe a single keypath of an object, use:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) addSubscriber:(id)subscriber toObject:(id)object keyPath:(NSString*)keyPath withCompletion:(PublishSubscribeKVOBlock)completion
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*swift version*

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
addSubscriber(Any, to: Any, keyPath: String, withCompletion: PublishSubscribeKVOBlock?)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

Or you can pass a list of keypaths with:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) addSubscriber:(id)subscriber toObject:(id)object keyPaths:(NSArray<NSString*>*)keyPaths withCompletion:(PublishSubscribeKVOBlock)completion
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*swift version*

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
addSubscriber(Any, to: Any, keyPaths: [String], withCompletion: PublishSubscribeKVOBlock?)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

Another possibility is to observe all properties of an object:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) addSubscriber:(id)subscriber toObject:(id)object withCompletion:(PublishSubscribeBlock)completion
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*swift version*

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
addSubscriber(Any, to: Any, withCompletion: PublishSubscribeBlock?)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 

To remove the subscription to a KVO channel use one of the two methods:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- (void) removeSubscriber:(id)subscriber toObject:(id)object keyPath:(NSString*)keyPath

- (void) removeSubscriber:(id)subscriber toObject:(id)object
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*swift version*

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
removeSubscriber(Any, to: Any, keyPath: String)

removeSubscriber(Any, to: Any)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


