//
//  ArasanTests.swift
//
//  Created by Amir Zucker on 10/01/2025.
//

import Foundation
import Testing
@testable import ChessKitEngine

extension EngineLifecycleTests {
    @Suite("Arasan", .serialized)
    final class ArasanTests {
        private let originalXCTestBundlePath: String?
        private let testBundleContainer: URL

        init() throws {
            originalXCTestBundlePath = ProcessInfo.processInfo
                .environment["XCTestBundlePath"]
            testBundleContainer = try Self.createTestBundle()
            setenv("XCTestBundlePath", testBundleContainer.path, 1)
        }

        deinit {
            if let originalXCTestBundlePath {
                setenv("XCTestBundlePath", originalXCTestBundlePath, 1)
            } else {
                unsetenv("XCTestBundlePath")
            }

            try? FileManager.default.removeItem(at: testBundleContainer)
        }

        @Test func engineStarts() async throws {
            let engine = Engine(type: .arasan, loggingEnabled: true)

            try await start(engine)
            try await engine.stop()
        }

        @Test func engineStops() async throws {
            let engine = Engine(type: .arasan, loggingEnabled: true)

            try await start(engine)
            try await stop(engine)
        }

        @Test func engineRestarts() async throws {
            let engine = Engine(type: .arasan, loggingEnabled: true)

            try await start(engine)
            try await Task.sleep(for: .seconds(1))
            try await stop(engine)
            try await Task.sleep(for: .seconds(1))
            try await start(engine)
            try await engine.stop()
        }

        private func start(_ engine: Engine) async throws {
            try await engine.start()

            let responseStream = await engine.responseStream
            let stream = try #require(
                responseStream,
                "Failed to create the Arasan response stream"
            )

            for await response in stream {
                if case let .id(.name(name)) = response {
                    #expect(name.contains(EngineType.arasan.version))
                }

                if response == .readyok, await engine.isRunning {
                    return
                }
            }

            Issue.record("Arasan stopped responding before it became ready")
        }

        private func stop(_ engine: Engine) async throws {
            try await engine.stop()
            #expect(await !engine.isRunning)
            #expect(await engine.responseStream == nil)
        }

        private static func createTestBundle() throws -> URL {
            let fileManager = FileManager.default
            let containerURL = fileManager.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            let bundleURL = containerURL
                .appendingPathComponent("ChessKitEngineTests.bundle", isDirectory: true)

            do {
                try fileManager.createDirectory(
                    at: bundleURL,
                    withIntermediateDirectories: true
                )

                for resource in ["arasan.rc", "arasan.nnue", "book.bin"] {
                    let resourceURL = try #require(
                        Bundle.module.url(
                            forResource: resource,
                            withExtension: nil
                        ),
                        "Missing test resource: \(resource)"
                    )
                    try fileManager.copyItem(
                        at: resourceURL,
                        to: bundleURL.appendingPathComponent(resource)
                    )
                }

                return containerURL
            } catch {
                try? fileManager.removeItem(at: containerURL)
                throw error
            }
        }
    }
}
