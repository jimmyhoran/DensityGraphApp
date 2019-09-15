//  Copyright © 2019 James Horan. All rights reserved.

import XCTest

@testable import DensityGraph

class DensityGraphViewTests: XCTestCase {

    func testSetSquares() {
        // Arrange
        let graphView = DensityGraphView()
        let service = MockDensityDataService()
        let manager = DensityDataManager(service: service)

        // Act
        manager.fetchAndCacheData() // Need to cache the mocked data
        graphView.setup(grid: manager.grid, with: manager.cache.last!)

        // Assert
        XCTAssertEqual(graphView.squares.count, service.mockedData.expectedCountOfLastIndex)
    }

    func testLargestMultiple() {
        // Arrange
        let graphView = DensityGraphView()
        let service = MockDensityDataService()
        let manager = DensityDataManager(service: service)

        // Act
        manager.fetchAndCacheData() // Need to cache the mocked data
        graphView.setup(grid: manager.grid, with: manager.cache.last!)

        // Assert
        XCTAssertEqual(graphView.largestMultiple, service.mockedData.expectedLargestMultiple)
    }

    /// Test the scenario where the largest multi is the same for more than 1 DataPoint.
    func testSharedLargestMultiple() {
        // Arrange
        let mockedServiceData = MockServiceData(
            // This data is arranged so that the last index's accumlative data
            // set has multiple DataPoints with the same largest multiple value.
            data: [
                [DataPointType(x: 0, y: 0), DataPointType(x: 1, y: 1)],
                [DataPointType(x: 0, y: 0), DataPointType(x: 1, y: 2)],
                [DataPointType(x: 0, y: 0), DataPointType(x: 1, y: 1), DataPointType(x: 1, y: 1)]
            ],
            expectedLargestMultiple: 3, // Both (x: 0, y: 0) and (x: 1, y: 1) have a multiple count of 3
            expectedCountOfLastIndex: 3,
            expectedCacheCount: 3)
        let manager = DensityDataManager(service: MockDensityDataService(mockedData: mockedServiceData))
        let graphView = DensityGraphView()

        // Act
        manager.fetchAndCacheData()
        graphView.setup(grid: manager.grid, with: manager.cache.last!)

        // Assert
        XCTAssertEqual(graphView.largestMultiple, mockedServiceData.expectedLargestMultiple)
    }

    func testReset() {
        // Arrange
        let graphView = DensityGraphView()
        let service = MockDensityDataService()
        let manager = DensityDataManager(service: service)

        // Act
        manager.fetchAndCacheData() // Need to cache the mocked data
        graphView.setup(grid: manager.grid, with: manager.cache.last!)
        graphView.updateGraph(with: manager.cache[1], for: 1)
        graphView.reset()

        // Assert
        XCTAssertEqual(graphView.renderedIndex, 0)
        XCTAssertEqual(graphView.largestMultiple, 0)
        XCTAssertEqual(graphView.squares.count, 0)
    }
}
