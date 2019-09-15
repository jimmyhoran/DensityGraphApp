//  Copyright © 2019 James Horan. All rights reserved.

import UIKit

final class ViewController: UIViewController {

    // MARK: - Properties

    private var dataManager: DensityDataManager?
    private var displayLink: CADisplayLink?

    // MARK: UI

    private var loadingView: LoadingView?
    private let graphView = DensityGraphView()
    private let slider = UISlider()
    private let failedIndicesLabel = UILabel()

    private let lowerIndexLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = .blue
        label.textColor = .white
        return label
    }()

    private let upperIndexLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = .blue
        label.textColor = .white
        return label
    }()

    private let currentIndexLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private let resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("Reset", for: .normal)
        button.addTarget(self, action: #selector(reset), for: .touchUpInside)
        button.backgroundColor = .red
        button.layer.cornerRadius = 5
        return button
    }()

    // MARK: State

    enum ViewState {

        // Requesting and loading the data sets into the cache.
        case loading

        // Finished loading data into the cache.
        case rendering
    }

    /// Holds the view controllers state.
    private var viewState: ViewState = .loading {
        didSet {
            // Early exit if state value didn't change
            guard oldValue != .rendering else { return }

            switch viewState {
            case .loading:
                slider.value = 0
                lowerIndexLabel.text = "-"
                upperIndexLabel.text = "-"
                currentIndexLabel.text = "-"
                failedIndicesLabel.removeFromSuperview()
            case .rendering:
                guard let dataManager = dataManager, let lastDataSet = dataManager.cache.last else { return }
                graphView.setup(grid: dataManager.grid, with: lastDataSet)

                // Slider values
                slider.minimumValue = 0
                slider.maximumValue = Float(dataManager.cache.count - 1)

                // Label values
                lowerIndexLabel.text = "0"
                upperIndexLabel.text = "\(dataManager.cache.count - 1)"

                // Create new DisplayLink
                displayLink = CADisplayLink(target: self, selector: #selector(updateDisplay))
                displayLink?.add(to: .current, forMode: .common)

                // Set the current sliders index
                slider.setValue(Float(dataManager.cache.count - 1), animated: true)

                // Show any failed indices
                showFailedIndices(dataManager.failedIndices)

                // Update the layout if needed
                view.layoutIfNeeded()
            }
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Setup view and constraints
        setupView()
        setConstraints()

        // Prepare to show graph
        prepareForNewGraph()
    }

    private func setupView() {
        [
            graphView,
            slider,
            lowerIndexLabel,
            upperIndexLabel,
            currentIndexLabel,
            resetButton
            ].forEach { view.addSubview($0) }
    }

    private func setConstraints() {
        graphView.translatesAutoresizingMaskIntoConstraints = false
        slider.translatesAutoresizingMaskIntoConstraints = false
        lowerIndexLabel.translatesAutoresizingMaskIntoConstraints = false
        upperIndexLabel.translatesAutoresizingMaskIntoConstraints = false
        currentIndexLabel.translatesAutoresizingMaskIntoConstraints = false
        resetButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            graphView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            graphView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            graphView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            slider.topAnchor.constraint(equalTo: graphView.bottomAnchor, constant: 32),
            slider.leadingAnchor.constraint(equalTo: lowerIndexLabel.trailingAnchor, constant: 16),
            slider.trailingAnchor.constraint(equalTo: upperIndexLabel.leadingAnchor, constant: -16),
            lowerIndexLabel.widthAnchor.constraint(equalToConstant: 50),
            lowerIndexLabel.heightAnchor.constraint(equalTo: slider.heightAnchor),
            lowerIndexLabel.topAnchor.constraint(equalTo: graphView.bottomAnchor, constant: 32),
            lowerIndexLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            upperIndexLabel.widthAnchor.constraint(equalToConstant: 50),
            upperIndexLabel.heightAnchor.constraint(equalTo: slider.heightAnchor),
            upperIndexLabel.topAnchor.constraint(equalTo: graphView.bottomAnchor, constant: 32),
            upperIndexLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            currentIndexLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 32),
            currentIndexLabel.heightAnchor.constraint(equalToConstant: 20),
            currentIndexLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            currentIndexLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            resetButton.topAnchor.constraint(equalTo: currentIndexLabel.bottomAnchor, constant: 32),
            resetButton.widthAnchor.constraint(equalToConstant: 80),
            resetButton.heightAnchor.constraint(equalToConstant: 44),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    /// Prepares the view controller to start loading a new graph.
    private func prepareForNewGraph() {
        dataManager = DensityDataManager(service: DensityDataService())
        dataManager?.delegate = self

        // Loading state
        viewState = .loading

        // Show loading view
        showLoadingView()

        // Start fetching and caching data sets on a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.dataManager?.fetchAndCacheData()
        }
    }

    /// DisplayLink update action.
    @objc private func updateDisplay() {
        let sliderValue = UInt(slider.value)
        // Only continue if sliderValue index is different to the renderedIndex
        guard graphView.renderedIndex != sliderValue else { return }
        guard let data = dataManager?.cache[Int(sliderValue)] else { return }
        currentIndexLabel.text = "\(sliderValue)"
        graphView.updateGraph(with: data, for: sliderValue)
    }

    /// Reset button action.
    @objc private func reset() {
        // Invalidate the current display link
        displayLink?.invalidate()
        displayLink = nil

        // Reset the `DensityGraphView`
        graphView.reset()

        prepareForNewGraph()
    }

    /// Show the user a label of hard failed indices.
    ///
    /// NOTE: Supports multiple failed indices.
    func showFailedIndices(_ indices: [UInt]) {
        guard indices.count > 0 else { return }
        failedIndicesLabel.textAlignment = .center
        failedIndicesLabel.numberOfLines = 0
        failedIndicesLabel.text = "Failed indices: \(indices.map { String($0) }.joined(separator: ", "))"

        // Add it to main view before setting constraints
        view.addSubview(failedIndicesLabel)

        // Set constraints
        failedIndicesLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            failedIndicesLabel.topAnchor.constraint(equalTo: resetButton.bottomAnchor, constant: 24),
            failedIndicesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            failedIndicesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }
}

// MARK: - DensityDataManagerDelegate

extension ViewController: DensityDataManagerDelegate {

    func didUpdateCache() {
        DispatchQueue.main.async { [weak self] in
            self?.loadingView?.progressLabel.text = "\(self?.dataManager?.progress ?? 0)%"
        }
    }

    func didCompleteCache() {
        DispatchQueue.main.async { [weak self] in
            self?.hideLoadingView()
            // Cahnge view state
            self?.viewState = .rendering
        }
    }
}

// MARK: - LoadingView

extension ViewController {

    /// Show the loading view.
    func showLoadingView() {
        viewState = .loading
        loadingView = LoadingView()
        guard let loadingView = loadingView else { return }
        view.addSubview(loadingView)

        // Set view constraints
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Start loader
        loadingView.setupView()
        loadingView.startLoading()
    }

    /// Stop and hide the loading view.
    func hideLoadingView() {
        if loadingView == nil { return }
        loadingView?.stopLoading()
        UIView.animate(withDuration: 0.4, animations: {
            self.loadingView?.alpha = 0.0
        }) { _ in
            self.loadingView?.removeFromSuperview()
        }
        loadingView = nil
    }
}
