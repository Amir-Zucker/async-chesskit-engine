//
//  EngineMessenger.swift
//  ChessKitEngine
//
//  Created by Amir Zucker on 27/12/2024.
//

import ChessKitEngineCore
import Combine

protocol EngineMessengerDelegate: Sendable {
    func engineMessengerDidReceiveResponse(_ response: String)
}

internal final class EngineMessenger: @unchecked Sendable {
    private let objcppBridge: ObjectiveCPlusplusBridge
    private var queue: dispatch_queue_t?
    private var readPipe: Pipe?
    private var writePipe: Pipe?
    private var pipeReadHandle: FileHandle?
    private var pipeWriteHandle: FileHandle?
    private var isRunning: Bool = false
    private var delegate: EngineMessengerDelegate?
    private var cancellables: [AnyCancellable] = []
    
    init(engineType: EngineType) {
        self.objcppBridge = ObjectiveCPlusplusBridge(engineType: engineType.rawValue)
    }
    
    func start(delegate: EngineMessengerDelegate) async throws {
        guard !isRunning else { throw EngineError.AlreadyStarted }
        isRunning = true
        self.delegate = delegate

        readPipe = Pipe()
        pipeReadHandle = readPipe?.fileHandleForReading
        dup2(readPipe?.fileHandleForWriting.fileDescriptor ?? 0, fileno(stdout))
        
        await MainActor.run {
            pipeReadHandle?.readInBackgroundAndNotify()
        }
        
        NotificationCenter.default.publisher(for: FileHandle.readCompletionNotification, object: pipeReadHandle).sink { [weak self] notification in
            self?.readStdout(notification: notification)
        }.store(in: &cancellables)
                
        
        writePipe = Pipe()
        pipeWriteHandle = writePipe?.fileHandleForWriting
        dup2(writePipe?.fileHandleForReading.fileDescriptor ?? 0, fileno(stdin))

        queue = DispatchQueue(label: "ck-message-queue", attributes: .concurrent)
        
        queue?.async { [weak self] in
            self?.objcppBridge.initalizeEngine()
        }
    }
    
    func stop() throws {
        try pipeReadHandle?.close()
        try pipeWriteHandle?.close()
        
        readPipe = nil
        pipeReadHandle = nil
        
        writePipe = nil
        pipeWriteHandle = nil
        
        NotificationCenter.default.removeObserver(self)
        isRunning = false
    }
    
    func sendCommand(command: EngineCommand) {
        let commandString = command.rawValue + "\n"

        _ = queue?.sync {
            let result = write(pipeWriteHandle!.fileDescriptor, commandString, strlen(commandString))
            
            //TODO: remove
            print("result: \(result)")
        }
    }
    
    private nonisolated func readStdout(notification: Notification) {
//        Task {
            pipeReadHandle?.readInBackgroundAndNotify()
//        }
            
        guard let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data,
              let output = String(data: data, encoding: .utf8)?.components(separatedBy: "\n") else {
            return
        }
        
        for response in output {
//            Task {
                delegate?.engineMessengerDidReceiveResponse(response)
//            }
        }
    }
}
