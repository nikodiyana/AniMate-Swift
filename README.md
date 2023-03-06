# AniMate

A simple general purpose Swift animation library. With iOS/MacOS support out of the box.

Version 1.3.1 
Copyright (C) 2023 Niko Di Yana, MIT License
***



AniMate is a simple lightweight animation library, written in Swift. AniMate does not rely on Apple's Core Graphics framework, which means anything can be animated.
The animations provide progress update callback which exposes the animated value. The animations are mutable, which means you can reuse them and modify their properties even while running.

By default, AniMate uses `CADisplayLink` (`CVDisplayLink` on MacOS) as a frequency generator, which provides smooth, screen-synchronized frame rate. A custom frequency generator, like NSTimer, can be used for specific frame rates.


## Install
Set this package as a dependancy in your Xcode Project "Package Dependancy" panel.


## Quick start
Create the animation:

    let animation = AniMate()

Then use it:

    animation.duration = 5                  // Set the animation to last five seconds
    animation.fromValue = 0                 // Set the animation start value
    animation.toValue = 25                  // Set the animation end value
    animation.didUpdate = {                 // This closure will be called on each animation frame
        (value) in
        print("Current value is: \(value))   
    }
    animation.start()                       // Start the animation

The code will print the values from 0 to 25 on each frame for the duration of 5 seconds. The values are of `Double` type.

The animation properties support declarative syntax, like this:
    
    animation.start(.duration(10), .autoreverse(true), .repeat(3))
    
This code will start the same animation, this time with duration of 10 seconds. With autoreverse set to `true`, the animation will start running
backwards once it reaches its end. Going backwards will output values from 25 to 0. The total forward-reverse cycle will last 20 seconds - 
10 seconds for each direction. 

The repeat setting will cause the animation to repeat the same forward-reverse cycle two more times for a total of three repeats.
Setting `.repeatForever` or passing a `UInt64.max` value to the `repeatCount` property will repeat the animation endlessly. Zero value for `repeatCount` will be ignored.



## Features:
- duration setting
- autoreverse
- repeat with specific count or forever
- pause/resume
- speed factor per animation
- global speed factor
- timing functions (easings) with bezier curves matching Core Animation default curves
- start time offset: the delay before the animation actually commences
- autoreverse offset: the delay before the animation starts in reverse way
- manually set animation time (scrubbing)
- callback closures: events are fired on important animation stages
- grouped animations
- custom frequency generator
    
### Currently not supported:
- Delegate
- Keyframes



## Documentation
From the Xcode menu, choose *Product* -> *Build Documentation* to compile the included in the code DocC documentation.


*The full DocC documentation is currently in progress*
