//
//  MapItemTests.swift
//  TokoTokoTests
//
//  Created by bokuyamada on 2025/06/17.
//

import XCTest
import CoreLocation
@testable import TekuToko

final class MapItemTests: XCTestCase {
    
    func testMapItemInitializationWithDefaultValues() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let title = "Test Location"
        
        // When
        let mapItem = MapItem(coordinate: coordinate, title: title)
        
        // Then
        XCTAssertEqual(mapItem.coordinate.latitude, coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(mapItem.coordinate.longitude, coordinate.longitude, accuracy: 0.0001)
        XCTAssertEqual(mapItem.title, title)
        XCTAssertEqual(mapItem.imageName, "mappin.circle.fill")
        XCTAssertNotNil(mapItem.id)
    }
    
    func testMapItemInitializationWithCustomValues() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let title = "Custom Location"
        let imageName = "custom.icon"
        let customId = UUID()
        
        // When
        let mapItem = MapItem(
            coordinate: coordinate,
            title: title,
            imageName: imageName,
            id: customId
        )
        
        // Then
        XCTAssertEqual(mapItem.coordinate.latitude, coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(mapItem.coordinate.longitude, coordinate.longitude, accuracy: 0.0001)
        XCTAssertEqual(mapItem.title, title)
        XCTAssertEqual(mapItem.imageName, imageName)
        XCTAssertEqual(mapItem.id, customId)
    }
    
    func testMapItemIdentifiableProtocol() {
        // Given
        let coordinate1 = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let coordinate2 = CLLocationCoordinate2D(latitude: 35.6813, longitude: 139.7672)
        
        // When
        let mapItem1 = MapItem(coordinate: coordinate1, title: "Location 1")
        let mapItem2 = MapItem(coordinate: coordinate2, title: "Location 2")
        
        // Then
        XCTAssertNotEqual(mapItem1.id, mapItem2.id)
    }
    
    func testMapItemWithSameIdAreEqual() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let sharedId = UUID()
        
        // When
        let mapItem1 = MapItem(coordinate: coordinate, title: "Location 1", id: sharedId)
        let mapItem2 = MapItem(coordinate: coordinate, title: "Location 2", id: sharedId)
        
        // Then
        XCTAssertEqual(mapItem1.id, mapItem2.id)
    }
    
    func testMapItemWithZeroCoordinate() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let title = "Zero Location"
        
        // When
        let mapItem = MapItem(coordinate: coordinate, title: title)
        
        // Then
        XCTAssertEqual(mapItem.coordinate.latitude, 0.0)
        XCTAssertEqual(mapItem.coordinate.longitude, 0.0)
        XCTAssertEqual(mapItem.title, title)
    }
    
    func testMapItemWithEmptyTitle() {
        // Given
        let coordinate = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
        let title = ""
        
        // When
        let mapItem = MapItem(coordinate: coordinate, title: title)
        
        // Then
        XCTAssertEqual(mapItem.title, "")
        XCTAssertEqual(mapItem.coordinate.latitude, coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(mapItem.coordinate.longitude, coordinate.longitude, accuracy: 0.0001)
    }
}
