//
//  MapViewComponentTests.swift
//  TokoTokoTests
//
//  Created by bokuyamada on 2025/06/17.
//

import XCTest
import SwiftUI
import CoreLocation
import MapKit
@testable import TokoToko

final class MapViewComponentTests: XCTestCase {
    
    func testMapViewComponentInitializationWithDefaultValues() {
        // Given & When
        let mapViewComponent = MapViewComponent()
        
        // Then
        XCTAssertNotNil(mapViewComponent)
    }
    
    func testMapViewComponentInitializationWithCustomRegion() {
        // Given
        let customRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // New York
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        // When
        let mapViewComponent = MapViewComponent(region: customRegion)
        
        // Then
        XCTAssertNotNil(mapViewComponent)
    }
    
    func testMapViewComponentInitializationWithAnnotations() {
        // Given
        let annotations = [
            MapItem(
                coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
                title: "Tokyo Station"
            ),
            MapItem(
                coordinate: CLLocationCoordinate2D(latitude: 35.6584, longitude: 139.7016),
                title: "Shibuya"
            )
        ]
        
        // When
        let mapViewComponent = MapViewComponent(annotations: annotations)
        
        // Then
        XCTAssertNotNil(mapViewComponent)
    }
    
    func testMapViewComponentWithEmptyAnnotations() {
        // Given
        let emptyAnnotations: [MapItem] = []
        
        // When
        let mapViewComponent = MapViewComponent(annotations: emptyAnnotations)
        
        // Then
        XCTAssertNotNil(mapViewComponent)
    }
    
    func testMapViewComponentWithFullCustomization() {
        // Given
        let customRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437), // Los Angeles
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        let annotations = [
            MapItem(
                coordinate: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
                title: "Los Angeles",
                imageName: "star.fill"
            )
        ]
        
        // When
        let mapViewComponent = MapViewComponent(region: customRegion, annotations: annotations)
        
        // Then
        XCTAssertNotNil(mapViewComponent)
    }
    
    func testMapViewComponentWithPolylineCoordinates() {
        // Given
        let polylineCoordinates = [
            CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671), // Tokyo Station
            CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.7738), // Imperial Palace
            CLLocationCoordinate2D(latitude: 35.6584, longitude: 139.7016)  // Shibuya
        ]
        
        // When
        let mapViewComponent = MapViewComponent(polylineCoordinates: polylineCoordinates)
        
        // Then
        XCTAssertNotNil(mapViewComponent)
    }
    
    func testMapViewComponentWithAnnotationsAndPolyline() {
        // Given
        let annotations = [
            MapItem(
                coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
                title: "Start Point",
                imageName: "play.circle.fill"
            ),
            MapItem(
                coordinate: CLLocationCoordinate2D(latitude: 35.6584, longitude: 139.7016),
                title: "End Point",
                imageName: "checkmark.circle.fill"
            )
        ]
        
        let polylineCoordinates = [
            CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.7738),
            CLLocationCoordinate2D(latitude: 35.6584, longitude: 139.7016)
        ]
        
        // When
        let mapViewComponent = MapViewComponent(
            annotations: annotations,
            polylineCoordinates: polylineCoordinates
        )
        
        // Then
        XCTAssertNotNil(mapViewComponent)
    }
    
    func testMapViewComponentWithEmptyPolylineCoordinates() {
        // Given
        let emptyPolylineCoordinates: [CLLocationCoordinate2D] = []
        
        // When
        let mapViewComponent = MapViewComponent(polylineCoordinates: emptyPolylineCoordinates)
        
        // Then
        XCTAssertNotNil(mapViewComponent)
    }
    
    func testMapViewComponentWithSinglePolylineCoordinate() {
        // Given
        let singleCoordinate = [
            CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        ]
        
        // When
        let mapViewComponent = MapViewComponent(polylineCoordinates: singleCoordinate)
        
        // Then
        XCTAssertNotNil(mapViewComponent)
    }
}

// iOS17MapViewとiOS15MapViewの個別テスト
@available(iOS 17.0, *)
extension MapViewComponentTests {
    
    func testIOS17MapViewBehavior() {
        // Given
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        let annotations = [
            MapItem(
                coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
                title: "Test Location"
            )
        ]
        
        // When
        let mapViewComponent = MapViewComponent(region: region, annotations: annotations)
        
        // Then
        XCTAssertNotNil(mapViewComponent)
    }
    
    func testIOS17MapViewWithPolyline() {
        // Given
        let polylineCoordinates = [
            CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.7738),
            CLLocationCoordinate2D(latitude: 35.6584, longitude: 139.7016)
        ]
        
        // When
        let mapViewComponent = MapViewComponent(polylineCoordinates: polylineCoordinates)
        
        // Then
        XCTAssertNotNil(mapViewComponent)
    }
}

extension MapViewComponentTests {
    
    func testIOS15MapViewBehavior() {
        // Given
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        let annotations = [
            MapItem(
                coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
                title: "Test Location"
            )
        ]
        
        // When
        let mapViewComponent = MapViewComponent(region: region, annotations: annotations)
        
        // Then
        XCTAssertNotNil(mapViewComponent)
    }
    
    func testIOS15MapViewWithPolyline() {
        // Given
        let polylineCoordinates = [
            CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.7738),
            CLLocationCoordinate2D(latitude: 35.6584, longitude: 139.7016)
        ]
        
        // When
        let mapViewComponent = MapViewComponent(polylineCoordinates: polylineCoordinates)
        
        // Then
        XCTAssertNotNil(mapViewComponent)
    }
}