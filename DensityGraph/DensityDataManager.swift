//  Copyright © 2019 James Horan. All rights reserved.

import Foundation

typealias CountedDataPoints = [DataPointType: UInt]
typealias CachedData = [CountedDataPoints]

protocol DensityDataManagerDelegate: AnyObject {
    func didUpdateCache()
    func didCompleteCache()
}

final class DensityDataManager {

    enum Constant {
        /// The maximum number of request attempts.
        ///
        /// Allowing for a maximum of 4 `getData(index:)` attempts would enforce mean the allowed
        // retries would be <= 3 times, after counting the first attempt.
        static let maxAttempts: UInt = 4
    }

    enum Result: Equatable {
        case success([DataPointType]?)
        case failure()
    }

    // MARK: - Properties

    weak var delegate: DensityDataManagerDelegate?

    /// Grid details.
    let grid: GridType

    /// Service API.
    private let service: DensityDataServiceProtocol

    // MARK: State

    /// Cached data.
    private(set) var cache: CachedData = []

    /// Log of failed indices.
    private(set) var failedIndices: [UInt] = []

    // MARK: Variables

    /// The current data fetching progress as a percent value.
    var progress: UInt {
        let count = Double(cache.count + failedIndices.count)
        return UInt(100 * max(0, min(1, count / Double(grid.dataSize))))
    }

    // MARK: - Init

    init(service: DensityDataServiceProtocol) {
        self.service = service

        // Set the grid information per instance
        self.grid = service.getGrid()
    }

    func fetchAndCacheData() {
        // Assuming `Grid.dataSize` is the number of data sets, the upper range
        // index would be `dataSize - 1`.
        let maxIndex = grid.dataSize - 1

        for index in 0...maxIndex {
            // Attempt to fetch index data mutliple times
            switch getData(for: index) {
            case let .success(data):

                // Early exit if there's no data
                guard let data = data, data.count > 0 else { break }

                // Find multiples in the received data set
                let newCountedData: CountedDataPoints = data.reduce(into: [:]) {
                    $0[$1, default: 0] += 1
                }

                // Add the accumulated DataPoint count dictionary to the cache
                cache.append({
                    var mutableDictionary = cache.last ?? [:]
                    newCountedData.forEach {
                        // Check if DataPoint already exists
                        guard let countValue = mutableDictionary[$0.key] else {
                            // If it doesn't exist.
                            mutableDictionary[$0.key] = $0.value
                            return
                        }
                        mutableDictionary[$0.key] = countValue + $0.value
                    }
                    return mutableDictionary
                }())
                didProcessIndex()
                break
            case .failure():
                // All attempts and retries failed
                logFailed(index: index)
                didProcessIndex()
                break
            }
        }
    }
}

// MARK: - Helpers

extension DensityDataManager {

    /// Attempts to execute `DensityDataAPI.getData(index:)` multiple times.
    func getData(for index: UInt, attempts: UInt = Constant.maxAttempts) -> Result {
        var attemptCount: UInt = 1
        while attemptCount <= attempts {
            do {
                let data = try service.getData(for: index)
                return .success(data)
            } catch {
                attemptCount += 1
                // Caught an error. Continue to the next iteration. The while
                // loops conditional statement will be evaulauted again to check
                // the number of attempts has not yet been exceeded.
                continue
            }
        }
        return .failure()
    }

    /// Adds a data set to the cache.
    private func addToCache(_ countedData: CountedDataPoints) {
        guard countedData.count > 0 else { return }
        cache.append(countedData)
    }

    /// Adds a failed index to the failed log.
    private func logFailed(index: UInt) {
        failedIndices.append(index)
    }

    /// Called when the data of each index of DataSize has been processed.
    /// This function gets called regardless of result. i.e. success or failure
    private func didProcessIndex() {
        // Check if all data has been either cached or logged as failed
        if grid.dataSize == (cache.count + failedIndices.count) {
            delegate?.didCompleteCache()
        } else {
            delegate?.didUpdateCache()
        }
    }
}
