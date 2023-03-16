//
//  TimingFunction.swift
//
//
//  A timing function factory class providing a collection of bezier based
//  timing functions for the AniMate animation library.
//
//  MIT License, Copyright (c) 2023 Niko Di Yana
//
//
// Parts of this code are provided by Apple Inc.



/*
 * Copyright (C) 2008 Apple Inc. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 


public class TimingFunction {
    let curve: TimingFunctionCurve
    
    public init(with name: TimingFunctionCurve) {
        curve = name
    }
    
    public init(controlPoints c1x: Double, _ c1y: Double, _ c2x: Double, _ c2y: Double) {
        curve = TimingFunctionCurve(controlPoints: c1x, c1y, c2x, c2y)
    }
}



public struct TimingFunctionCurve {
    // Bezier control points taken from Apple Developer website
    public static let easeIn = TimingFunctionCurve(controlPoints: 0.42, 0, 1, 1)
    public static let easeOut = TimingFunctionCurve(controlPoints: 0, 0, 0.58, 1)
    public static let easeInEaseOut = TimingFunctionCurve(controlPoints: 0.42, 0, 0.58, 1)
    public static let `default` = TimingFunctionCurve(controlPoints: 0.25, 0.01, 0.25, 1)
    
    let c1x: Double, c1y: Double, c2x: Double, c2y: Double
    
    private var ax, bx, cx, ay, by, cy: Double
    
    init(controlPoints c1x: Double, _ c1y: Double, _ c2x: Double, _ c2y: Double) {
        self.c1x = c1x
        self.c1y = c1y
        self.c2x = c2x
        self.c2y = c2y
        
        // Calculate the polynomial coefficients, implicit first and last control points are (0,0) and (1,1).
        cx = 3.0 * c1x
        bx = 3.0 * (c2x - c1x) - cx
        ax = 1.0 - cx - bx
                     
        cy = 3.0 * c1y
        by = 3.0 * (c2y - c1y) - cy
        ay = 1.0 - cy - by
    }
    
    func sampleCurveX(_ t: Double) -> Double {
        // `ax t^3 + bx t^2 + cx t' expanded using Horner's rule.
        return ((ax * t + bx) * t + cx) * t;
    }
            
    func sampleCurveY(_ t: Double) -> Double {
        return ((ay * t + by) * t + cy) * t;
    }
            
    func sampleCurveDerivativeX(_ t: Double) -> Double {
        return (3.0 * ax * t + 2.0 * bx) * t + cx;
    }
    // Given an x value, find a parametric value it came from.
    func solveCurveX(_ x: Double, _ epsilon: Double) -> Double
    {
        var t0, t1, t2, x2, d2: Double
        //var i: Int

        // First try a few iterations of Newton's method -- normally very fast.
        t2 = x
        for _ in 0..<8 {
            x2 = sampleCurveX(t2) - x
            if (abs(x2) < epsilon)
                { return t2 }
            d2 = sampleCurveDerivativeX(t2)
            if (abs(d2) < 1e-6)
                { break }
            t2 = t2 - x2 / d2
        }

        // Fall back to the bisection method for reliability.
        t0 = 0.0
        t1 = 1.0
        t2 = x

        if (t2 < t0)
            { return t0 }
        if (t2 > t1)
            { return t1 }

        while (t0 < t1) {
            x2 = sampleCurveX(t2)
            if (abs(x2 - x) < epsilon)
                { return t2 }
            if (x > x2)
                { t0 = t2 }
            else
                { t1 = t2 }
            t2 = (t1 - t0) * 0.5 + t0
        }

        // Failure
        return t2
    }

    func solve(_ x: Double, _ epsilon: Double) -> Double {
        return sampleCurveY(solveCurveX(x, epsilon))
    }
}
