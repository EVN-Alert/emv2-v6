//
//  ViewController.swift
//  emv2
//
//  Created by Roen Wainscoat on 10/19/17.
//  Copyright © 2017 Roen Wainscoat. All rights reserved.
//

import UIKit
import MapKit
import AudioToolbox
import AVFoundation

class ViewController: UIViewController, CLLocationManagerDelegate {
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    var myTimer: Timer? = nil
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var myLatitude: UITextField!
    @IBOutlet weak var myLongitude: UITextField!
    @IBOutlet weak var evLatitude: UITextField!
    @IBOutlet weak var evLongitude: UITextField!
    @IBOutlet weak var evDistance: UITextField!
    @IBOutlet weak var EVARView: UILabel!
    @IBOutlet weak var EVARSwitch: UISwitch!
    @IBAction func EVARSwitch(_ sender: UISwitch) {
        if EVARSwitch.isOn {
            EVARView.text = "Fetching EV Location"
            myTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(evLoad), userInfo: nil, repeats: true)
            } else {
            EVARView.text = "Inactive"
            myTimer?.invalidate()
            myTimer = nil
        }
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate  = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        evLoad()
        EVARView.text = "Inactive"
        // Do any additional setup after loading the view, typically from a nib.
}
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            print("GPS allowed.")
        }
        else {
            print("GPS not allowed.")
            return
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let myCoordinate = locationManager.location?.coordinate
        altitude = locationManager.location?.altitude
        latitude = myCoordinate?.latitude
        longitude = myCoordinate?.longitude
        
        myLatitude.text = String(latitude!)
        myLongitude.text = String(longitude!)
    }
    
    @objc func evLoad() {
        super.viewDidLoad()
        fetchURL()
       // performSelector(inBackground: #selector(fetchURL), with: nil)
    }
    
    var evLocDidRefresh = false
    var once = 0
    
    func fetchURL() {
        var data = "00 A 0.0 0.0"
        if let url = URL(string: "https://roen.us/wapps/dev/evn/evn.txt") {
            do {
                data = "7 A 7.0 7.0"
                let data = try String(contentsOf: url)
                let allEvData = data.components(separatedBy: " ")
                evLatitude.text = allEvData[2]
                evLongitude.text = allEvData[3]
                let evlatNum = Double(evLatitude.text ?? "") ?? 0.0
                let evlonNum = Double(evLongitude.text ?? "") ?? 0.0
                let mylatNum = Double(myLatitude.text ?? "") ?? 0.0
                let mylonNum = Double(myLongitude.text ?? "") ?? 0.0
                let dlat: Double = mylatNum - evlatNum
                let dlon: Double = (mylonNum - evlonNum) * 0.931
                let distance: Double = sqrt(dlat * dlat + dlon * dlon) * 111325.0
                let idistance = Int32(distance)
                evDistance.text = String(idistance)
                //evDistance.text = "33"
                evLocDidRefresh = true
                if distance < 700 {
                    if once == 0 {
                        once = 1
                        let alert = UIAlertController(title: "Warning!", message: "Emergency vehicle nearby", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("Acknowledge", comment: "Default action"), style: .`default`, handler: { _ in
                            NSLog("The \"OK\" alert occured.")
                        }))
                        self.present(alert, animated: true, completion: nil)
                                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                        let systemSoundID: SystemSoundID = 1333
                        AudioServicesPlaySystemSound(systemSoundID)
                    }
                }
            } catch {
                // error loading
                data = "9 A 9.0 9.0"
                let data = data.components(separatedBy: " ")
                evLatitude.text = data[1]
                evLongitude.text = data[2]
            }
        } else {
            // url bad
            data = "4 A 4.0 4.0"
        }
//        data = "2 A 2.0 2.0"
    }
    
    @IBAction func evRefresh(_ sender: UIButton) {
        evLoad()
        print("Refresh queued")
        sleep(1)
        if evLocDidRefresh == true {
            print("Refreshed from source")
            evLocDidRefresh = false
        } else {
            print("There was an error refreshing EVInfo from source. Please try again!")
        }
    }


    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

