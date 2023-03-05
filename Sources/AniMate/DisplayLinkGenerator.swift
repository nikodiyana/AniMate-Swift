//
//  CAGenerator.swift
//
//
//  A MacOS and iOS implementation of the AniMateGenerator for pulsing screen framerate animations
//
//  MIT License, Copyright (C) 2023 Niko Di Yana



import QuartzCore



#if os(macOS)

class DisplayLinkGenerator: AniMateGenerator {
    weak public var animation: AniMate!
    var displayLink: CVDisplayLink!
    
    
    
    required public init(for animation: AniMate) {
        self.animation = animation
        
        // Setup CVDisplayLink with a closure
        let displayLinkOutputCallback: CVDisplayLinkOutputCallback = {
            (displayLink: CVDisplayLink,
             inNow: UnsafePointer<CVTimeStamp>,
             inOutputTime: UnsafePointer<CVTimeStamp>,
             flagsIn: CVOptionFlags,
             flagsOut: UnsafeMutablePointer<CVOptionFlags>,
             displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn in
            
            // This closure is currently without context. To call self context class functions:
            let generator = unsafeBitCast(displayLinkContext, to: DisplayLinkGenerator.self)
            
            // Capture the current time in the currentTime property.
            let timestamp = CFTimeInterval(inNow.pointee.hostTime)/1000000000
            
            // Update the animation from the main thead
            DispatchQueue.main.async(qos: .default) {
                generator.animation.tick(timestamp: timestamp)
            }
            return kCVReturnSuccess
        }
        
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink, displayLinkOutputCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        
    }
    
    public func start() -> Double {
        CVDisplayLinkStart(displayLink)
        return CACurrentMediaTime()
    }
    
    public func stop() {
        CVDisplayLinkStop(displayLink)
    }
    
    deinit {
        stop()
    }
}



#elseif os(iOS)

class DisplayLinkGenerator: AniMateGenerator {
    weak public var animation: AniMate!
    var displayLink: CADisplayLink?
    
    required public init(for animation: AniMate) {
        self.animation = animation
    }
    
    public func start() -> Double {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .default)
        return CACurrentMediaTime()
    }
    
    @objc func update() {
        animation.tick(timestamp: displayLink!.timestamp)
    }
    
    public func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    deinit {
        stop()
    }
}
#endif
