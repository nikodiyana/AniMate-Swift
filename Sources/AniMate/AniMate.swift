//
//  AniMate.swift
//
//
//  AniMate animation library main implementation.
//
//  MIT License, Copyright (C) 2023 Niko Di Yana



import Foundation



/// An animation
public class AniMate {
    // Global
    //
    public enum Properties {
        case from(Double)
        case to(Double)
        case duration(Double)
        case timingFunction(TimingFunctionCurve?)
        case autoreverse(Bool)
        case `repeat`(UInt64)
        case startOffset(Double)
        case autoreverseOffset(Double)
        case speed(Double)
        
        public static var repeatForever: Self { .repeat(.max) }
    }
    
    /// Sets the global speed factor for all AniMate instances
    public static var masterSpeed: Double = 1
    
    
    // Time
    //
    /// Pulse Generator for the animation
    public lazy var pulseGenerator: AniMateGenerator = DisplayLinkGenerator(for: self)
    
    var lastTimestamp: Double = 0,
        epsilon: Float = 0.02, // For default duration of 0.25s
        time: Double = 0
                            
    /// Current animation progress, expressed in 0 to 1.0
    public private(set) var progress: Double = 0
    
    public var timeOffset: Double {
        set {
            time = min(newValue, duration)
            progress = time/duration
            updateValue()
        }
        get {
            return time
        }
    }
    
    // Running status
    //
    /// A flag indicating the animation is running
    public internal(set) var running = false
    
    /// A flag indicating the animation has started after the startOffset time
    public internal(set) var pendingStart = true
    
    /// A flag indicating the animation is currently going in reverse
    public private(set) var reversing = false
    
    /// The number of the repeats left
    public private(set) var repeatCountLeft: UInt64 = 1
    
    
    // User settings
    //
    /// Sets the animation autoreverse mode
    public var autoreverse = false
    
    /// Sets the animation pause mode
    public var paused = false
    
    /// Sets the animation speed factor. Default is 1.
    public var speed: Double = 1
    
    /// Sets the amount of time in seconds before the animation should beging after a start command
    public var startOffset: Double = 0
    
    /// Sets the amount of time in seconds before the animation should beging going in reverse
    public var autoreverseOffset: Double = 0
    
    /// Sets the timing function (easing) of the animation
    ///
    /// Setting this property to `nil` will resut a linear timing function (no easing).
    /// See TimingFunctionCurve for possible easing options
    public var timingFunction: TimingFunction?
    
    /// Sets how many time the animation should repeat
    ///
    /// When `autoreverse = true` the next repeat cycle starts after the reversing ends.
    public var repeatCount: UInt64 = 1 {
        didSet { repeatCountLeft = repeatCount }
    }
    
    /// Sets the duration of the animation
    public var duration: Double = 0.25 {
        didSet {
            if (time >= 0 && time <= duration) {
                time = progress * duration
            }
            if (duration > 0) { // Protect epsilon to be not 0, which causes endless loop in Timing Function
                epsilon = 1/(200 * Float(duration))
            }
        }
    }
    
    
    // Callbacks
    //
    /// Closure called on animation start (after timeOffset has passed)
    public var didStart: (() -> Void)?
    
    /// Closure called each time the animation updates the current value
    public var didUpdate: ((_ value: Double) -> Void)?
    
    /// Closure called each time the animation ends and will repeat again
    public var willRepeat: ((_ repeatsLeft: UInt64) -> Void)?
    
    /// Closure called when the animation stops
    public var didStop: (() -> Void)?
    
    
    // Values
    //
    /// The value the animations should start from
    public var fromValue: Double = 0
    
    /// The current value of the animation
    public private(set) var currentValue: Double = 0
    
    /// The value the animations should end to
    public var toValue: Double = 1
    
    
    
    /// Animation properties
    public var properties: [AniMate.Properties] {
        set {
            newValue.forEach {
                switch $0 {
                    case let .from(value): fromValue = value
                    case let .to(value): toValue = value
                    case let .duration(value): duration = value
                    case let .autoreverse(state): autoreverse = state
                    case let .repeat(count): repeatCount = count
                    case let .timingFunction(name): timingFunction = name != nil ? .init(with: name!) : nil
                    case let .startOffset(value): startOffset = value
                    case let .autoreverseOffset(value): autoreverseOffset = value
                    case let .speed(value): speed = value
                }
            }
        }
        get {
            [
                .from(fromValue),
                .to(toValue),
                .duration(duration),
                .autoreverse(autoreverse),
                .repeat(repeatCount),
                .timingFunction(timingFunction?.curve),
                .startOffset(startOffset),
                .autoreverseOffset(autoreverseOffset),
                .speed(speed)
            ]
        }
    }
    
    /// Initializes an animation with possible properties passed as parameters
    public init(_ properties: Properties...) {
        self.properties = properties
    }
    
    /// Initializes an animation with properties array
    public init(properties: [Properties]) {
        self.properties = properties
    }
    
    
    func prepare() {
        pendingStart = true
        paused = false
        reversing = false
        repeatCountLeft = repeatCount
        time = -startOffset
    }
        
    @objc func tick(timestamp: Double) {
        // Get time difference since last pulse
        let timeDiff = (timestamp - lastTimestamp) * speed * AniMate.masterSpeed
        lastTimestamp = timestamp
        
        if paused { return }
        
        // Accumulate time
        time += timeDiff
        
        // Active animating
        if (time >= 0 && time < duration) {
            if pendingStart {
                pendingStart = false
                didStart?()
            }
            progress = time/duration
            if reversing { progress = 1 - progress }
            updateValue()
        }
        
        // End condition
        if (time >= duration) {
            if autoreverse {
                if reversing {
                    reversing = false
                    progress = 0
                    updateValue()
                    onTimeEnd()
                } else {
                    reversing = true
                    if autoreverseOffset == 0 {
                        progress = 2 - time/duration // Apply overflowed time
                    } else {
                        progress = 1
                    }
                    updateValue()
                    time = -autoreverseOffset
                }
            } else {
                progress = 1
                updateValue()
                onTimeEnd()
            }
        }
    }
    
    
    
    func onTimeEnd() {
        if repeatCountLeft > 1 {
            time = -startOffset
            if repeatCount != .max { repeatCountLeft -= 1 } // Check for counteless repeat
            willRepeat?(repeatCountLeft)
        } else {
            stop()
        }
    }
    
    
    /// Manually update the current value
    ///
    /// This function may be called when the animation is stopped. In case the `fromValue` or `toValue` are altered when the animation is not running, calling
    /// this function updates the `currentValue` based on the current `progress` value
    public func updateValue() {
        // Apply timing fucntion to progress
        let timedProgress = timingFunction?.curve.solve(Float(progress), epsilon) ?? progress
        
        // Interpolate between the values with timed progress
        currentValue = fromValue + timedProgress * (toValue - fromValue)
        
        // Call closure
        didUpdate?(currentValue)
    }
   
    
    
    /// Starts the animation
    ///
    /// Calling this function resets animation time to 0, `reversing` status to false and `paused` status to false.
    /// Properties can be passed as parameters
    public func start(_ properties: AniMate.Properties...) {
        self.properties = properties
        prepare()
        if !running { lastTimestamp = pulseGenerator.start() }
        running = true
    }
    
    /// Starts the animation from the current value to the new value
    ///
    /// Can be called when the animation is running.
    public func start(toValue: Double) {
        fromValue = currentValue
        self.toValue = toValue
        start()
    }
    
    /// Stops the animation
    public func stop() {
        pulseGenerator.stop()
        running = false
        paused = false
        didStop?()
    }
}
