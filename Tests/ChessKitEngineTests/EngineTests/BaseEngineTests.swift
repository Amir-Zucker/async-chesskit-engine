//
//  BaseEngineTests.swift
//  ChessKitEngineTests
//

import Testing

/// EngineMessenger redirects process-wide standard input and output, so its
/// integration tests must not run concurrently.
@Suite("Engine lifecycle tests", .serialized)
struct EngineLifecycleTests {}
