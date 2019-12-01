//
//  ViewController.swift
//  sendIT
//
//  Created by Иван Дахненко on 05.11.2019.
//  Copyright © 2019 Ivan Dakhnenko. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate, UITextFieldDelegate {
    
    enum MessageType {
        case incoming
        case outgoing
    }

    //MARK: constants
    let STRING_ENCODING = String.Encoding.unicode
    let BUBBLES_Y_SPACE: CGFloat = 50
    let BUBBLES_X_OFFCET: CGFloat = 10
    let BUBBLES_Y_OFFCET: CGFloat = 0
    
    
    //MARK: variables
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    var currentBubbneNumber = 0
    
    //MARK: outlet variables
    @IBOutlet weak var messageInputField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    
    //MARK: outlet functions
    @IBAction func tapSendButton(_ sender: UIButton) {
        guard let stringMessage = messageInputField.text, stringMessage != "" else {
            Log.w("Weird text entered in textField")
            return
        }
        showMessageBubble(withText: stringMessage, type: .outgoing)
        self.send(stringMessage: stringMessage, encoding: STRING_ENCODING)
    }
    
    @IBAction func tapHostSessionButton(_ sender: UIButton) {
        hostSession()
    }
    
    @IBAction func tapJoinSessionButton(_ sender: UIButton) {
        joinSession()
    }
    
    
    //MARK: gereric functions
    /// Need to provide custom name getter function,
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
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.messageInputField.delegate = self

        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
        
        // we increase content size (height) with each appeared message,
        // so initially it could be set to zero.
        scrollView.contentSize = CGSize(width: 0, height: 0)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: self.view.window)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: self.view.window)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {return}
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        let keyboardFrame = keyboardSize.cgRectValue
        UIView.animate(withDuration: 0.5, animations: {
            self.view.frame.size.height -= keyboardFrame.height
            self.view.layoutIfNeeded()
        })
        
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {return}
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        let keyboardFrame = keyboardSize.cgRectValue
        UIView.animate(withDuration: 0.5, animations: {
            self.view.frame.size.height += keyboardFrame.height
            self.view.layoutIfNeeded()
        })
    }
    
    func showMessageBubble(withText text: String, type: MessageType)  {
        // TODO: handle multi-line messages
        let label =  UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .white
        label.text = text

        let constraintRect = CGSize(width: 0.66 * view.frame.width,
                                    height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font: label.font!],
                                            context: nil)
        label.frame.size = CGSize(width: ceil(boundingBox.width),
                                  height: ceil(boundingBox.height))

        let bubbleSize = CGSize(width: label.frame.width + 28,
                                height: label.frame.height + 20)

        let bubbleView = BubbleView()
        bubbleView.isIncoming = type == .incoming
        bubbleView.frame.size = bubbleSize
        bubbleView.backgroundColor = .clear
        
        if type == .outgoing {
            bubbleView.frame.origin.x = scrollView.frame.width - bubbleView.frame.width - BUBBLES_X_OFFCET
            bubbleView.frame.origin.y = CGFloat(BUBBLES_Y_OFFCET + BUBBLES_Y_SPACE * CGFloat(currentBubbneNumber))
        } else {
            bubbleView.frame.origin.x = BUBBLES_X_OFFCET
            bubbleView.frame.origin.y = CGFloat(BUBBLES_Y_OFFCET + BUBBLES_Y_SPACE * CGFloat(currentBubbneNumber))
        }
    
        scrollView.addSubview(bubbleView)
        label.center = bubbleView.center
        scrollView.addSubview(label)
        currentBubbneNumber += 1
        
        scrollView.contentSize = CGSize(width: scrollView.contentSize.width,
                                        height: BUBBLES_Y_OFFCET + BUBBLES_Y_SPACE * CGFloat(currentBubbneNumber-1) + bubbleView.frame.height)
        if scrollView.contentSize.height > scrollView.bounds.size.height {
            let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height + CGFloat(10))
            scrollView.setContentOffset(bottomOffset, animated: true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // TODO: send message on enter
        // TODO: hide keyboard on tap
        messageInputField.resignFirstResponder()
        return true;
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
                self.showMessageBubble(withText: receivedMessage, type: .incoming)
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
