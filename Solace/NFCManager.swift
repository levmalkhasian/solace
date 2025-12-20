//
//  NFCManager.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/19/25.
//

import CoreNFC

final class NFCManager: NSObject, NFCNDEFReaderSessionDelegate {
   
    private var session: NFCNDEFReaderSession? // stores session
    private var onResult: ((Bool) -> Void)? // callback - success or not
    
    func startScan(prompt: String, onResult: @escaping (Bool) -> Void) {
        self.onResult = onResult
        
        guard NFCNDEFReaderSession.readingAvailable else {
            onResult(false)
            self.onResult = nil
            return
        }
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = prompt // text shown in NFC scan
        session?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        
        session.alertMessage = "Successful Scan."
        onResult?(true)
        onResult = nil
        self.session = nil
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) { // error/cancel function callback
        onResult?(false)
        onResult = nil
        self.session = nil
    }
    
}
