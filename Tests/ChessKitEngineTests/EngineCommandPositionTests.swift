//
//  EngineCommandPositionTests.swift
//  ChessKitEngineTests
//

import Testing
@testable import ChessKitEngine

@Suite("Engine command position tests")
struct EngineCommandPositionTests {

    @Test("Position strings produce UCI raw values")
    func positionStringRawValue() {
        let p = EngineCommand.PositionString.startpos
        #expect(p.rawValue == "startpos")

        let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        let f = EngineCommand.PositionString.fen(fen)
        #expect(f.rawValue == "fen \(fen)")
    }

    @Test("Position strings initialize from UCI raw values")
    func positionStringRawValueInit() {
        #expect(EngineCommand.PositionString(rawValue: "startpos") == .startpos)

        let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        #expect(EngineCommand.PositionString(rawValue: "fen \(fen)") == .fen(fen))
    }

    @Test(
        "Incomplete FEN position strings are rejected",
        arguments: [
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR",
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w",
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq",
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -",
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0",
        ]
    )
    func invalidFENPositionString(_ fen: String) {
        #expect(EngineCommand.PositionString(rawValue: "fen \(fen)") == nil)
    }

    @Test("Invalid position strings are rejected", arguments: ["invalid", ""])
    func invalidPositionString(_ position: String) {
        #expect(EngineCommand.PositionString(rawValue: position) == nil)
    }
}
