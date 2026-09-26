//
//  UserDetailVC.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 26/09/26.
//
import UIKit

final class UserDetailsViewController: UIViewController {

    private let firstNameTextField = UITextField()
    private let lastNameTextField = UITextField()
    private let nextButton = UIButton(type: .system)

    private var continuation:
        CheckedContinuation<UserDetails, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "User Details"
        view.backgroundColor = .systemBackground

        setupUI()
    }

    // MARK: - UI

    private func setupUI() {

        firstNameTextField.placeholder =
            "First Name"

        firstNameTextField.borderStyle =
            .roundedRect

        lastNameTextField.placeholder =
            "Last Name"

        lastNameTextField.borderStyle =
            .roundedRect

        nextButton.setTitle(
            "Next",
            for: .normal
        )

        nextButton.isEnabled = false

        nextButton.addTarget(
            self,
            action: #selector(nextButtonTapped),
            for: .touchUpInside
        )

        firstNameTextField.addTarget(
            self,
            action: #selector(textFieldDidChange),
            for: .editingChanged
        )

        lastNameTextField.addTarget(
            self,
            action: #selector(textFieldDidChange),
            for: .editingChanged
        )

        let stackView =
            UIStackView(
                arrangedSubviews: [
                    firstNameTextField,
                    lastNameTextField,
                    nextButton
                ]
            )

        stackView.axis = .vertical
        stackView.spacing = 16

        view.addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints =
            false

        NSLayoutConstraint.activate([

            stackView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 24
            ),

            stackView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -24
            ),

            stackView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            )
        ])
    }

    // MARK: - Async Flow

    func getUserDetails() async -> UserDetails {

        await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<UserDetails, Never>
            ) in

            self.continuation =
                continuation
        }
    }

    // MARK: - Validation

    @objc
    private func textFieldDidChange() {

        let firstName =
            firstNameTextField.text?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""

        let lastName =
            lastNameTextField.text?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""

        nextButton.isEnabled =
            !firstName.isEmpty &&
            !lastName.isEmpty
    }

    // MARK: - Next

    @objc
    private func nextButtonTapped() {

        let firstName =
            firstNameTextField.text?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""

        let lastName =
            lastNameTextField.text?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""

        guard
            !firstName.isEmpty,
            !lastName.isEmpty
        else {
            return
        }

        print("✅ User Details Next tapped")

        continuation?.resume(
            returning: UserDetails(
                firstName: firstName,
                lastName: lastName
            )
        )

        continuation = nil
    }
}
