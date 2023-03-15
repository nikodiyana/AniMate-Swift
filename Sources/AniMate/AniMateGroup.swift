//
//  AniMateGroup.swift
//
//
//  Group many AniMate animations with common frequency generator.
//
//  MIT License, Copyright (C) 2023 Niko Di Yana


import Foundation



public class AniMateGroup: AniMate {
    
    public var animations = NSHashTable<AniMate>.weakObjects()
            
    override func tick(timestamp: Double) {
        // Get time difference since last pulse
        let timeDiff = (timestamp - lastTimestamp) * speed
        lastTimestamp = timestamp
        
        if paused { return }
        
        // Accumulate time
        time += timeDiff
        
        // Change the duration based on master speed setting
        // The master speed setting is applied in subanimations, not here
        let durationForSpeed = duration / AniMate.masterSpeed
        
        // Active animating
        if (time >= 0 && time < durationForSpeed) {
            if pendingStart {
                pendingStart = false
                didStart?()
            }
            dispatchTimestamp(timestamp: timestamp)
        }
        
        // End condition
        if (time >= durationForSpeed) {
            dispatchTimestamp(timestamp: timestamp)
            onTimeEnd()
            if repeatCountLeft > 1 {
                animations.allObjects.forEach { $0.time = -$0.startOffset }
            }
        }
    }
    
    private func dispatchTimestamp(timestamp: Double) {
        animations.allObjects.forEach {
            (animation) in
            if animation.running {
                animation.tick(timestamp: timestamp)
            }
        }
    }
    
    public override func start(_ properties: AniMate.Properties...) {
        self.properties = properties
        super.start()
        animations.allObjects.forEach {
            (animation) in
            animation.prepare()
            animation.lastTimestamp = lastTimestamp
            animation.running = true
        }
    }
   
    public func startFromCurrentValue() {
        animations.allObjects.forEach {
            (animation) in
            animation.fromValue = animation.currentValue
        }
        start()
    }
}
