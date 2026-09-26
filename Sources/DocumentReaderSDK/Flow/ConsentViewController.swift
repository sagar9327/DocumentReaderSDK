//
//  ConsentViewController.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 26/09/26.
//
import UIKit

final class ConsentViewController: UIViewController {

    // MARK: - UI

    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let agreeSwitch = UISwitch()
    private let agreeLabel = UILabel()
    private let nextButton = UIButton(type: .system)

    // MARK: - Async Flow

    private var continuation:
        CheckedContinuation<Bool, Never>?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Identity Verification"
        view.backgroundColor = .systemBackground

        setupUI()
    }

    // MARK: - Public Flow

    func waitForAgreement() async -> Bool {

        await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<Bool, Never>
            ) in

            self.continuation = continuation
        }
    }

    // MARK: - UI

    private func setupUI() {

        titleLabel.text =
            "Before We Begin"

        titleLabel.font =
            .systemFont(
                ofSize: 28,
                weight: .bold
            )

        titleLabel.textAlignment =
            .center

        titleLabel.numberOfLines =
            0

        messageLabel.text =
            """
            To proceed, we need to collect and process your selfie and identity document.

            Your selfie will be used for identity verification and your document will be captured to extract the required information.

            Please make sure you are ready before continuing.
            """

        messageLabel.font =
            .systemFont(
                ofSize: 16
            )

        messageLabel.textColor =
            .secondaryLabel

        messageLabel.numberOfLines =
            0

        agreeLabel.text =
            "I agree to proceed with identity verification"

        agreeLabel.font =
            .systemFont(
                ofSize: 16,
                weight: .medium
            )

        agreeLabel.numberOfLines =
            0

        agreeSwitch.isOn =
            false

        agreeSwitch.addTarget(
            self,
            action: #selector(
                agreementChanged
            ),
            for: .valueChanged
        )

        nextButton.setTitle(
            "I Agree & Next",
            for: .normal
        )

        nextButton.titleLabel?.font =
            .systemFont(
                ofSize: 17,
                weight: .semibold
            )

        nextButton.backgroundColor =
            .systemBlue

        nextButton.setTitleColor(
            .white,
            for: .normal
        )

        nextButton.layer.cornerRadius =
            12

        nextButton.isEnabled =
            false

        nextButton.alpha =
            0.5

        nextButton.addTarget(
            self,
            action: #selector(
                nextTapped
            ),
            for: .touchUpInside
        )

        let agreementStack =
            UIStackView(
                arrangedSubviews: [
                    agreeSwitch,
                    agreeLabel
                ]
            )

        agreementStack.axis =
            .horizontal

        agreementStack.alignment =
            .center

        agreementStack.spacing =
            12

        let stackView =
            UIStackView(
                arrangedSubviews: [
                    titleLabel,
                    messageLabel,
                    agreementStack,
                    nextButton
                ]
            )

        stackView.axis =
            .vertical

        stackView.spacing =
            24

        view.addSubview(
            stackView
        )

        stackView.translatesAutoresizingMaskIntoConstraints =
            false

        NSLayoutConstraint.activate([

            stackView.leadingAnchor.constraint(
                equalTo:
                    view.leadingAnchor,
                constant: 24
            ),

            stackView.trailingAnchor.constraint(
                equalTo:
                    view.trailingAnchor,
                constant: -24
            ),

            stackView.centerYAnchor.constraint(
                equalTo:
                    view.centerYAnchor
            ),

            nextButton.heightAnchor.constraint(
                equalToConstant: 52
            )
        ])
    }

    // MARK: - Agreement

    @objc
    private func agreementChanged() {

        nextButton.isEnabled =
            agreeSwitch.isOn

        nextButton.alpha =
            agreeSwitch.isOn
            ? 1.0
            : 0.5
    }

    // MARK: - Next

    @objc
    private func nextTapped() {

        guard agreeSwitch.isOn else {
            return
        }

        print(
            "✅ Consent accepted"
        )

        continuation?.resume(
            returning: true
        )

        continuation = nil
    }

    // MARK: - Cleanup

    deinit {

        continuation?.resume(
            returning: false
        )

        continuation = nil
    }
}
