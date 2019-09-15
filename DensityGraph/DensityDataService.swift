//  Copyright © 2019 James Horan. All rights reserved.

import Foundation

import DensityDataAPI

// Exposing `Grid` and `DataPoint` internally via these typealiase's to avoid
// many imports of `DensityDataAPI`.
typealias GridType = Grid
typealias DataPointType = DataPoint

// This protocol acts as a DensityDataAPI facade for testing
protocol DensityDataServiceProtocol {
    func getGrid() -> GridType
    func getData(for index: UInt) throws -> [DataPointType]?
}

final class DensityDataService: DensityDataServiceProtocol {

    private let api: DensityDataAPI = DensityDataAPI()

    func getGrid() -> GridType {
        return api.getGrid()
    }

    func getData(for index: UInt) throws -> [DataPointType]? {
        return try api.getData(index: index)
    }
}
