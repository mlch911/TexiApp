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
import LeanCloud
import JHSpinner
import NotificationBannerSwift

class HomeVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionBtn: RoundedShadowButton!
    @IBOutlet weak var centerBtn: UIButton!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationCircle: CircleView!
    @IBOutlet weak var cancelBtn: UIButton!
    
    @IBAction func closeToHome(segue: UIStoryboardSegue) {}
    
    @IBAction func actionBtnPressed(_ sender: Any) {
        actionBtn.animateButton(shouldLoad: true, withMessage: nil)
        if UserDefaults.standard.value(forKey: "hasUserData") as? Bool == true {
            if UserDefaults.standard.value(forKey: "isDriver") as? Bool == true {
                if actionBtn.titleLabel?.text == "Arrive to Pickup Point" {
                    actionBtn.animateButton(shouldLoad: false, withMessage: "Pickup Passenger")
                } else {
                    if actionBtn.titleLabel?.text == "Pickup Passenger" {
                        showWayTo(wayTo: .destination)
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
                        destinationTextField.isUserInteractionEnabled = false
                        hasDestination = true
                    }
                }
                if hasDestination {
                    mapView.removeAnnotations(mapView.annotations)
                    UpdateService.instance.updateTripForPassengerRequest { (isSuccess) in
                        if isSuccess {
                            self.cancelBtn.isHidden = false
                            self.queue_Background.async {
                                for _ in 1...999 {
                                    self.checkTripStep()
                                }
                            }
                        } else {
                            let banner = NotificationBanner(title: "Error", subtitle: "请求失败，请重试！", style: .danger)
                            banner.show()
                            self.actionBtn.animateButton(shouldLoad: false, withMessage: "Request Ride")
                        }
                    }
                } else {
                    actionBtn.animateButton(shouldLoad: false, withMessage: "Destination Required")
                }
            }
        } else {
            menuBtnPressed(self)
            let banner = NotificationBanner(title: "请登录或注册。", subtitle: "点击下方Sign in/Login来登录或注册账号。", style: .warning)
            banner.show()
        }
    }
    
    @IBAction func centerBtnPressed(_ sender: Any) {
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
    
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        if UserDefaults.standard.value(forKey: "isDriver") as? Bool == true {
            UpdateService.instance.cancelTripForDriver()
        } else {
            UpdateService.instance.cancelTripForPassenger()
        }
        cancelBtn.isHidden = true
    }
    
    var delegate: CenterVCDelegate?
    
    var manager: CLLocationManager?
    
    let queue_UserInteractive = DispatchQueue.init(label: "tech.mluoc.queueUserInteractive", qos: .userInteractive, attributes: .concurrent)
    let queue_UserInitiated = DispatchQueue.init(label: "tech.mluoc.queueUserInitiated", qos: .userInitiated, attributes: .concurrent)
    let queue_Utility = DispatchQueue.init(label: "tech.mluoc.queueUtility", qos: .utility, attributes: .concurrent)
    let queue_Background = DispatchQueue.init(label: "tech.mluoc.queueBackground", qos: .background, attributes: .concurrent)
    
