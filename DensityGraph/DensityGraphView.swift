//  Copyright © 2019 James Horan. All rights reserved.

import UIKit

final class DensityGraphView: UIView {

    enum Constant {
        static let squareAnimationDuration: CFTimeInterval = 0.4
    }

    // MARK: - Properties

    /// Dictionary of CAShapeLayer's with `Key: DataPoint`.
    private(set) var squares: [(DataPointType, CAShapeLayer)] = []

    /// The variable height constraint of the view. A variable graph height
    /// allows the graph to scale to any unknown number of rows.
    private var heightConstraint: NSLayoutConstraint?

    /// Grid information.
    private var grid: GridType? {
        didSet {
            // Assuming the width needs to stay fixed per app use, a variable
            // height can be calculated for the graph where c is the number
            // of columns, r is the number of rows, w is the fixed available
            // width; the height to scale can be calculated with `h = (w/c)*r`.
            // NOTE: If landscape device orientation needs to be supported,
            // this approach will need to be reviewed.
            squareSize = bounds.size.width / CGFloat(grid?.columns ?? 0)
            // Check that `heightConstraint` is already set and active
            guard let constraint = heightConstraint, constraint.isActive else {
                heightConstraint = heightAnchor.constraint(
                    equalToConstant: squareSize * CGFloat(grid?.rows ?? 0))
                heightConstraint?.isActive = true
                return
            }
            constraint.constant = squareSize * CGFloat(grid?.rows ?? 0)
            layoutIfNeeded()
        }
    }

    /// Holds the drawable square size.
    private var squareSize: CGFloat = 0.0

    /// Tracks the rendered index.
    private(set) var renderedIndex: UInt = 0

    /// Largest multiset count; largest number of equal values.
    private(set) var largestMultiple: UInt = 0

    /// Will setup a graph with the given `Grid` and accumulated data points.
    func setup(grid: GridType, with data: CountedDataPoints) {
        self.grid = grid
        data.forEach {
            let rectangleLayer = makeRectangleLayer(for: $0.key)
            layer.addSublayer(rectangleLayer)
            squares.append(($0.key, rectangleLayer))
        }
        // Find the largest multiple
        largestMultiple = data.max { $0.value < $1.value }?.value ?? 0
    }

    /// Updates the graph with a data set of a certain index.
    func updateGraph(with countedData: CountedDataPoints, for index: UInt) {
        renderedIndex = index
        func normalisedOpacity(for value: UInt) -> Float {
            let upper: Float = Float(largestMultiple)
            let lower: Float = 0.0
            return max(0.0, min(1.0, (Float(value) - lower) / (upper - lower)))
        }
        CATransaction.begin()
        CATransaction.setAnimationDuration(Constant.squareAnimationDuration)
        squares.forEach {
            guard let dataPointCount = countedData[$0.0] else {
                $0.1.opacity = 0.0
                return
            }
            $0.1.opacity = normalisedOpacity(for: dataPointCount)
        }
        CATransaction.commit()
    }

    private func makeRectangleLayer(for dataPoint: DataPointType) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let x: CGFloat = CGFloat(dataPoint.x) * squareSize
        let y: CGFloat = CGFloat(dataPoint.y) * squareSize
        layer.path = UIBezierPath(
            roundedRect: CGRect(x: x, y: y, width: squareSize, height: squareSize),
            cornerRadius: 0).cgPath
        layer.fillColor = UIColor.green.cgColor
        layer.isOpaque = true
        layer.opacity = 0.0
        return layer
    }

    /// Resets the graph view state.
    func reset() {
        squares.forEach { $0.1.removeFromSuperlayer() }
        squares = []
        largestMultiple = 0
        renderedIndex = 0
    }
}
