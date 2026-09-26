//
//  Untitled.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 25/09/26.
//
import UIKit
public struct DocumentReaderResult {
    public let firstName: String
    public let lastName: String
    public let selfie: UIImage

    public init(
        firstName: String,
        lastName: String,
        selfie: UIImage
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.selfie = selfie
    }
}
