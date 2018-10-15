//
//  SettingsViewController.swift
//  hh
//
//  Created by Teodoro Gomes on 04/09/2018.
//  Copyright © 2018 Teodoro Gomes. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FirebaseAuth

class SettingsViewController: UIViewController {

    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var sliderLabel: UILabel!
    @IBOutlet weak var trackFriend: UISwitch!
    @IBOutlet weak var mapType: UISegmentedControl!
    @IBOutlet weak var unitType: UISegmentedControl!
    let selection = UISelectionFeedbackGenerator()
    
    @IBAction func logOut(_ sender: Any) {
        let loginManager = FBSDKLoginManager()
        loginManager.logOut() // this is an instance function
       try! Auth.auth().signOut()
       
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sliderLabel.text = String(UserDefaults.standard.integer(forKey: "target"))
        trackFriend.isOn = UserDefaults.standard.bool(forKey: "trackFriend")
        mapType.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "mapType")
        unitType.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "unitType")
        
        if(Auth.auth().currentUser?.displayName != nil){
            displayNameLabel.text = "Logged as: \(Auth.auth().currentUser?.displayName! ?? "")"
        }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
       
         sender.value = round(sender.value)
        sliderLabel.text = String(Int(sender.value) * 100)
        if((Int(sender.value) * 100) % 1000 == 0  ){
            //            impact.impactOccurred()
            selection.selectionChanged()
        }
        
    }
    
    
    @IBAction func saveButton(_ sender: Any) {
        ViewController.MyVariables.target = Int(slider.value) * 100
        createAlert(title: "Success", message: "Settings successfully saved")
        UserDefaults.standard.set(Int(slider.value) * 100, forKey: "target")
        
        UserDefaults.standard.set(trackFriend.isOn, forKey: "trackFriend")
        UserDefaults.standard.set(mapType.selectedSegmentIndex, forKey: "mapType")
        UserDefaults.standard.set(unitType.selectedSegmentIndex, forKey: "unitType")
    }
    
    func createAlert(title:String , message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))

        self.present(alert, animated: true, completion: nil)
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
