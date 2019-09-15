//  Copyright © 2019 James Horan. All rights reserved.

import UIKit

final class LoadingView: UIView {

    enum Constant {
        static let startValue = "0%"
        static let endValue = "100%"
    }

    // MARK: - Properties

    private let activityIndicatorView = UIActivityIndicatorView()
    let progressLabel = UILabel()

    // MARK: - Functions

    /// Setup a LoadingView.
    func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.6)

        activityIndicatorView.style = .whiteLarge
        progressLabel.text = Constant.startValue
        progressLabel.textColor = .white
        progressLabel.textAlignment = .center
        progressLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)

        [activityIndicatorView, progressLabel].forEach { addSubview($0) }

        // Set constraints
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressLabel.topAnchor.constraint(equalTo: activityIndicatorView.bottomAnchor, constant: 24),
            progressLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            progressLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            progressLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    /// Start the loading view.
    func startLoading() {
        progressLabel.text = Constant.startValue
        activityIndicatorView.startAnimating()
    }

    /// Stop the loading view.
    func stopLoading() {
        progressLabel.text = Constant.endValue
        activityIndicatorView.stopAnimating()
    }
}
