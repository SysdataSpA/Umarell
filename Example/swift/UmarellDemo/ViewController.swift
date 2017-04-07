//
//  ViewController.swift
//  UmarellDemo
//
//  Created by Guido Sabatini on 07/04/17.
//  Copyright © 2017 Sysdata SpA. All rights reserved.
//

import UIKit
import Umarell

let TIME_INTERVAL = 1
let CHANNEL_NAME = "My channel name"

class ViewController: UIViewController {

    dynamic var timerValue = NSNumber(value: 0)
    var observedTimer: Timer?
    
    @IBOutlet weak var observedPropertyLabel: UILabel!
    @IBOutlet weak var observedChannelLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @objc
    func timerUpdate() {
        timerValue = NSNumber(value: self.timerValue.intValue + TIME_INTERVAL) 
        print(timerValue)
    }
    
// MARK: IBActions
    
    @IBAction func addSubscriberToProperty(_ sender: Any) {
        if observedTimer == nil {
            observedTimer =  Timer.scheduledTimer(timeInterval: TimeInterval(TIME_INTERVAL), target: self, selector: #selector(ViewController.timerUpdate), userInfo: nil, repeats: true)
        }
        SDEventBus.sharedInstance()?.addSubscriber(self, to: self, keyPath: "timerValue", withCompletion: { [weak self] (changedObject: Any, keypath: String) in
            guard self != nil else { return }
            self!.observedPropertyLabel.text = "Observed property value: \(self!.timerValue)"
        })
    }
    
    @IBAction func removeSubscriberToProperty(_ sender: Any) {
        observedTimer?.invalidate()
        SDEventBus.sharedInstance()?.removeSubscriber(self, to: self)
    }

    @IBAction func addSubscriberToChannel(_ sender: Any) {
        SDEventBus.sharedInstance()?.addSubscriber(self, toChannelWithName: CHANNEL_NAME, withCompletion: { [weak self] (publishedObject: Any) in
            guard self != nil else { return }
            self!.observedChannelLabel.text = "Observed channel value:\n\(publishedObject)"
        })
    }
    
    @IBAction func sendMessageToChannel(_ sender: Any) {
        SDEventBus.sharedInstance()?.publishObject("Channel message - \(arc4random_uniform(1000))", onChannelWithName: CHANNEL_NAME, options: .none)
    }
    
    @IBAction func removeSubscriberToChannel(_ sender: Any) {
        SDEventBus.sharedInstance()?.removeSubscriber(self, toChannelWithName: CHANNEL_NAME)
    }

}

