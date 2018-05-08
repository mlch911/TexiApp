//
//  PickupVC.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/27.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import UIKit
import MapKit
import JHSpinner
import LeanCloud
import NotificationBannerSwift

class PickupVC: UIViewController {
    
    @IBOutlet weak var pickupMapView: RoundMapView!
    @IBOutlet weak var acceptBtn: RoundedShadowButton!
    
    @IBAction func acceptTripBtnPressed(_ sender: Any) {
        acceptBtn.animateButton(shouldLoad: true, withMessage: nil)
        UpdateService.instance.acceptTrip(withPassengerKey: passengerKey, withDriverKey: driverKey) { (finished) in
            if finished {
                self.acceptBtn.animateButton(shouldLoad: false, withMessage: "Successful Accepted")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: {
                    self.performSegue(withIdentifier: "acceptTrip", sender: self)
                })
            } else {
                let banner = NotificationBanner(title: "Error", subtitle: "请求失败，请重试！", style: .danger)
                banner.show()
                self.acceptBtn.animateButton(shouldLoad: false, withMessage: "Accept Trip")
            }
        }
    }
    
    var route1: MKRoute!
    var route2: MKRoute!
    var selectedLocationPlacemark: MKPlacemark? = nil
    var passengerCoordinate: CLLocationCoordinate2D!
    var destinationCoordinate: CLLocationCoordinate2D!
    var currentCoordinate: CLLocationCoordinate2D!
    var passengerKey: String!
    var driverKey: String!
    var tripKey: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let queue_UserInteractive = DispatchQueue.init(label: "tech.mluoc.queueUserInteractive", qos: .userInteractive, attributes: .concurrent)
//        let queue_UserInitiated = DispatchQueue.init(label: "tech.mluoc.queueUserInitiated", qos: .userInitiated, attributes: .concurrent)
//        let queue_Utility = DispatchQueue.init(label: "tech.mluoc.queueUtility", qos: .utility, attributes: .concurrent)
        let queue_Background = DispatchQueue.init(label: "tech.mluoc.queueBackground", qos: .background, attributes: .concurrent)
        
        pickupMapView.delegate = self
        let passengerPlacemark = MKPlacemark(coordinate: passengerCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        let currentPlacemark = MKPlacemark(coordinate: currentCoordinate)
        dropPinFor(placemarks: [passengerPlacemark: .passenger, destinationPlacemark: .destination, currentPlacemark: .driver])
        let passengerMapItem = MKMapItem(placemark: passengerPlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        let currentMapItem = MKMapItem(placemark: currentPlacemark)
        
        searchMapKitForResultsWithPolyline(forSourceLocation: passengerMapItem, forDestinationLocation: destinationMapItem) { (route) in
            self.route1 = route
            self.pickupMapView.add(self.route1.polyline)
        }
//        searchMapKitForResultsWithPolyline(forSourceLocation: currentMapItem, forDestinationLocation: passengerMapItem) { (route) in
//            self.route2 = route
//            self.pickupMapView.add(self.route2.polyline)
//        }
        queue_Background.async {
            var query = LCQuery(className: "Trip")
            query.whereKey("objectID", .equalTo(self.tripKey))
            query.find({ (result) in
                if result.isSuccess {
                    if let trip = result.objects?.first as? Trip {
                        if trip.isTripAccepted == true {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }
                } else {
                    let banner = NotificationBanner(title: "Error!", subtitle: result.error.debugDescription, style: .danger)
                    banner.show()
                    print(result.error.debugDescription)
                }
            })
            query = LCQuery(className: "_User")
            query.whereKey("objectID", .equalTo(self.driverKey))
            query.find({ (result) in
                if result.isSuccess {
                    if let driver = result.objects?.first as? User {
                        guard !(driver.isOnTrip.boolValue!) && driver.isPickupModeEnable.boolValue! else {
                            self.dismiss(animated: true, completion: nil)
                            return
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
    
    func initData(passengerCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D, currentCoordinate: CLLocationCoordinate2D, passengerKey: String, driverKey: String, tripKey: String) {
        self.passengerCoordinate = passengerCoordinate
        self.destinationCoordinate = destinationCoordinate
        self.currentCoordinate = currentCoordinate
        self.passengerKey = passengerKey
        self.driverKey = driverKey
        self.tripKey = tripKey
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "acceptTrip" {
            if let dest = segue.destination as? HomeVC {
                dest.actionBtn.animateButton(shouldLoad: true, withMessage: nil)
                dest.showWayTo(wayTo: .passenger)
//                dest.spinner = JHSpinnerView.showOnView(dest.view, spinnerColor: UIColor.red, overlay: .roundedSquare, overlayColor: UIColor.white.withAlphaComponent(0.6))
            }
        }
    }
}

extension PickupVC: MKMapViewDelegate {
    
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
    
    func centerMapOnTrip() {
        zoom(toFitAnntationsFromMapView: pickupMapView)
    }
    
    func dropPinFor(placemarks: Dictionary<MKPlacemark, AnnotationType>) {
        for annotation in pickupMapView.annotations {
            pickupMapView.removeAnnotation(annotation)
        }
        for placemark in placemarks {
            selectedLocationPlacemark = placemark.key
            
            switch placemark.value {
            case .destination:
                let annotation = MKPointAnnotation()
                annotation.coordinate = placemark.key.coordinate
                pickupMapView.addAnnotation(annotation)
            case .driver:
                let annotation = DriverAnnotation(coordinate: placemark.key.coordinate, withKey: passengerKey)
                pickupMapView.addAnnotation(annotation)
            case .passenger:
                let annotation = PassengerAnnotation(coordinate: placemark.key.coordinate, withKey: driverKey)
                pickupMapView.addAnnotation(annotation)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRenderer = MKPolylineRenderer(overlay: overlay)
        lineRenderer.strokeColor = UIColor(red: 216/255, green: 71/255, blue: 30/255, alpha: 0.75)
        lineRenderer.lineWidth = 1
        
        zoom(toFitAnntationsFromMapView: self.pickupMapView)
        
        return lineRenderer
    }
    
    func searchMapKitForResultsWithPolyline(forSourceLocation sourceLocation: MKMapItem, forDestinationLocation destinationLocation: MKMapItem, handler: @escaping(_ route: MKRoute) -> Void) {
        let request = MKDirectionsRequest()
        request.source = sourceLocation
        request.destination = destinationLocation
        request.transportType = MKDirectionsTransportType.automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            guard let response = response else {
                print(error.debugDescription)
                return
            }
            handler(response.routes[0])
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

