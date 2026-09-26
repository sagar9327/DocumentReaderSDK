// The Swift Programming Language
// https://docs.swift.org/swift-book
import UIKit

public final class DocumentReader {

    private var firstName: String?
    private var lastName: String?
    private var selfie: UIImage?
    private var documentImage: UIImage?

    public init() {}

    @MainActor
    public func start(
        from viewController: UIViewController
    ) async throws -> DocumentReaderResult {

        // MARK: 1. Consent

        let consentVC = ConsentViewController()

        let navigationController =
            UINavigationController(
                rootViewController: consentVC
            )

        viewController.present(
            navigationController,
            animated: true
        )

        let agreed =
            await consentVC.waitForAgreement()

        guard agreed else {
            navigationController.dismiss(
                animated: true
            )

            throw DocumentReaderError.processingFailed
        }


        // MARK: 2. User Details

        let userDetailsVC =
            UserDetailsViewController()

        navigationController.pushViewController(
            userDetailsVC,
            animated: true
        )

        let userDetails =
            await userDetailsVC.getUserDetails()

        firstName =
            userDetails.firstName

        lastName =
            userDetails.lastName


        // MARK: 3. Selfie

        let selfieVC =
            SelfieViewController()

        navigationController.pushViewController(
            selfieVC,
            animated: true
        )

        let capturedSelfie =
            await selfieVC.captureSelfie()

        guard let capturedSelfie else {
            throw DocumentReaderError.processingFailed
        }

        selfie =
            capturedSelfie


        // MARK: 4. Document

        let documentScannerVC =
            DocumentScannerViewController()

        navigationController.pushViewController(
            documentScannerVC,
            animated: true
        )

        let capturedDocument =
            await documentScannerVC.scanDocument()

        documentImage =
            capturedDocument


        // MARK: 5. Finish

        guard
            let firstName,
            let lastName,
            let selfie,
            let documentImage
        else {
            throw DocumentReaderError.processingFailed
        }

        navigationController.dismiss(
            animated: true
        )

        return DocumentReaderResult(
            firstName: firstName,
            lastName: lastName,
            selfie: selfie
        )
    }
}
