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

    //MARK: constants
    let STRING_ENCODING = String.Encoding.unicode
    
    //MARK: outlet variables
    @IBOutlet weak var messageHistoryView: UITextView!
    @IBOutlet weak var messageInputField: UITextField!
    
    //MARK: outlet functions
    @IBAction func tapSendButton(_ sender: UIButton) {
        guard let stringMessage = messageInputField.text else {
            Log.w("No text entered in textField, cannot send empty message")
            return
        }
        self.send(stringMessage: stringMessage, encoding: STRING_ENCODING)
    }
    
    @IBAction func tapHostSessionButton(_ sender: UIButton) {
        hostSession()
    }
    
    @IBAction func tapJoinSessionButton(_ sender: UIButton) {
        joinSession()
    }
    
    //MARK: variables
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    //MARK: gereric functions
    
    /// Need to provide custom name gettr function,
    /// as the peer could be connected to no one and no peedID is avaliable
    func getPeerName() -> String {
        if let currentPeerID = self.peerID {
            return currentPeerID.displayName
        } else {
            Log.w("cannot get peerID")
            return "<nil>"
        }
    }
    
    func hostSession() {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ivanChat", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
        Log.i("starting session...")
    }
    
    func joinSession() {
        let mcBrowser = MCBrowserViewController(serviceType: "ivanChat", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
        Log.i("joining session...")
    }
    
    func send(stringMessage message: String, encoding: String.Encoding) {
        guard let dataToSend = message.data(using: STRING_ENCODING) else {
            Log.w("Unable to convert String to Data")
            return
        }
        guard let currentSession = mcSession else {
            Log.e("Not connected to anyone, cannot send")
            return
        }
        do {
            try currentSession.send(dataToSend, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            Log.e("Unable to send message, errorMessage: ")
        }
    }

    
    //MARK: UI functions
    override func viewDidLoad() {
        super.viewDidLoad()
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
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
            Log.i("MCSessionState changed to: Connected")
        case .connecting:
            Log.i("MCSessionState changed to: Connecting")
        case .notConnected:
            Log.i("MCSessionState changed to: Not Connected")
        @unknown default:
            Log.e("Fatal error")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            if let receivedMessage = String(data: data, encoding: self.STRING_ENCODING) {
                self.messageHistoryView.text = self.messageHistoryView.text + "\n" + self.getPeerName() + " " + receivedMessage
            } else {
                Log.w("Unable to decode received message as string")
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
