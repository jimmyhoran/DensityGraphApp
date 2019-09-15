//  Copyright © 2019 James Horan. All rights reserved.

import XCTest

@testable import DensityGraph

final class DensityDataManagerTests: XCTestCase {

    /// Test data processing and caching logic.
    func testDataFetchingAndCaching() {
        // Arrange
        let mockedServiceData = MockServiceData(
            data: [
                [DataPointType(x: 0, y: 0), DataPointType(x: 1, y: 1)],
                [DataPointType(x: 1, y: 1), DataPointType(x: 1, y: 2)],
                [DataPointType(x: 0, y: 1), DataPointType(x: 1, y: 1)]
            ],
            expectedLargestMultiple: 3,
            expectedCountOfLastIndex: 4,
            expectedCacheCount: 3)
        let manager = DensityDataManager(service: MockDensityDataService(mockedData: mockedServiceData))

        // Act
        manager.fetchAndCacheData()

        // Assert
        XCTAssertEqual(manager.cache.count, mockedServiceData.expectedCacheCount)
        XCTAssertEqual(manager.cache[0].count, 2)
        XCTAssertEqual(manager.cache[1].count, 3)
        XCTAssertEqual(manager.cache[2].count, mockedServiceData.expectedCountOfLastIndex)
    }

    /// Test retry `getData(index:)` retry functionality.
    func testRetries() {
        // 0...3 failed attempts should NOT hard fail
        for f in 0...3 {
            let manager = DensityDataManager(service: MockDensityDataService(fails: UInt(f)))
            let result = manager.getData(for: 0, attempts: 4)
            XCTAssertNotEqual(result, DensityDataManager.Result.failure())
        }

        // 4 of more failures should hard fail
        for f in 4...5 {
            let manager = DensityDataManager(service: MockDensityDataService(fails: UInt(f)))
            let result = manager.getData(for: 0, attempts: 4)
            XCTAssertEqual(result, DensityDataManager.Result.failure())
        }
    }

    /// Test computed progress based on a completed and cached data set.
    func testProgress() {
        // Arrange
        let manager = DensityDataManager(service: MockDensityDataService())

        // Act
        manager.fetchAndCacheData()

        // Assert
        XCTAssertEqual(manager.progress, 100)
    }
}
