//
//  StockfishTests.swift
//  ChessKitEngineTests
//

import Testing
@testable import ChessKitEngine

extension EngineLifecycleTests {
    @Suite("Stockfish", .serialized)
    struct StockfishTests {
        @Test func engineStarts() async throws {
            let engine = Engine(type: .stockfish, loggingEnabled: true)

            try await start(engine)
            try await engine.stop()
        }

        @Test func engineStops() async throws {
            let engine = Engine(type: .stockfish, loggingEnabled: true)

            try await start(engine)
            try await stop(engine)
        }

        @Test func engineRestarts() async throws {
            let engine = Engine(type: .stockfish, loggingEnabled: true)

            try await start(engine)
            try await stop(engine)

            // Stockfish can fail its internal mutex when restarted immediately.
            try await Task.sleep(for: .milliseconds(100))
            try await start(engine)
            try await engine.stop()
        }

        private func start(_ engine: Engine) async throws {
            try await engine.start()

            let responseStream = await engine.responseStream
            let stream = try #require(
                responseStream,
                "Failed to create the Stockfish response stream"
            )

            for await response in stream {
                if case let .id(.name(name)) = response {
                    #expect(name.contains(EngineType.stockfish.version))
                }

                if response == .readyok, await engine.isRunning {
                    return
                }
            }

            Issue.record("Stockfish stopped responding before it became ready")
        }

        private func stop(_ engine: Engine) async throws {
            try await engine.stop()
            #expect(await !engine.isRunning)
            #expect(await engine.responseStream == nil)
        }
    }
}
// ↑↑ Failing in CI since update to Stockfish 17 - to be investigated. ↑↑
