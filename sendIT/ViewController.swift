//
//  ViewController.swift
//  sendIT
//
//  Created by Иван Дахненко on 05.11.2019.
//  Copyright © 2019 Ivan Dakhnenko. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate {

    let STRING_ENCODING = String.Encoding.unicode
    
    //MARK: variables
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    //MARK: gereric functions
    func hostSession(action: UIAlertAction) {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ivan-chat", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
        Log.i("\(peerID.displayName) is starting session...")
    }
    
    func joinSession(action: UIAlertAction) {
        let mcBrowser = MCBrowserViewController(serviceType: "ivan-chat", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
        Log.i("joining session...")
    }
    
    func send(stringMessage message: String, encoding: String.Encoding) {
        guard let dataToSend = message.data(using: STRING_ENCODING) else {
            Log.w("\(peerID.displayName) is unable to convert String to Data")
            return
        }
        do {
            try mcSession.send(dataToSend, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch let error {
            Log.e("\(peerID.displayName) is unable to send message, errorMessage: \(error.localizedDescription)")
        }
    }

    
    //MARK: UI functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    /// from MCBrowserViewController
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    /// from MCBrowserViewController
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    //MARK: protocol conforming functions
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            Log.i("Connected: \(peerID.displayName)")
        case .connecting:
            Log.i("Connecting to: \(peerID.displayName)")
        case .notConnected:
            Log.i("Not Connected: \(peerID.displayName)")
        @unknown default:
            Log.e("Fatal error")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            if let receivedMessage = String(data: data, encoding: self.STRING_ENCODING) {
                // TODO: show massage on screen
            } else {
                Log.w("\(peerID.displayName) is unable to decode received message as string")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        //
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        //
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        //
    }
}
