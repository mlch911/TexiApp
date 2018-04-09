//
//  PickupVC.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/27.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import UIKit
import MapKit

enum annotationType {
    case driver
    case passenger
    case destination
}

class PickupVC: UIViewController {
    
    @IBOutlet weak var pickupMapView: RoundMapView!
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func acceptTripBtnPressed(_ sender: Any) {
        UpdateService.instance.acceptTrip(withPassengerKey: passengerKey, withDriverKey: driverKey)
        self.dismiss(animated: true) {
            let homeVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "HomeVC") as? HomeVC
            homeVC?.spinner.animate()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        UpdateService.instance.trips.child(passengerKey).observe(.value) { (snapshot) in
            if snapshot.exists() {
                if snapshot.childSnapshot(forPath: "tripIsAccepted").value as? Bool == true {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func initData(passengerCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D, currentCoordinate: CLLocationCoordinate2D, passengerKey: String, driverKey: String) {
        self.passengerCoordinate = passengerCoordinate
        self.destinationCoordinate = destinationCoordinate
        self.currentCoordinate = currentCoordinate
        self.passengerKey = passengerKey
        self.driverKey = driverKey
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
    
    func dropPinFor(placemarks: Dictionary<MKPlacemark, annotationType>) {
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

