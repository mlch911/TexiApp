//
//  HomeVC.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/1.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import RevealingSplashView
import Sparrow
import Firebase
import JHSpinner
import NotificationBannerSwift

class HomeVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionBtn: RoundedShadowButton!
    @IBOutlet weak var centerBtn: UIButton!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationCircle: CircleView!
    
    @IBAction func actionBtnPressed(_ sender: Any) {
        actionBtn.animateButton(shouldLoad: true, withMessage: nil)
        if UserDefaults.standard.value(forKey: "hasUserData") as? Bool == true {
            if UserDefaults.standard.value(forKey: "isDriver") as? Bool == true {
                if actionBtn.titleLabel?.text == "Arrive to Pickup Point" {
                    actionBtn.animateButton(shouldLoad: false, withMessage: "Pickup Passenger")
                } else {
                    if actionBtn.titleLabel?.text == "Pickup Passenger" {
                        showWayToPassenger(wayTo: .destination)
                        actionBtn.animateButton(shouldLoad: false, withMessage: "Arrival Destination")
                    } else {
                        if actionBtn.titleLabel?.text == "Arrival Destination" {
                            UpdateService.instance.finishTrip()
                        } else {
                            actionBtn.animateButton(shouldLoad: false, withMessage: "You're A Driver")
                        }
                    }
                }
            } else {
                var hasDestination = false
                for annotation in mapView.annotations {
                    if annotation.isKind(of: MKPointAnnotation.self) {
                        UpdateService.instance.updateTripForPassengerRequest()
                        destinationTextField.isUserInteractionEnabled = false
                        hasDestination = true
                    }
                }
                guard hasDestination else {
                    actionBtn.animateButton(shouldLoad: false, withMessage: "Destination Required")
                    return
                }
            }
        } else {
            menuBtnPressed(self)
            let banner = NotificationBanner(title: "请登录或注册。", subtitle: "点击下方Sign in/Login来登录或注册账号。", style: .warning)
            banner.show()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.actionBtn.animateButton(shouldLoad: false, withMessage: "Request Ride")
        }
    }
    
    @IBAction func centerBtnPressed(_ sender: Any) {
//        if let tripCoordinate = UserDefaults.standard.value(forKey: "tripCoordinate") as? Array<Any> {
//            if tripCoordinate.count != 0 {
//                zoom(toFitAnntationsFromMapView: self.mapView)
//            } else {
//                centerMapOnUserLocation()
//                centerBtn.fadeTo(alphaValue: 0.0, withDuration: 0.5)
//            }
//        } else {
//            centerMapOnUserLocation()
//            centerBtn.fadeTo(alphaValue: 0.0, withDuration: 0.5)
//        }
        var countAnnotations = 0
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self) {
            countAnnotations += 1
        }
        if countAnnotations > 1 {
            zoom(toFitAnntationsFromMapView: self.mapView)
            centerBtn.fadeTo(alphaValue: 0.0, withDuration: 0.5)
        } else {
            centerMapOnUserLocation()
            centerBtn.fadeTo(alphaValue: 0.0, withDuration: 0.5)
        }
    }
    
    @IBAction func menuBtnPressed(_ sender: Any) {
        view.endEditing(true)
        delegate?.toggleLeftPanel()
    }
    
    @IBAction func userImagePressed(_ sender: Any) {
        delegate?.toggleLeftPanel()
    }
    
    var delegate: CenterVCDelegate?
    
    var manager: CLLocationManager?
    
    let queue_UserInteractive = DispatchQueue.init(label: "tech.mluoc.queueUserInteractive", qos: .userInteractive, attributes: .concurrent)
    let queue_UserInitiated = DispatchQueue.init(label: "tech.mluoc.queueUserInitiated", qos: .userInitiated, attributes: .concurrent)
    let queue_Utility = DispatchQueue.init(label: "tech.mluoc.queueUtility", qos: .utility, attributes: .concurrent)
    let queue_Background = DispatchQueue.init(label: "tech.mluoc.queueBackground", qos: .background, attributes: .concurrent)
    
    var tableView = UITableView()
    var matchingLocations: [MKMapItem] = [MKMapItem]()
    
    let revealingSplashView = RevealingSplashView(iconImage: #imageLiteral(resourceName: "launchScreenIcon"), iconInitialSize: CGSize.init(width: 100, height: 100), backgroundColor: UIColor.white)
    
    var spinner = JHSpinnerView()
    
    var selectedLocationPlacemark: MKPlacemark? = nil
    
    var regionRadius: CLLocationDistance = 500
    
    var route: MKRoute!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        
        manager = CLLocationManager()
        manager?.delegate = self
        mapView.delegate = self
        destinationTextField.delegate = self
        
        queue_UserInitiated.async{
            self.centerMapOnUserLocation()
        }
        view.addSubview(self.revealingSplashView)
        revealingSplashView.animationType = .heartBeat
        revealingSplashView.startAnimation()
        revealingSplashView.heartAttack = true
        
        queue_Background.async {
            FirebaseDataService.FRinstance.checkUserStatus()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            SPRequestPermission.dialog.interactive.present(on: self, with: [.locationWhenInUse])
        }
        checkLocationAuthStatus()
        queue_Background.async {
            self.loadDriverAnnotations()
            if UserDefaults.standard.value(forKey: "hasUserData") as? Bool == false {
                self.removeFromMapView()
                return
            }
            if UserDefaults.standard.value(forKey: "hasUserData") as? Bool == true {
                if UserDefaults.standard.value(forKey: "isDriver") as! Bool && UserDefaults.standard.value(forKey: "driverIsOnTrip") as! Bool == true {
                self.showWayToPassenger(wayTo: .passenger)
                }
            }
            if UserDefaults.standard.value(forKey: "requireClean") as? Bool == true {
                self.removeFromMapView()
                UserDefaults.standard.set(false, forKey: "requireClean")
            }
        }
        observeRideRequest()
    }
    
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            manager?.desiredAccuracy = kCLLocationAccuracyBest
            manager?.startUpdatingLocation()
        }
    }
    
    func loadDriverAnnotations() {
        FirebaseDataService.FRinstance.REF_DRIVERS.observe(.value, with: { snapshot in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for driver in driverSnapshot {
                    if driver.childSnapshot(forPath: "isPickupModeEnable").value as? Bool == true && driver.childSnapshot(forPath: "driverIsOnTrip").value as? Bool == false {
                        if driver.hasChild("coordinate") {
                            if let driverDict = driver.value as? Dictionary<String, AnyObject> {
                                let coordinateArray = driverDict["coordinate"] as! NSArray
                                let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateArray[0] as! CLLocationDegrees, longitude: coordinateArray[1] as! CLLocationDegrees)
                                let annotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driver.key)
                                
                                var driverIsVisible: Bool {
                                    return self.mapView.annotations.contains(where: { (annotation) -> Bool in
                                        if let driverAnnotation = annotation as? DriverAnnotation {
                                            if driverAnnotation.key == driver.key {
                                                driverAnnotation.update(annotationPosition: driverAnnotation, withCoordinate: driverCoordinate)
                                                return true
                                            }
                                        }
                                        return false
                                    })
                                }
                                if !driverIsVisible {
                                    self.mapView.addAnnotation(annotation)
                                }
                            }
                        }
                    } else {
                        for annotation in self.mapView.annotations {
                            if annotation.isKind(of: DriverAnnotation.self) {
                                if let annotation = annotation as? DriverAnnotation {
                                    if annotation.key == driver.key {
                                        self.mapView.removeAnnotation(annotation)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    func observeRideRequest() {
        if UserDefaults.standard.value(forKey: "isDriver") as? Bool == true {
            if UserDefaults.standard.value(forKey: "driverIsOnTrip") as? Bool == false {
                if UserDefaults.standard.value(forKey: "isPickupModeEnable") as? Bool == true {
                    queue_Background.async {
                        UpdateService.instance.observeTrips(handler: { (tripDict) in
                            if let tripDict = tripDict {
                                let pickupCoordinateArray = tripDict["pickupCoordinate"] as! NSArray
                                let destinationCoordinateArray = tripDict["destinationCoordinate"] as! NSArray
                                let tripKey = tripDict["passengerKey"] as! String
                                let tripIsAccepted = tripDict["tripIsAccepted"] as! Bool
                                
                                guard tripIsAccepted else {
                                    let currentCoordinate = self.mapView.userLocation.coordinate
                                    let pickupVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PickupVC") as? PickupVC
                                    pickupVC?.initData(passengerCoordinate: CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees), destinationCoordinate: CLLocationCoordinate2D(latitude: destinationCoordinateArray[0] as! CLLocationDegrees, longitude: destinationCoordinateArray[1] as! CLLocationDegrees), currentCoordinate: currentCoordinate, passengerKey: tripKey, driverKey: (Auth.auth().currentUser?.uid)!)
                                    self.present(pickupVC!, animated: true, completion: nil)
                                    return
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    func showWayToPassenger(wayTo: annotationType) {
        UpdateService.instance.trips.observeSingleEvent(of: .value, with: { (snapshot) in
            if let tripSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for trip in tripSnapshot {
                    if trip.childSnapshot(forPath: "driverKey").value as? String == Auth.auth().currentUser!.uid {
                        let pickupCoordinateArray = trip.childSnapshot(forPath: "pickupCoordinate").value as! NSArray
                        let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                        let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                        let destinationCoordinateArray = trip.childSnapshot(forPath: "destinationCoordinate").value as! NSArray
                        let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0] as! CLLocationDegrees, longitude: destinationCoordinateArray[1] as! CLLocationDegrees)
                        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                        
                        switch wayTo {
                        case .passenger:
                            self.dropPinFor(placemarks: [pickupPlacemark: .passenger, destinationPlacemark: .destination])
                            self.searchMapKitForResultsWithPolyline(forMapLocation: MKMapItem(placemark: pickupPlacemark))
                        case .destination:
//                            self.dropPinFor(placemarks: [pickupPlacemark: .passenger, destinationPlacemark: .destination])
                            self.searchMapKitForResultsWithPolyline(forMapLocation: MKMapItem(placemark: destinationPlacemark))
                        case .driver:
                            break
                        }
                    }
                }
            }
        }) { (error) in
            let banner = NotificationBanner(title: "Error!", subtitle: error.localizedDescription, style: .danger)
            banner.show()
            print(error.localizedDescription)
        }
    }
}

//MARK:  /**********CLLocationManagerDelegate**********/
extension HomeVC: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthStatus()
        if status == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
        }
    }

    func centerMapOnUserLocation() {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
}

//MARK:  /**********MKMapViewDelegate**********/
extension HomeVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if UserDefaults.standard.value(forKey: "isDriver") as? Bool == true {
            UpdateService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)
        } else {
            UpdateService.instance.updatePassengerLocation(withCoordinate: userLocation.coordinate)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let identifier = "driver"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                view?.annotation = annotation
            }
            view?.image = #imageLiteral(resourceName: "driverAnnotation")
            return view
        } else if let annotation = annotation as? PassengerAnnotation {
            let identifier = "passenger"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                view?.annotation = annotation
            }
            view?.image = #imageLiteral(resourceName: "currentLocationAnnotation")
            return view
        } else if let annotation = annotation as? MKPointAnnotation {
            let identifier = "destination"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                view?.annotation = annotation
            }
            view?.image = #imageLiteral(resourceName: "destinationAnnotation")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        centerBtn.fadeTo(alphaValue: 1.0, withDuration: 0.5)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRenderer = MKPolylineRenderer(polyline: route.polyline)
        lineRenderer.strokeColor = UIColor(red: 216/255, green: 71/255, blue: 30/255, alpha: 0.75)
        lineRenderer.lineWidth = 1
        
        zoom(toFitAnntationsFromMapView: self.mapView)
        
        return lineRenderer
    }
    
    func performSearch(searchWord: String) {
        matchingLocations.removeAll()
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchWord
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        
        search.start { (response, error) in
            if error == nil {
                if response?.mapItems.count == 0 {
                    print("No result!")
                } else {
                    for mapItem in response!.mapItems {
                        self.matchingLocations.append(mapItem)
                        self.tableView.reloadData()
                    }
                }
            } else {
                print(error.debugDescription)
            }
        }
    }
    
    func dropPinFor(placemarks: Dictionary<MKPlacemark, annotationType>) {
//        selectedLocationPlacemark = placemark
        
        for annotation in mapView.annotations {
            if annotation.isKind(of: MKPointAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
        }
        
        for placemark in placemarks {
            selectedLocationPlacemark = placemark.key
            
            switch placemark.value {
            case .destination:
                let annotation = MKPointAnnotation()
                annotation.coordinate = placemark.key.coordinate
                mapView.addAnnotation(annotation)
            case .driver:
                let annotation = DriverAnnotation(coordinate: placemark.key.coordinate, withKey: "")
                mapView.addAnnotation(annotation)
            case .passenger:
                let annotation = PassengerAnnotation(coordinate: placemark.key.coordinate, withKey: "")
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    func searchMapKitForResultsWithPolyline(forMapLocation mapLocation: MKMapItem) {
        let request = MKDirectionsRequest()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = mapLocation
        request.transportType = MKDirectionsTransportType.automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            guard let response = response else {
                print(error.debugDescription)
                return
            }
            self.route = response.routes[0]
            
            self.mapView.add(self.route.polyline)
            
            for subview in self.view.subviews {
                if subview.tag == 1006 {
//                    subview.removeFromSuperview()
                    self.spinner.dismiss()
                }
            }
        }
    }
    
    func zoom(toFitAnntationsFromMapView mapView: MKMapView) {
        if mapView.annotations.count == 0 {
            return
        }
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var buttomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self) {
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
            buttomRightCoordinate.longitude = fmax(buttomRightCoordinate.longitude, annotation.coordinate.longitude)
            buttomRightCoordinate.latitude = fmin(buttomRightCoordinate.latitude, annotation.coordinate.latitude)
        }
        var region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(topLeftCoordinate.latitude - (topLeftCoordinate.latitude - buttomRightCoordinate.latitude) * 0.5, topLeftCoordinate.longitude + (buttomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.5) , span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - buttomRightCoordinate.latitude) * 2.0, longitudeDelta: fabs(buttomRightCoordinate.longitude - topLeftCoordinate.longitude) * 2.0))
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }
}

//MARK:  /**********UITextFieldDelegate**********/
extension HomeVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == destinationTextField {
            var y: CGFloat = 0
            if UIScreen.main.bounds.height == 812 {
                y = 180
            } else {
                y = 160
            }
            if tableView.frame.origin.y != y {
                tableView.frame = CGRect(x: 20, y: view.frame.height, width: view.frame.width - 40, height: view.frame.height - y)
                tableView.layer.cornerRadius = 5.0
                tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
                
                tableView.delegate = self
                tableView.dataSource = self
                
                tableView.tag = 1004
                tableView.rowHeight = 60
                
                view.addSubview(tableView)
                animateTableView(shouldShow: true)
            }
            UIView.animate(withDuration: 0.2, animations: {
                self.destinationCircle.backgroundColor = UIColor.red
                self.destinationCircle.borderColor = UIColor.init(red: 199/255, green: 0/255, blue: 0/255, alpha: 1.0)
            })
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == destinationTextField {
            performSearch(searchWord: destinationTextField.text!)
            destinationTextField.endEditing(true)
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.destinationTextField.text == "" {
                self.matchingLocations = []
                self.tableView.reloadData()
            } else {
                self.performSearch(searchWord: self.destinationTextField.text!)
            }
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == destinationTextField {
            if destinationTextField.text == "" {
                UIView.animate(withDuration: 0.2, animations: {
                    self.destinationCircle.backgroundColor = UIColor.lightGray
                    self.destinationCircle.borderColor = UIColor.darkGray
                })
                animateTableView(shouldShow: false)
            }
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        cancel()
        removeFromMapView()
        centerMapOnUserLocation()
        queue_Background.async {
            if let _ = Auth.auth().currentUser {
                FirebaseDataService.FRinstance.REF_PASSENGERS.child((Auth.auth().currentUser?.uid)!).child("tripCoordinate").removeValue { (error, reference) in
                    if error != nil {
                        print(error.debugDescription)
                    }
                }
            }
        }
        return true
    }
    
    func cancel() {
        matchingLocations = []
        tableView.reloadData()
        UserDefaults.standard.set([], forKey: "tripCoordinate")
    }
    
    func removeFromMapView() {
        mapView.removeOverlays(mapView.overlays)
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
        UserDefaults.standard.set(false, forKey: "requireClean")
    }
    
    func animateTableView(shouldShow: Bool) {
        if shouldShow {
            UIView.animate(withDuration: 0.5, animations: {
                if UIScreen.main.bounds.height == 812 {
                    self.tableView.frame = CGRect(x: 20, y: 180, width: self.view.frame.width - 40, height: self.view.frame.height - 180)
                } else {
                    self.tableView.frame = CGRect(x: 20, y: 160, width: self.view.frame.width - 40, height: self.view.frame.height - 160)
                }
            })
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                self.tableView.frame = CGRect(x: 20, y: self.view.frame.height, width: self.view.frame.width - 40, height: self.view.frame.height - 180)
            }, completion: { (finished) in
                if finished {
                    for subview in self.view.subviews {
                        if subview.tag == 1004 {
                            subview.removeFromSuperview()
                        }
                    }
                }
            })
        }
    }
}

//MARK:  /**********UITableViewDelegate, UITableViewDataSource**********/
extension HomeVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "locationCell")
        let mapItem = matchingLocations[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingLocations.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mapView.removeOverlays(mapView.overlays)
        for annotation in mapView.annotations {
            if annotation.isKind(of: PassengerAnnotation.self) {
                mapView.removeAnnotation(annotation)
            } else if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            }
        }
        if UserDefaults.standard.value(forKey: "hasUserData") as? Bool == false {
            destinationTextField.text = ""
            view.endEditing(true)
            cancel()
            menuBtnPressed(self)
            let banner = NotificationBanner(title: "请登录或注册。", subtitle: "点击下方Sign in/Login来登录或注册账号。", style: .warning)
            banner.show()
        }
        if UserDefaults.standard.value(forKey: "isDriver") as? Bool == true {
            view.endEditing(true)
            let banner = NotificationBanner(title: "You're a Driver.", subtitle: "Driver can't request for a ride.", style: .warning)
            banner.show()
            
            let passengerCoordinate = mapView.userLocation.coordinate
            let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate, withKey: (Auth.auth().currentUser?.uid)!)
            mapView.addAnnotation(passengerAnnotation)
            destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
            let selectedLocation = matchingLocations[indexPath.row]
            dropPinFor(placemarks: [selectedLocation.placemark: .destination])
            searchMapKitForResultsWithPolyline(forMapLocation: selectedLocation)
            destinationTextField.endEditing(true)
            animateTableView(shouldShow: false)
            return
        }
        
        let passengerCoordinate = mapView.userLocation.coordinate
        let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate, withKey: (Auth.auth().currentUser?.uid)!)
        mapView.addAnnotation(passengerAnnotation)
        destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        let selectedLocation = matchingLocations[indexPath.row]

        DispatchQueue.main.async {
            self.spinner = JHSpinnerView.showOnView(self.view, spinnerColor: UIColor.red, overlay: .roundedSquare, overlayColor: UIColor.white.withAlphaComponent(0.6))
            self.spinner.tag = 1006
            self.view.addSubview(self.spinner)
        }
        queue_Background.async {
            FirebaseDataService.FRinstance.REF_PASSENGERS.child((Auth.auth().currentUser?.uid)!).updateChildValues(["tripCoordinate": [selectedLocation.placemark.coordinate.latitude, selectedLocation.placemark.coordinate.longitude]]) { (error, reference) in
                if error == nil {
                    UserDefaults.standard.set([selectedLocation.placemark.coordinate.latitude, selectedLocation.placemark.coordinate.longitude], forKey: "tripCoordinate")
                    
                    self.dropPinFor(placemarks: [selectedLocation.placemark: .destination])
                    self.searchMapKitForResultsWithPolyline(forMapLocation: selectedLocation)
                    
                    self.destinationTextField.endEditing(true)
                    self.animateTableView(shouldShow: false)
                } else {
                    print(error.debugDescription)
                }
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if destinationTextField.text == "" {
            animateTableView(shouldShow: false)
        }
    }
}
