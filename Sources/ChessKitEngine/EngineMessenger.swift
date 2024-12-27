//
//  EngineMessenger.swift
//  ChessKitEngine
//
//  Created by Amir Zucker on 27/12/2024.
//

import ChessKitEngineCore

internal actor EngineMessenger {
    private let objcppBridge: ObjectiveCPlusplusBridge
//    private let configuration: EngineConfiguration
    private var queue: dispatch_queue_t?
    private var readPipe: Pipe?
    private var writePipe: Pipe?
    private var pipeReadHandle: FileHandle?
    private var pipeWriteHandle: FileHandle?
    private var isRunning: Bool = false
    
    init(engineType: EngineType) {
        objcppBridge = ObjectiveCPlusplusBridge(engineType: engineType.rawValue)
    }
    
    nonisolated func start() async throws -> AsyncCompactMapSequence<NotificationCenter.Notifications, [String]> {
        guard await !isRunning else { throw EngineError.AlreadyStarted }
        await setIsRunning(isRunning: true)

        await setReadPipe()
        await setWritePipe()
        
        let notifications = await NotificationCenter.default.notifications(named: FileHandle.readCompletionNotification, object: pipeReadHandle)
        
        await queue?.async { [weak self] in
            self?.objcppBridge.initalizeEngine()
        }
        
        // start engine setup loop
        await sendCommand(command: .uci)
        
        return notifications.compactMap({ notification in
            Task {[weak self] in
                await self?.pipeReadHandle?.readInBackgroundAndNotify()
            }
            
            return self.readStdout(notification: notification)
        })
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
        guard let pipeWriteHandle else { return }
        
        let commandString = command.rawValue + "\n"

        _ = queue?.sync {
            let result = write(pipeWriteHandle.fileDescriptor, commandString, strlen(commandString))
            
            //TODO: remove
            print("result: \(result)")
        }
    }
    
    private func setIsRunning(isRunning: Bool) {
        self.isRunning = isRunning
    }
    
    private func setWritePipe() {
        writePipe = Pipe()
        pipeWriteHandle = writePipe?.fileHandleForWriting
        dup2(writePipe?.fileHandleForReading.fileDescriptor ?? 0, fileno(stdin))
    }
    
    private func setReadPipe() {
        readPipe = Pipe()
        pipeReadHandle = readPipe?.fileHandleForReading
        dup2(readPipe?.fileHandleForWriting.fileDescriptor ?? 0, fileno(stdout))
        
        pipeReadHandle?.readInBackgroundAndNotify()
    }
    
    private func setqueue() {
        queue = DispatchQueue(label: "ck-message-queue", attributes: .concurrent)
    }
    
    private nonisolated func readStdout(notification: Notification) -> [String] {
        guard let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data,
            let output = String(data: data, encoding: .utf8)?.components(separatedBy: "\n") else {
            return []
        }
        
        return output
    }
}
