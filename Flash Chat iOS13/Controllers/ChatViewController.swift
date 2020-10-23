//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    //referencia ao banco de dados
    let db = Firestore.firestore()
    
    var messages : [Message] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMessages()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        
        navigationController?.isNavigationBarHidden = false
        title = K.appName
        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
       
    }
    
    func loadMessages(){
        
        db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField)
            .addSnapshotListener {(querySnapshot, error) in
            
            self.messages = []
            
            if let e = error{
                print("\(e) erro no get documents")
            }else{
                if  let snapshotDoc =  querySnapshot?.documents{
                    for doc in snapshotDoc {
                        let data = doc.data()
                        if let mSender = data[K.FStore.senderField] as? String,let mBody = data [K.FStore.bodyField] as? String {
                            let newMessage = Message(sender: mSender, body: mBody)
                            self.messages.append(newMessage)
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                let indexPath = IndexPath(row: self.messages.count - 1 , section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
   
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
            
        } catch let signOutError as NSError {
            
            print ("Error signing out: %@", signOutError)
        }
        
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        
        //verificando se não é nulo
        if let messageBody   = messageTextfield.text,
           let messageSender = Auth.auth().currentUser?.email {
            
            db.collection(K.FStore.collectionName).addDocument(data: [K.FStore.senderField : messageSender, K.FStore.bodyField : messageBody,K.FStore.dateField : Date().timeIntervalSince1970]) { (error) in
                
                if let e = error {
                    print("Problema salvando os dados no Firestore \(e)")
                }else {
                    DispatchQueue.main.async {
                        self.messageTextfield.text = ""
                    }
                    print("Dados salvos com sucesso")
                }
            }
        }
    }
    
    
}

extension ChatViewController : UITableViewDataSource , UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        
       cell.messageLbl.text = message.body
        
        // esta msg é do usuario logado
        if message.sender == Auth.auth().currentUser?.email {
            cell.youImgView.isHidden = true
            cell.avatarImgView.isHidden = false
            cell.messageBuble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.messageLbl.textColor = UIColor(named: K.BrandColors.purple)
        }
        //esta mensagem é de outro sender
        else {
            cell.youImgView.isHidden = false
            cell.avatarImgView.isHidden = true
            cell.messageBuble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.messageLbl.textColor = UIColor(named: K.BrandColors.lightPurple)
        }
        
        return cell
    }
}

