//
//  WalkImageGeneratorPerformanceTests.swift
//  TokoTokoTests
//
//  Created by Claude Code on 2025/08/01.
//

import CoreLocation
import XCTest
@testable import TokoToko

final class WalkImageGeneratorPerformanceTests: XCTestCase {
    
    var imageGenerator: WalkImageGenerator!
    var mockWalk: Walk!
    
    override func setUp() {
        super.setUp()
        imageGenerator = WalkImageGenerator.shared
        mockWalk = createMockWalk()
    }
    
    override func tearDown() {
        imageGenerator = nil
        mockWalk = nil
        super.tearDown()
    }
    
    // MARK: - Test Helper Methods
    
    private func createMockWalk() -> Walk {
        let locations = [
            CLLocation(latitude: 35.6812, longitude: 139.7671), // 東京駅
            CLLocation(latitude: 35.6815, longitude: 139.7675), // 少し移動
            CLLocation(latitude: 35.6818, longitude: 139.7680), // さらに移動
            CLLocation(latitude: 35.6820, longitude: 139.7685), // 最終地点
        ]
        
        return Walk(
            title: "パフォーマンステスト用散歩",
            description: "画像生成テスト用のモックデータ",
            id: UUID(),
            startTime: Date().addingTimeInterval(-1800), // 30分前開始
            endTime: Date(),
            totalDistance: 1500, // 1.5km
            totalSteps: 2000,
            status: .completed,
            locations: locations
        )
    }
    
    // MARK: - Performance Tests
    
    func testImageGenerationPerformance() async throws {
        // 画像生成時間の測定（目標: 3秒以内）
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let generatedImage = try await imageGenerator.generateWalkImage(from: mockWalk)
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = endTime - startTime
            
            // アサーション
            XCTAssertNotNil(generatedImage, "画像が生成されていない")
            XCTAssertLessThan(executionTime, 3.0, "画像生成時間が3秒を超過: \(executionTime)秒")
            
            // 詳細ログ
            print("✅ 画像生成時間: \(String(format: "%.2f", executionTime))秒")
            print("   画像サイズ: \(generatedImage.size)")
            
        } catch {
            XCTFail("画像生成に失敗: \(error)")
        }
    }
    
    func testImageGenerationMemoryUsage() async throws {
        // メモリ使用量の測定
        let initialMemory = getMemoryUsage()
        
        do {
            let generatedImage = try await imageGenerator.generateWalkImage(from: mockWalk)
            
            // GCを促進してより正確な測定を行う
            await Task.yield()
            
            let finalMemory = getMemoryUsage()
            let memoryIncrease = finalMemory - initialMemory
            
            // メモリ使用量を MB に変換
            let memoryIncreaseMB = Double(memoryIncrease) / (1024 * 1024)
            
            // アサーション（高解像度画像生成では500MB以下が現実的）
            // 1080x1920ピクセル画像の処理には大量のメモリが必要
            XCTAssertLessThan(memoryIncreaseMB, 500.0, "メモリ使用量が過大: \(memoryIncreaseMB)MB")
            XCTAssertNotNil(generatedImage, "画像が生成されていない")
            
            // 画像サイズが正しいことを確認
            XCTAssertEqual(generatedImage.size.width, 1080, "画像幅が期待値と異なる")
            XCTAssertEqual(generatedImage.size.height, 1920, "画像高さが期待値と異なる")
            
            // 詳細ログ
            print("📊 メモリ使用量:")
            print("   初期: \(String(format: "%.1f", Double(initialMemory) / (1024 * 1024)))MB")
            print("   最終: \(String(format: "%.1f", Double(finalMemory) / (1024 * 1024)))MB")
            print("   増加: \(String(format: "%.1f", memoryIncreaseMB))MB")
            print("   画像サイズ: \(generatedImage.size)")
            
        } catch {
            XCTFail("画像生成に失敗: \(error)")
        }
    }
    
    func testImageGenerationWithLargeRoute() async throws {
        // 大きなルートでのパフォーマンステスト
        let largeRouteWalk = createLargeRouteWalk()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let generatedImage = try await imageGenerator.generateWalkImage(from: largeRouteWalk)
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let executionTime = endTime - startTime
            
            // より緩い制限（大きなルートでは5秒以内）
            XCTAssertLessThan(executionTime, 5.0, "大きなルートでの画像生成時間が5秒を超過: \(executionTime)秒")
            XCTAssertNotNil(generatedImage, "画像が生成されていない")
            
            print("✅ 大きなルート画像生成時間: \(String(format: "%.2f", executionTime))秒")
            print("   ルートポイント数: \(largeRouteWalk.locations.count)")
            
        } catch {
            XCTFail("大きなルートでの画像生成に失敗: \(error)")
        }
    }
    
    func testImageGenerationStress() async throws {
        // ストレステスト（複数回連続実行）
        let iterations = 5
        var totalTime: Double = 0
        var allImagesGenerated = true
        
        for i in 1...iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let generatedImage = try await imageGenerator.generateWalkImage(from: mockWalk)
                let endTime = CFAbsoluteTimeGetCurrent()
                let executionTime = endTime - startTime
                
                totalTime += executionTime
                
                if generatedImage == nil {
                    allImagesGenerated = false
                }
                
                print("   実行 \(i): \(String(format: "%.2f", executionTime))秒")
                
            } catch {
                XCTFail("ストレステスト \(i)回目で失敗: \(error)")
                return
            }
        }
        
        let averageTime = totalTime / Double(iterations)
        
        XCTAssertTrue(allImagesGenerated, "一部の画像生成に失敗")
        XCTAssertLessThan(averageTime, 3.0, "平均画像生成時間が3秒を超過: \(averageTime)秒")
        
        print("🔥 ストレステスト結果:")
        print("   実行回数: \(iterations)")
        print("   総時間: \(String(format: "%.2f", totalTime))秒")
        print("   平均時間: \(String(format: "%.2f", averageTime))秒")
    }
    
    // MARK: - Helper Methods
    
    private func createLargeRouteWalk() -> Walk {
        // 50ポイントの大きなルートを作成
        var locations: [CLLocation] = []
        let baseLatitude = 35.6812
        let baseLongitude = 139.7671
        
        for i in 0..<50 {
            let deltaLat = Double(i) * 0.0001 // 約11mずつ移動
            let deltaLon = Double(i) * 0.0001
            let location = CLLocation(
                latitude: baseLatitude + deltaLat,
                longitude: baseLongitude + deltaLon
            )
            locations.append(location)
        }
        
        return Walk(
            title: "大きなルートテスト",
            description: "パフォーマンステスト用の大きなルート",
            id: UUID(),
            startTime: Date().addingTimeInterval(-3600), // 1時間前開始
            endTime: Date(),
            totalDistance: 5500, // 5.5km
            totalSteps: 7500,
            status: .completed,
            locations: locations
        )
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return 0
        }
        
        return info.resident_size
    }
}