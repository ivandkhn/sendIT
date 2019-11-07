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
            Log.w("in \(getPeerName()) no text entered in textField, cannot send empty message")
            return
        }
        self.send(stringMessage: stringMessage, encoding: STRING_ENCODING)
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
    
    func hostSession(action: UIAlertAction) {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ivan-chat", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
        Log.i("\(getPeerName()) is starting session...")
    }
    
    func joinSession(action: UIAlertAction) {
        let mcBrowser = MCBrowserViewController(serviceType: "ivan-chat", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
        Log.i("joining session...")
    }
    
    func send(stringMessage message: String, encoding: String.Encoding) {
        guard let dataToSend = message.data(using: STRING_ENCODING) else {
            Log.w("\(getPeerName()) is unable to convert String to Data")
            return
        }
        guard let currentSession = mcSession else {
            Log.e("\(getPeerName()) is not connected to anyone, cannot send")
            return
        }
        do {
            try currentSession.send(dataToSend, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            Log.e("\(getPeerName()) is unable to send message, errorMessage: ")
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
            Log.i("Connected: \(getPeerName())")
        case .connecting:
            Log.i("Connecting to: \(getPeerName())")
        case .notConnected:
            Log.i("Not Connected: \(getPeerName())")
        @unknown default:
            Log.e("Fatal error")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            if let receivedMessage = String(data: data, encoding: self.STRING_ENCODING) {
                self.messageHistoryView.text = self.messageHistoryView.text + "\n" + receivedMessage
            } else {
                Log.w("\(self.getPeerName()) is unable to decode received message as string")
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
