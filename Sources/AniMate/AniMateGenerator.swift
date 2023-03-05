//
//  AniMateGenerator.swift
//
//
//  Protocol for suplying custom pulse generator to an animation.
//
//  MIT License, Copyright (C) 2023 Niko Di Yana



public protocol AniMateGenerator {
    var animation: AniMate! { get set }
    
    init(for animation: AniMate)
    
    func start() -> Double
    func stop()
}
