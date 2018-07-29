//
//  MapViewWithZoom.swift
//  SolarCalculator
//
//  Created by apple on 28/07/18.
//  Copyright © 2018 Aakash Srivastav. All rights reserved.
//

import MapKit

class MapViewWithZoom: MKMapView {
    
    var zoomLevel: Int {
        get {
            return Int(log2(360 * (Double(frame.size.width/256) / region.span.longitudeDelta)) + 1);
        }
        set (newZoomLevel) {
            setCenterCoordinate(coordinate: centerCoordinate, zoomLevel: newZoomLevel, animated: false)
        }
    }
    
    func setCenterCoordinate(coordinate: CLLocationCoordinate2D, zoomLevel: Int, animated: Bool){
        let span = MKCoordinateSpan(latitudeDelta: 0, longitudeDelta: 360 / pow(2, Double(zoomLevel)) * Double(self.frame.size.width) / 256)
        setRegion(MKCoordinateRegion(center: coordinate, span: span), animated: animated)
    }
}
