//  Copyright © 2019 James Horan. All rights reserved.

@testable import DensityGraph

// Need to extend Grid with a accessible initialiser.
// Grid does not have a public initialiser and one is needed for testing.
extension GridType {
    internal init(columns: UInt, rows: UInt, dataSize: UInt) {
        self.columns = columns
        self.rows = rows
        self.dataSize = dataSize
    }
}

// Need to extend DataPoint with a accessible initialiser.
// Grid does not have a public initialiser and one is needed for testing.
extension DataPointType {
    internal init(x: UInt, y: UInt) {
        self.x = x
        self.y = y
    }
}

// NOTE: Extending these types with an initialiser throws an error as of
// Swift 5. For more info see SE-0189.
// https://github.com/apple/swift-evolution/blob/master/proposals/0189-restrict-cross-module-struct-initializers.md

enum MockError: Error {
    case generic
}

struct MockServiceData {

    // Default data set
    static let defaultData: [[DataPointType]] = [
        [DataPointType(x: 0, y: 0)],
        [DataPointType(x: 1, y: 1), DataPointType(x: 1, y: 2)],
        [DataPointType(x: 0, y: 0)]
    ]

    // Mocked data set.
    let data: [[DataPointType]]

    /// Expected largest value.
    let expectedLargestMultiple: UInt

    /// The count of last index's accumulated set of unique DataPoint's.
    let expectedCountOfLastIndex: Int

    /// Number of cached indices.
    let expectedCacheCount: Int

    init(
        data: [[DataPointType]] = defaultData,
        expectedLargestMultiple: UInt = 2,
        expectedCountOfLastIndex: Int = 3,
        expectedCacheCount: Int = 3) {
        self.data = data
        self.expectedLargestMultiple = expectedLargestMultiple
        self.expectedCountOfLastIndex = expectedCountOfLastIndex
        self.expectedCacheCount = expectedCacheCount
    }
}

final class MockDensityDataService: DensityDataServiceProtocol {

    // Mock data type.
    let mockedData: MockServiceData

    /// The number of times the service should simulate a thrown error.
    private let fails: UInt

    // Counts the already thrown errors.
    private var failCount: UInt = 0

    init(fails: UInt = 0, mockedData: MockServiceData = MockServiceData()) {
        self.fails = fails
        self.mockedData = mockedData
    }

    func getGrid() -> GridType {
        return GridType(
            columns: 3,
            rows: 3,
            dataSize: UInt(mockedData.data.count))
    }

    func getData(for index: UInt) throws -> [DataPointType]? {
        if failCount < fails {
            failCount += 1
            throw MockError.generic
        }
        return mockedData.data[Int(index)]
    }
}
