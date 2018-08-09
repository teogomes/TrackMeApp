//
//  ViewController.swift
//  hh
//
//  Created by Teodoro Gomes on 12/07/2018.
//  Copyright © 2018 Teodoro Gomes. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreMotion
import CoreLocation
import HealthKit
import Charts

class ViewController: UIViewController , CLLocationManagerDelegate {

    var pedometer = CMPedometer()
    var myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(0,0)
    let apiKey = "1c4f7b36ac9324cf27e477de0db76bfd"
    let manager = CLLocationManager()
    let healthKitStore:HKHealthStore = HKHealthStore()
    var buttonPressed:Date = Date()
    var numOfSteps = 0
    var timer = Timer()
    let timerInterval = 1.0
    var timeElapsed:TimeInterval = 0.0
    let target = 100
    var textView3:UILabel = UILabel()
    let shapeLayer = CAShapeLayer()
    var maxSteps = 0
  
    
    @IBOutlet weak var lineChart: LineChartView!
    @IBOutlet weak var gifView: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        authorHealthKit()
        // Do any additional setup after loading the view, typically from a nib.
        
        // User Location
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        makeProgressBar()
       
        updateGraph()
        gifView.loadGif(name: "heartbeat")
        
        
        //Repositionings
        cityLabel.center = CGPoint(x: cityLabel.center.x, y: cityLabel.center.y - 60)
        tempLabel.center = CGPoint(x: tempLabel.center.x - 60, y: tempLabel.center.y)
//        iconView?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
    }
    

    func heartBeat(startOfTime:Date){
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        
        //SECOND TEST
        let now = Date()
        print("starTime: \(startOfTime) endTime: \(now)")
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfTime, end: now, options: .strictStartDate)
        
        
        let sortByTime = NSSortDescriptor(key:HKSampleSortIdentifierEndDate, ascending:false)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm:ss"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YYYY"
        
        
        let query = HKSampleQuery(sampleType:heartRateType, predicate:predicate, limit:20, sortDescriptors:[sortByTime], resultsHandler:{(query, results, error) in
            
            guard let results = results else { return }
            for quantitySample in results {
                let quantity = (quantitySample as! HKQuantitySample).quantity
                let heartRateUnit = HKUnit(from: "count/min")
//                print(quantity.doubleValue(for: heartRateUnit))
//                 print("\(timeFormatter.stringFromDate(quantitySample.startDate)),\(dateFormatter.stringFromDate(quantitySample.startDate)),\(quantity.doubleValueForUnit(heartRateUnit))")
                print("\(timeFormatter.string(from: quantitySample.startDate)) , \(dateFormatter.string(from: quantitySample.endDate)) , \(quantity.doubleValue(for: heartRateUnit))")
                
            }
        })
        healthKitStore.execute(query)
    }

    
    func requestWeather(lat:String , long:String) {
        Alamofire.request("https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(long)&appid=\(apiKey)&units=metric").responseJSON { response in
            if let responseStr = response.result.value {
                let jsonResponse = JSON(responseStr)
                let jsonWeather = jsonResponse["weather"].array![0]
                let weather = jsonWeather["main"].stringValue
                let jsonTemp = jsonResponse["main"]
                let temp = jsonTemp["temp"].stringValue
                let cityName = jsonResponse["name"] .stringValue
//                print("temp = \(temp) cityName = \(cityName) and \(weather)")
                
                if(self.cityLabel.text != cityName){
                    self.someAnimations(object: "other")
                }
                self.cityLabel.text = cityName
                self.tempLabel.text = "\(temp) °C"
                switch(weather){
                case "Clouds":
                    self.iconView.image = #imageLiteral(resourceName: "clouds")
                    break
                case "Sunny":
                    self.iconView.image = #imageLiteral(resourceName: "Sunny-icon")
                case "Mist":
                    self.iconView.image = #imageLiteral(resourceName: "mist")
                default:
                    self.iconView.image = #imageLiteral(resourceName: "Sunny-icon")
                    break
                }
            }
        }
    }
    
    
    
    
    @IBAction func startUpdate(_ sender: UIButton) {
        if(sender.titleLabel?.text == "Start"){
            sender.setTitle("Stop", for: .normal)
            //GIF LOADER
           
            gifView.isHidden = false
            someAnimations(object: "gifViewIN")
            startTimer()
            //Custom date to simulate heartbeat Data
            lineChart.isHidden = false
            let customDate = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!
        
            buttonPressed = customDate
            pedometer.startUpdates(from: Date()) { (data, error) in
                if let pedData = data {
                    print(pedData.numberOfSteps)
                   self.numOfSteps = Int(pedData.numberOfSteps)
                    print("To Firebase..")
                    print("Steps:\(pedData.numberOfSteps) Coordinates x: \(self.myLocation.latitude) y: \(self.myLocation.longitude)")
                  
                }
                else{
                    
                    print("Steps Counter Not Available")
                }
            }
            print("requesting Data..")
            
            
            
            
        }else{
            someAnimations(object: "gifViewOUT")
//            gifView.isHidden = true
            heartBeat(startOfTime: buttonPressed)
            stopTimer()
            sender.setTitle("Start", for: .normal)
            pedometer.stopUpdates()
        }
        
    }
    
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        myLocation = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
    }
    
    
    func updateStepsView(){
      
        if(numOfSteps > maxSteps){
            textView3.text = "\(numOfSteps) / \(target)"
            textView3.sizeToFit()
            
            //Progress Animation
            let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
            basicAnimation.fromValue = 0.8 * (Double(maxSteps) / 100.0)
            basicAnimation.toValue =  0.8 * (Double(numOfSteps) / 100.0)
            basicAnimation.duration = 2
            basicAnimation.fillMode = kCAFillModeForwards
            basicAnimation.isRemovedOnCompletion = false
            shapeLayer.add(basicAnimation, forKey: "basic")
            maxSteps = numOfSteps
        }
       
      
    }
    
    
    
    func makeProgressBar() {
        let pos = CGPoint(x: view.center.x, y: view.center.y - 100)
        
         let circularPath = UIBezierPath(arcCenter: pos, radius: 100, startAngle: -CGFloat.pi / 2, endAngle: 2 * CGFloat.pi, clockwise: true)
        
        let trackerLayer = CAShapeLayer()
       
        trackerLayer.lineCap = kCALineCapRound
        trackerLayer.fillColor = UIColor.clear.cgColor
        trackerLayer.path = circularPath.cgPath
        trackerLayer.strokeColor = UIColor.lightGray.cgColor
        trackerLayer.lineWidth = 10
        view.layer.addSublayer(trackerLayer)
        
        
        
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.path = circularPath.cgPath
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.lineWidth = 10
        shapeLayer.strokeEnd = 0
        
        
        let textView = UILabel(frame: CGRect(x: pos.x , y: pos.y - 40 , width: 30, height: 30))
        textView.text = " Steps"
        textView.sizeToFit()
        textView.center.x = self.view.center.x
        textView.textColor = UIColor.white
        view.addSubview(textView)
        
        
        textView3 = UILabel(frame: CGRect(x: pos.x , y: pos.y - 10 , width: 30, height: 30))
        textView3.text = "0 / 100"
        textView3.sizeToFit()
        textView3.center.x = self.view.center.x
        textView3.textColor = UIColor.white
        view.addSubview(textView3)
        
//
       
        view.layer.addSublayer(shapeLayer)
    }

    
    func authorHealthKit(){



        let healthKitTypesToRead : Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        if !HKHealthStore.isHealthDataAvailable(){
            print("error")
            return
        }

        healthKitStore.requestAuthorization(toShare: nil, read: healthKitTypesToRead) { (success, error) in
            print(success)
        }
    }
    
    //Timers Funcs
    func startTimer(){
        if timer.isValid{ timer.invalidate()}
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true, block: { (Timer) in
            self.updateStepsView()
            self.requestWeather(lat: String(self.myLocation.latitude), long: String(self.myLocation.longitude))
        })
    }
    func stopTimer(){
         timer.invalidate()
    }
    
    //Graph
    
    func updateGraph(){
        
        var lineChartEntry = [ChartDataEntry]()
        let numbers = [80,90,100,110,76,80,67]
        var circleColors: [NSUIColor] = []
        
        for i in 0..<numbers.count {
            let value = ChartDataEntry(x: Double(i), y: Double(numbers[i]))
            lineChartEntry.append(value)
    
            let color = UIColor.black
            circleColors.append(color)
        }
        let line1 = LineChartDataSet(values: lineChartEntry, label:"")
        line1.circleRadius = 4.0
        line1.mode = LineChartDataSet.Mode.linear
        line1.drawValuesEnabled = false
        line1.drawIconsEnabled = false
        line1.drawFilledEnabled = true
        print(LineChartView.description())
        line1.colors = [UIColor.red]
        lineChart.chartDescription?.enabled = false
        lineChart.xAxis.labelTextColor = UIColor.white
        lineChart.rightAxis.labelTextColor = UIColor.white
        lineChart.leftAxis.labelTextColor = UIColor.white
        let data = LineChartData()
        
        line1.fillColor = UIColor.red
        data.addDataSet(line1)
        
        lineChart.data = data
       
       
    
    }
    
    func someAnimations(object:String){
        switch object {
        case "gifViewIN":
             gifView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            break
        case "other":
             iconView?.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            break
        default:
            break
        }
      
        
        UIView.animate(withDuration: 0.6, delay: 0.0, options: .curveLinear, animations: {
                switch(object){
                case "gifViewIN":
                     self.gifView.transform = CGAffineTransform(scaleX: 1, y: 1)
                    break
                case "gifViewOUT":
                    self.gifView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
//                    self.gifView.isHidd
                    break
                default:
                    self.cityLabel.center = CGPoint(x: self.cityLabel.center.x, y: self.cityLabel.center.y + 60)
                    self.tempLabel.center = CGPoint(x: self.tempLabel.center.x + 60, y: self.tempLabel.center.y)
                    self.iconView?.transform = CGAffineTransform(scaleX: 1, y: 1)
                    break
                }
          
        }, completion:{ (finished:Bool) in
            if(object == "gifViewOUT"){
                self.gifView.isHidden = true
            }
            
        })
    }
}

