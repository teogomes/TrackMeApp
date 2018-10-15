//
//  infoViewController.swift
//  hh
//
//  Created by Teodoro Gomes on 04/10/2018.
//  Copyright © 2018 Teodoro Gomes. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Charts

class infoViewController: UIViewController {
    var  dataID:String = ""
    var ref:DatabaseReference = Database.database().reference()
    
    @IBOutlet weak var heartLineChart: LineChartView!
    @IBOutlet weak var stepsProgressBar: UIProgressView!
    @IBOutlet weak var stepsLabel: UILabel!
    @IBOutlet weak var heartbeatsLabel: UILabel!
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var floorsLabel: UILabel!
    @IBOutlet weak var timeStampLabel: UILabel!
    @IBOutlet weak var weatherLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    var heartsBeatsList = [] as! [Double]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
        loadData { (list) in
            self.updateGraph()
        }
        
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // Do any additional setup after loading the view.
    }
    
    func loadData(completion: @escaping (_  heartsList: [Double] ) -> Void){
       
        targetLabel.text = String(UserDefaults.standard.integer(forKey: "target"))
        ref.child("data").queryOrdered(byChild: "DataID").queryEqual(toValue: dataID).observeSingleEvent(of: .value) { (snapshot) in
                let snap = snapshot.children.allObjects[0] as! DataSnapshot
                let dict = snap.value as! [String: Any]
                self.usernameLabel.text = dict["Username"] as? String
                self.weatherLabel.text = dict["Weather"] as? String
                self.timeStampLabel.text = dict["Timestamp"] as? String
                self.floorsLabel.text = dict["Floors"] as? String
                self.distanceLabel.text = dict["Distance"] as? String
                var heartbeats = dict["Heartbeats"] as? String
                let steps = dict["Steps"] as? String
                self.stepsProgressBar.progress = Float(steps!)! / Float(UserDefaults.standard.integer(forKey: "target"))
                self.stepsLabel.text = steps

                heartbeats = heartbeats?.replacingOccurrences(of: "[", with: "")
                heartbeats = heartbeats?.replacingOccurrences(of: "]", with: "")
                heartbeats = heartbeats?.replacingOccurrences(of: " ", with: "")
               let heartStringList = (heartbeats?.components(separatedBy: ","))!
            
                for i in 0..<heartStringList.count{
                    self.heartsBeatsList.append(Double(heartStringList[i])!)
                }
            completion(self.heartsBeatsList)
            
        }
        
    }


    
    @IBAction func backPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    func updateGraph(){

        var lineChartEntry = [ChartDataEntry]()

        var circleColors: [NSUIColor] = []
        lineChartEntry.removeAll()
        for i in 0..<heartsBeatsList.count {
            let value = ChartDataEntry(x: Double(i), y: Double(heartsBeatsList[i]))
            lineChartEntry.append(value)

            let color = UIColor.black
            circleColors.append(color)
        }
        heartsBeatsList.removeAll()
        let line1 = LineChartDataSet(values: lineChartEntry, label:"")
        line1.circleRadius = 4.0
        line1.mode = LineChartDataSet.Mode.linear
        line1.drawValuesEnabled = false
        line1.drawIconsEnabled = false
        line1.drawFilledEnabled = true
        line1.colors = [UIColor.red]
        heartLineChart.chartDescription?.enabled = false
        heartLineChart.xAxis.labelTextColor = UIColor.white
        heartLineChart.rightAxis.labelTextColor = UIColor.white
        heartLineChart.leftAxis.labelTextColor = UIColor.white
        let data = LineChartData()

        line1.fillColor = UIColor.red
        data.addDataSet(line1)

        heartLineChart.data = data



    }
    
}
