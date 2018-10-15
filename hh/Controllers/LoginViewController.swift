//
//  LoginViewController.swift
//  
//
//  Created by Teodoro Gomes on 28/06/2018.
//  Copyright © 2018 Teodoro Gomes. All rights reserved.
//

import UIKit
import FirebaseAuth
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseDatabase

class LoginViewController: UIViewController , FBSDKLoginButtonDelegate , UITextFieldDelegate {
    
    
  
    @IBOutlet weak var sexType: UISegmentedControl!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var emailText: UITextField!
    
    @IBOutlet weak var stepper: UIStepper!
  
    @IBOutlet weak var sexLabel: UILabel!
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var signInButton: RoundButton!
    @IBOutlet weak var signUpButton: RoundButton!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var loginButton: FBSDKLoginButton!
    @IBOutlet weak var age2Label: UILabel!
    var ref:DatabaseReference!
    
    
    override func viewDidAppear(_ animated: Bool) {
//        if(FBSDKAccessToken.current() != nil){
            //             self.performSegue(withIdentifier: "loggedSegue", sender: self)
            //        }else {
            //             print("Not Logged")
            //        }

        
        if(Auth.auth().currentUser != nil){
            perform(#selector(nextController), with: nil, afterDelay: 0.01)
        }

    }
    
    @objc func nextController() {
          performSegue(withIdentifier: "loggedSegue", sender: self)
    }
    
    override func viewDidLoad() {
        ref = Database.database().reference()
        super.viewDidLoad()
        loginButton.readPermissions = ["public_profile","email"]
        loginButton.delegate = self
        nameText.delegate = self
        emailText.delegate = self
        passwordText.delegate = self
        
    }
    
   
    

    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error != nil{
            print(error.localizedDescription)
            print("EERROROROROR")
            return
        }else{
            if(result.isCancelled){
                return
            }
            let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
            
            Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
               
                self.performSegue(withIdentifier: "loggedSegue", sender: self)
            }
        }
    }
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Logged out")
        
    }
    

    @IBAction func SignIn(_ sender: UIButton) {
        errorLabel.text = ""
        if(sender.titleLabel?.text == "Sign In"){
            Auth.auth().signIn(withEmail: emailText!.text!, password: passwordText!.text!) { (authDataResult, error) in
                if let Error = error {
                    self.errorLabel.text = Error.localizedDescription
                }else{
                    self.performSegue(withIdentifier: "loggedSegue", sender: self)
                }
            }
        }else{
            nameText.isHidden = true
            sexLabel.isHidden = true
            sexType.isHidden = true
            ageLabel.isHidden = true
            age2Label.isHidden = true
            stepper.isHidden = true
            signUpButton.setTitle("Sign Up", for: .normal)
            loginButton.isHidden = false
            signInButton.setTitle("Sign In", for: .normal)
            signInButton.backgroundColor = UIColor.black
        }
       
    }
    
    
    
    @IBAction func SignUp(_ sender: UIButton) {
        errorLabel.text = ""
        if(sender.titleLabel?.text == "Submit"){
            if(nameText.text != ""){
                Auth.auth().createUser(withEmail: emailText!.text!, password: passwordText!.text!) { (authResult, error) in
                     if let eror = error {
                        self.errorLabel.text = eror.localizedDescription
                    }else{
                       
                        print("User Added")
                        Auth.auth().signIn(withEmail: self.emailText!.text!, password: self.passwordText!.text!) { (authDataResult, error) in
                            if let Error = error {
                                self.errorLabel.text = Error.localizedDescription
                            }else{
                                 guard let user = authDataResult?.user else { return }
                                let changeRequest = user.createProfileChangeRequest()
                                changeRequest.displayName = self.nameText.text!
                                changeRequest.commitChanges { (error) in
                                    if error != nil {
                                        print(error?.localizedDescription ?? "error")
                                    }else{
                                        UserDefaults.standard.set(5000, forKey: "target")
                                       
                                    self.writeUserToFirebase()
                                        self.performSegue(withIdentifier: "loggedSegue", sender: self)
                                    }
                                }
                                //
                                
                            }
                        }
                    }
                }
            }else{
                errorLabel.text = "Please provide a valid name"
            }
        }else{
            nameText.isHidden = false
            sexLabel.isHidden = false
            sexType.isHidden = false
            ageLabel.isHidden = false
            age2Label.isHidden = false
            stepper.isHidden = false
            
            sender.setTitle("Submit", for: .normal)
            loginButton.isHidden = true
            signInButton.setTitle("Go Back", for: .normal)
            signInButton.backgroundColor = UIColor.red
        }
       
    
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func stepsChanged(_ sender: UIStepper) {
        ageLabel.text = String(Int(sender.value))
        
    }
    
    func writeUserToFirebase(){
        let data = [
            "UserID" : Auth.auth().currentUser?.uid ?? " ",
            "Username" : nameText.text,
            "Age" : ageLabel.text,
            "Sex" : sexType.selectedSegmentIndex
            ] as [String : Any]
        ref.child("Users").childByAutoId().setValue(data)
        
    }
    
}
