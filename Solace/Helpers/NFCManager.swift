//
//  NFCManager.swift
//  Solace
//
//  Created by Levon Malkhasian on 12/19/25.
//

import CoreNFC

final class NFCManager: NSObject, NFCNDEFReaderSessionDelegate {
   
    private var nfcSession: NFCNDEFReaderSession? // stores session
    private var onResult: ((Bool) -> Void)? // callback - success or not
    
    func startScan(prompt: String, onResult: @escaping (Bool) -> Void) { // prompt = "Scan To Start Focus"
        self.onResult = onResult
        
        guard NFCNDEFReaderSession.readingAvailable else {
            onResult(false)
            self.onResult = nil
            return
        }
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.alertMessage = prompt // Text shown in NFC scan
        nfcSession?.begin() // Starts NFC Session In-App
        // let isScanning = true
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {} // Intentionally Empty, to suppress console message

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) { // Success function
        
        session.alertMessage = "Successful Scan."
        DispatchQueue.main.async {
            self.onResult?(true)
            self.onResult = nil
        }
        self.nfcSession = nil
        // isScanning = false
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) { // Error/cancel function callback
        DispatchQueue.main.async {
            self.onResult?(false)
            self.onResult = nil
        }
        self.nfcSession = nil
        // isScanning = false
    }
    
}