//    var isDriver = UserDefaults.standard.value(forKey: "isDriver") as? Bool
//    var isOnTrip = UserDefaults.standard.value(forKey: "isOnTrip") as? Bool
//    var isPickupModeEnable = UserDefaults.standard.value(forKey: "isPickupModeEnable") as? Bool
//    var hasUserData = UserDefaults.standard.value(forKey: "hasUserData") as? Bool
//    var requireClean = UserDefaults.standard.value(forKey: "requireClean") as? Bool
    
    var tableView = UITableView()
    var matchingLocations: [MKMapItem] = [MKMapItem]()
    let revealingSplashView = RevealingSplashView(iconImage: #imageLiteral(resourceName: "launchScreenIcon"), iconInitialSize: CGSize.init(width: 100, height: 100), backgroundColor: UIColor.white)
    var spinner = JHSpinnerView()
    var selectedLocationPlacemark: MKPlacemark? = nil
    var regionRadius: CLLocationDistance = 500
    var route: MKRoute!
    var search: MKLocalSearch!
    
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
        cancelBtn.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        checkLocationAuthStatus()
        if LCUser.current?.get("isOnTrip")?.rawValue as? Bool == true {
            self.cancelBtn.isHidden = false
        }
        queue_Background.async {
            for _ in 1...999 {
                if LCUser.current?.get("isOnTrip")?.rawValue as? Bool == false {
                    self.loadDriverAnnotations()
                    if LCUser.current?.get("isDriver")?.rawValue as? Bool == true {
                        self.observeRideRequest()
                    }
                }
                DataService.instance.syncUserStatus()
                sleep(5)
            }
            if UserDefaults.standard.value(forKey: "hasUserData") as? Bool == false {
                self.removeFromMapView()
                return
            }
            if UserDefaults.standard.value(forKey: "hasUserData") as? Bool == true && UserDefaults.standard.value(forKey: "isDriver") as? Bool == true && UserDefaults.standard.value(forKey: "isOnTrip") as? Bool == true {
                self.queue_Background.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.showWayTo(wayTo: .passenger)
                })
            }
            if UserDefaults.standard.value(forKey: "requireClean") as? Bool == true {
                self.removeFromMapView()
                UserDefaults.standard.set(false, forKey: "requireClean")
            }
        }
    }
    
    func checkLocationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            manager?.desiredAccuracy = kCLLocationAccuracyBest
            manager?.startUpdatingLocation()
        } else {
            SPRequestPermission.dialog.interactive.present(on: self, with: [.locationWhenInUse])
        }
    }
    
    func loadDriverAnnotations() {
        DataService.instance.loadDriverAnnotations(handler: { (isSuccess, drivers) in
            if isSuccess {
                for annotation in self.mapView.annotations {
                    if annotation.isKind(of: DriverAnnotation.self) {
                        self.mapView.removeAnnotation(annotation)
                    }
                }
                for driver in drivers! {
                    let driverCoordinate = CLLocationCoordinate2D(latitude: driver.value[0], longitude: driver.value[1])
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
        })
    }
    
    func observeRideRequest() {
        if UserDefaults.standard.value(forKey: "isDriver") as? Bool == true && UserDefaults.standard.value(forKey: "isOnTrip") as? Bool == false && UserDefaults.standard.value(forKey: "isPickupModeEnable") as? Bool == true {
            queue_Background.async {
                UpdateService.instance.observeTrips(handler: { (trip) in
                    let pickupCoordinateArray = trip.get("pickupCoordinate")?.rawValue as! [Double]
                    let destinationCoordinateArray = trip.get("destinationCoordinate")?.rawValue as! [Double]
                    let tripKey = trip.passengerKey.stringValue
                    let isTripAccepted = trip.isTripAccepted.rawValue as! Bool
                    
                    guard isTripAccepted else {
                        let currentCoordinate = self.mapView.userLocation.coordinate
                        let pickupVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PickupVC") as? PickupVC
                        pickupVC?.initData(
                            passengerCoordinate: CLLocationCoordinate2D(latitude: pickupCoordinateArray[0], longitude: pickupCoordinateArray[1]),
                            destinationCoordinate: CLLocationCoordinate2D(latitude: destinationCoordinateArray[0], longitude: destinationCoordinateArray[1]),
                            currentCoordinate: currentCoordinate, passengerKey: tripKey!, driverKey: (LCUser.current?.objectId?.stringValue)!, tripKey: (trip.objectId?.stringValue)!
                        )
                        self.present(pickupVC!, animated: true, completion: nil)
                        return
                    }
                })
            }
        }
        
        let firstQuery = LCQuery(className: "Trip")
        firstQuery.whereKey("isTripAccepted", .equalTo(false))
        let secondQuery = LCQuery(className: "Trip")
        secondQuery.didChangeValue(forKey: "addTime")
    }
    
    func showWayTo(wayTo: AnnotationType) {
        if UserDefaults.standard.value(forKey: "isDriver") as? Bool == true {
            let query = LCQuery(className: "Trip")
            query.whereKey("driverKey", .equalTo((LCUser.current?.objectId)!))
            query.find { (result) in
                if result.isSuccess {
                    if let trip = result.objects?.first as? Trip {
                        let pickupCoordinateArray = trip.get("pickupCoordinate")?.rawValue as! [Double]
                        let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0], longitude: pickupCoordinateArray[1])
                        let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                        let destinationCoordinateArray = trip.get("destinationCoordinate")?.rawValue as! [Double]
                        let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0], longitude: destinationCoordinateArray[1])
                        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                        
                        switch wayTo {
                        case .passenger:
                            self.dropPinFor(placemarks: [pickupPlacemark: .passenger, destinationPlacemark: .destination])
                            self.searchMapKitForResultsWithPolyline(forMapLocation: MKMapItem(placemark: pickupPlacemark))
                            trip.step = "Accepted"
                            trip.save({ (result) in
                                if result.isSuccess {
                                    self.actionBtn.animateButton(shouldLoad: false, withMessage: "Arrive to Pickup Point")
                                } else {
                                    let banner = NotificationBanner(title: "Error!", subtitle: result.error.debugDescription, style: .danger)
                                    banner.show()
                                    print(result.error.debugDescription)
                                }
                            })
                        case .destination:
                            self.searchMapKitForResultsWithPolyline(forMapLocation: MKMapItem(placemark: destinationPlacemark))
                        case .driver:
                            break
                        }
                    }
                } else {
                    let banner = NotificationBanner(title: "Error!", subtitle: result.error.debugDescription, style: .danger)
                    banner.show()
                    print(result.error.debugDescription)
                }
            }
        } else {
            let query = LCQuery(className: "Trip")
            query.whereKey("passengerKey", .equalTo((LCUser.current?.objectId)!))
            query.find({ (result) in
                if result.isSuccess {
                    if let trip = result.objects?.first as? Trip {
                        switch wayTo {
                        case .driver:
                            let query = LCQuery(className: "_User")
                            query.get(trip.driverKey!, completion: { (result) in
                                if result.isSuccess {
                                    if let driver = result.object as? User {
                                        self.mapView.removeAnnotations(self.mapView.annotations)
                                        self.mapView.removeOverlays(self.mapView.overlays)
                                        let driverCoordinateArray = driver.get("coordinate")?.rawValue as! [Double]
                                        let driverCoordinate = CLLocationCoordinate2D(latitude: driverCoordinateArray[0], longitude: driverCoordinateArray[1])
                                        let driverPlacemark = MKPlacemark(coordinate: driverCoordinate)
                                        self.dropPinFor(placemarks: [driverPlacemark: .driver])
                                        self.searchMapKitForResultsWithPolyline(forMapLocation: MKMapItem(placemark: driverPlacemark))
                                    }
                                } else {
                                    let banner = NotificationBanner(title: "Error!", subtitle: result.error.debugDescription, style: .danger)
                                    banner.show()
                                    print(result.error.debugDescription)
                                }
                            })
                        case .destination:
                            let query = LCQuery(className: "Trip")
                            query.whereKey("passengerKey", .equalTo((LCUser.current?.objectId)!))
                            query.find { (result) in
                                if result.isSuccess {
                                    if let trip = result.objects?.first as? Trip {
                                        self.mapView.removeAnnotations(self.mapView.annotations)
                                        self.mapView.removeOverlays(self.mapView.overlays)
                                        let destinationCoordinateArray = trip.get("destinationCoordinate")?.rawValue as! [Double]
                                        let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0], longitude: destinationCoordinateArray[1])
                                        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                                        self.dropPinFor(placemarks: [destinationPlacemark: .destination])
                                        self.searchMapKitForResultsWithPolyline(forMapLocation: MKMapItem(placemark: destinationPlacemark))
                                    }
                                } else {
                                    let banner = NotificationBanner(title: "Error!", subtitle: result.error.debugDescription, style: .danger)
                                    banner.show()
                                    print(result.error.debugDescription)
                                }
                            }
                        case .passenger:
                            break
                        }
                        
                    }
                } else {
                    let banner = NotificationBanner(title: "Error!", subtitle: result.error.debugDescription, style: .danger)
                    banner.show()
                    print(result.error.debugDescription)
                }
            })
        }
    }
    
    func checkTripStep() {
        if UserDefaults.standard.value(forKey: "isOnTrip") as? Bool == true {
            DataService.instance.checkTripStep { (isAccepted, driverKey) in
                if isAccepted {
                    self.actionBtn.isUserInteractionEnabled = false
                    if let tripStep = UserDefaults.standard.value(forKey: "tripStep") as? TripStep {
                        switch tripStep {
                        case .accepted:
                            self.acitonBtnTextAnimating(withMessage: "Driver is Coming")
                            self.showWayTo(wayTo: .driver)
                        case .driverArrived:
                            self.acitonBtnTextAnimating(withMessage: "Driver is Waiting")
                            self.showWayTo(wayTo: .driver)
                        case .inTravel:
                            self.acitonBtnTextAnimating(withMessage: "In Traveling")
                            self.showWayTo(wayTo: .destination)
                        case .end:
                            UpdateService.instance.finishTrip()
                            self.actionBtn.animateButton(shouldLoad: false, withMessage: "Travel Completed")
                            self.queue_Background.asyncAfter(deadline: .now() + 1.0, execute: {
                                self.actionBtn.animateButton(shouldLoad: false, withMessage: "Request Ride")
                                self.actionBtn.isUserInteractionEnabled = true
                            })
                        }
                    }
                }
            }
        }
    }
    
    func acitonBtnTextAnimating(withMessage message: String) {
        for i in 1...4 {
            var x = ""
            let b = "."
            if i >= 2 {
                for _ in 2...i {
                    x += b
                }
            }
            queue_Background.asyncAfter(deadline: .now() + 0.2) {
                self.actionBtn.animateButton(shouldLoad: false, withMessage: message + x)
            }
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
        UpdateService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
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
        
        search = MKLocalSearch(request: request)
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
    
    func dropPinFor(placemarks: Dictionary<MKPlacemark, AnnotationType>) {
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
                    self.centerBtn.isHidden = true
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
        let text = destinationTextField.text! + string
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if self.destinationTextField.text! == "" {
                self.matchingLocations = []
                self.tableView.reloadData()
            } else {
                if self.destinationTextField.text! == text {
                    self.performSearch(searchWord: (self.destinationTextField.text!))
                }
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
            if let user = LCUser.current {
                user.set("tripCoordinate", value: nil)
                user.save({ (result) in
                    if result.isFailure {
                        let banner = NotificationBanner(title: "Error!", subtitle: result.error.debugDescription, style: .danger)
                        banner.show()
                        print(result.error.debugDescription)
                    }
                })
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
            if annotation.isKind(of: PassengerAnnotation.self) {
                mapView.removeAnnotation(annotation)
            } else if annotation.isKind(of: MKPointAnnotation.self) {
                mapView.removeAnnotation(annotation)
            }
            
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
        } else {
            if UserDefaults.standard.value(forKey: "isDriver") as? Bool == true {
                view.endEditing(true)
                let banner = NotificationBanner(title: "You're a Driver.", subtitle: "Driver can't request for ride.", style: .warning)
                banner.show()
                
                let passengerCoordinate = mapView.userLocation.coordinate
                let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate, withKey: (LCUser.current?.objectId?.stringValue)!)
                mapView.addAnnotation(passengerAnnotation)
                destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
                let selectedLocation = matchingLocations[indexPath.row]
                dropPinFor(placemarks: [selectedLocation.placemark: .destination])
                searchMapKitForResultsWithPolyline(forMapLocation: selectedLocation)
                destinationTextField.endEditing(true)
                animateTableView(shouldShow: false)
                return
            } else {
                let passengerCoordinate = mapView.userLocation.coordinate
                let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate, withKey: (LCUser.current?.objectId?.stringValue)!)
                mapView.addAnnotation(passengerAnnotation)
                destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
                let selectedLocation = matchingLocations[indexPath.row]
                
                DispatchQueue.main.async {
                    self.spinner = JHSpinnerView.showOnView(self.view, spinnerColor: UIColor.red, overlay: .roundedSquare, overlayColor: UIColor.white.withAlphaComponent(0.6))
                    self.spinner.tag = 1006
                    self.view.addSubview(self.spinner)
                }
                queue_Background.async {
                    if let passenger = LCUser.current {
                        passenger.set("tripCoordinate", value: [selectedLocation.placemark.coordinate.latitude, selectedLocation.placemark.coordinate.longitude])
                        passenger.set("isOnTrip", value: true)
                        passenger.save({ (result) in
                            if result.isSuccess {
                                UserDefaults.standard.set([selectedLocation.placemark.coordinate.latitude, selectedLocation.placemark.coordinate.longitude], forKey: "tripCoordinate")
                                UserDefaults.standard.set(true, forKey: "isOnTrip")
                                self.dropPinFor(placemarks: [selectedLocation.placemark: .destination])
                                self.searchMapKitForResultsWithPolyline(forMapLocation: selectedLocation)
                                self.destinationTextField.endEditing(true)
                                self.animateTableView(shouldShow: false)
                            } else {
                                let banner = NotificationBanner(title: "Error!", subtitle: result.error.debugDescription, style: .danger)
                                banner.show()
                                print(result.error.debugDescription)
                            }
                        })
                    }
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
