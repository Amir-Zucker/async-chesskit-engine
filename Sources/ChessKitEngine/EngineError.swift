//
//  File.swift
//  ChessKitEngine
//
//  Created by Amir Zucker on 27/12/2024.
//

import Foundation

public enum EngineError: Error {
    case NotRunning
    case AlreadyStarted
    case FailedToStartEngine
    case FailedToStopEngine
    
    var localizedDescription: String {
        switch self {
        case .NotRunning:
            return "Engine is not running. You should call Engine.start(_:) before sending commands."
        case .AlreadyStarted:
            return "Engine is already running. You should call Engine.stop() before starting again."
        case .FailedToStartEngine:
            return "Failed to start engine."
        case .FailedToStopEngine:
            return "Failed to stop engine."
        }
    }
}
