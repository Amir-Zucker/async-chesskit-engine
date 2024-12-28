//
//  BaseEngineTests.swift
//  ChessKitEngineTests
//

import XCTest
@testable import ChessKitEngine

/// Base test case for testing included engines.
///
/// Subclass `BaseEngineTests`, set `engineType` in `setUp()`,
/// and then call `super.setUp()` to run common engine tests.
///
/// #### Example
/// ``` swift
/// final class MyEngineTests: BaseEngineTests {
///
///     func override setUp() {
///         engineType = .myEngine
///         super.setUp()
///     }
///
/// }
/// ```
///
//@TestsActor
class BaseEngineTests: XCTestCase {
    
    override class var defaultTestSuite: XCTestSuite {
        // Disable tests in base test case with empty XCTestSuite
        if self == BaseEngineTests.self {
            return .init(name: "Disable BaseEngineTests")
        } else {
            return super.defaultTestSuite
        }
    }
    
    /// The engine type to test.
    nonisolated(unsafe) var engineType: EngineType!
    nonisolated(unsafe) var engine: Engine!
    
    override func setUp() {
        super.setUp()
        engine = Engine(type: engineType, loggingEnabled: true)
    }
    
    override func tearDown() async throws {
        try? await engine.stop()
        engine = nil
    }
    
    func testEngineSetup() async {
        XCTAssert(!Thread.isMainThread, "Test must be run on a background thread")
        XCTAssertNotNil(self.engine, "Failed to initialize engine")

        let expectation = self.expectation(
            description: "Expect engine \(engine.type.name) to start up."
        )
        
//        Task{
            await startEngine(expectation: expectation)
            
            for await response in await engine.responseStream! {
                if case let .id(id) = response,
                   case let .name(name) = id {
                    let version = engine.type.version
                    XCTAssertTrue(name.contains(version))
                }
                
                let isRunning = await engine.isRunning
                
                if response == .readyok &&
                    isRunning {
                    expectation.fulfill()
                }
            }
//        }
        await fulfillment(of: [expectation], timeout: 50)
    }
    
    func testEngineStop() async {
        XCTAssert(!Thread.isMainThread, "Test must be run on a background thread")
        XCTAssertNotNil(self.engine, "Failed to initialize engine")
        
        let expectationStartEngine = self.expectation(
            description: "Expect engine \(engine.type.name) to start up."
        )
        let expectationStopEngine = self.expectation(
            description: "Expect engine \(engine.type.name) to stop gracefully."
        )
        
//        Task{
            await startEngine(expectation: expectationStartEngine)
            
            await stopEngine(expectation: expectationStopEngine)
//        }
        
        await fulfillment(of: [expectationStartEngine, expectationStopEngine], timeout: 50)
    }
    
    func testEngineRestart() async {
        XCTAssert(!Thread.isMainThread, "Test must be run on a background thread")
        XCTAssertNotNil(self.engine, "Failed to initialize engine")

        let expectationStartEngine = self.expectation(
            description: "Expect engine \(engine.type.name) to start up."
        )
        let expectationStopEngine = self.expectation(
            description: "Expect engine \(engine.type.name) to stop gracefully."
        )
        
        expectationStartEngine.expectedFulfillmentCount = 2
        
//        Task{
            await startEngine(expectation: expectationStartEngine)
            
            await stopEngine(expectation: expectationStopEngine)
            
            await startEngine(expectation: expectationStartEngine)
//        }
        
        await fulfillment(of: [expectationStartEngine, expectationStopEngine], timeout: 50)
    }
    
    
    private func stopEngine(expectation: XCTestExpectation) async {
        do {
            try await engine.stop()
        } catch {
            XCTFail("Failed to stop engine: \(error)")
        }
        
        if await !engine.isRunning,
           await engine.responseStream == nil {
            expectation.fulfill()
        }
    }
    
    private func startEngine(expectation: XCTestExpectation) async {
        do {
            try await engine.start()
        } catch {
            XCTFail("Failed to start engine: \(error)")
        }
        
        for await response in await engine.responseStream! {
            if case let .id(id) = response,
               case let .name(name) = id {
                let version = engine.type.version
                XCTAssertTrue(name.contains(version))
            }
            
            let isRunning = await engine.isRunning
            
            if response == .readyok &&
                isRunning {
                expectation.fulfill()
                break
            }
        }
    }
}

//This actor's purpose is to ensure tests for the engine
//class aren't running on main thread.
//Since start function now uses MainActor.run which is virtually the
//same thing as main thread to execute, testing on main thread is
//counter productive.
@globalActor
actor TestsActor: GlobalActor {
    static var shared = TestsActor()
}
