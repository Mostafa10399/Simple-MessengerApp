//
//  LocationPickerViewController.swift
//  Flash Chat iOS13
//
//  Created by Mostafa Mahmoud on 1/22/22.
//  Copyright © 2022 Angela Yu. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
//MARK: - Location Picker Delegate
protocol LocationPickerDelegate: AnyObject
{
    func viewError(error:Error)
    func sendCordinate(_ newLocation:LocationPickerViewController,cordinate:CLLocationCoordinate2D)
}
//MARK: - class location Picker
class LocationPickerViewController: UIViewController,CLLocationManagerDelegate {
  
    
 
    //MARK: - IBOutlets
    @IBOutlet weak var sendButtonOutLet: UIBarButtonItem!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var map: MKMapView!
    //MARK: - variables
    var isPickable:Bool?
    var coordinatesSend:CLLocationCoordinate2D?
    let locationManager = CLLocationManager()
    var rightBarButtonItem : UIBarButtonItem!
    weak var delegate:LocationPickerDelegate?
    var coordinates:CLLocationCoordinate2D?
    var completion: ((CLLocationCoordinate2D)->Void)?
    var currentCordenate :CLLocationCoordinate2D?
    
    //MARK: - View DId Load
    override func viewDidLoad() {
        super.viewDidLoad()

        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        if let ip = isPickable,ip == true
        {
            locationButton.isHidden = false
            map.isUserInteractionEnabled = true
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
            navigationItem.title = "Pick Location"
            sendButtonOutLet.isEnabled = true
            sendButtonOutLet.title = "Send"

        }
        else
        {

            locationButton.isHidden = true

            guard let longitude = self.coordinatesSend?.longitude,let latitude = self.coordinatesSend?.latitude else
            {
                return
            }
            let center = CLLocationCoordinate2D(latitude: latitude, longitude:longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))

                   self.map.setRegion(region, animated: true)
            sendButtonOutLet.title = ""
            sendButtonOutLet.isEnabled = false
       
            guard let coordinates = self.coordinatesSend  else
            {
                return
            }
            sendButtonOutLet.customView?.isHidden = true

            navigationItem.title = "Location"
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
            
        }
        
        
        // Do any additional setup after loading the view.
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let ip = isPickable,ip == true
        {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return
            
        }
            let center = CLLocationCoordinate2D(latitude: locValue.latitude, longitude:locValue.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            self.map.setRegion(region, animated: true)
            currentCordenate = locValue
            
        }
    }
//MARK: - Send Button
    @IBAction func sendButtonAction(_ sender: UIBarButtonItem) {
        if let coordinates = coordinates {
            print("i am in coordinate")
            navigationController?.popViewController(animated: true)
            delegate?.sendCordinate(self,cordinate: coordinates)
            print(coordinates.latitude)
            print(coordinates.longitude)
        
//            completion?(coordinates)
        }
           }
    
    @IBAction func getCurrentLocation(_ sender: UIButton) {
        guard let currentLoc = currentCordenate else
        {
            return
        }
        print("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++__________________________")
        print(currentLoc)
        self.coordinates = currentLoc
        for annotation in map.annotations
        {
            map.removeAnnotation(annotation)
        }
        
        
        let pin = MKPointAnnotation()
        pin.coordinate = currentLoc
        map.addAnnotation(pin)
        let center = CLLocationCoordinate2D(latitude: currentLoc.latitude, longitude:currentLoc.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
        self.map.setRegion(region, animated: true)
        
    }
    
    //MARK: - Did tap map
    @objc func didTapMap(_ gesture:UITapGestureRecognizer)
    {
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        //drop pin for location
        for annotation in map.annotations
        {
            map.removeAnnotation(annotation)
        }
        
        
        
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
        
        
        
    }
}
