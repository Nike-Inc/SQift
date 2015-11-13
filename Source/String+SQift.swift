//
//  String+SQift.swift
//  SQift
//
//  Created by Dave Camp on 3/14/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

private let SingleQuote = Character("'")

extension String {
    func sanitize() -> String {
        var sanitizedCharacters: [Character] = []

        for (index, character) in characters.enumerate() {
            if index == 0 || index == (characters.count - 1) {
                if character != SingleQuote { sanitizedCharacters.append(character) }
            } else {
                if character == SingleQuote {
                    sanitizedCharacters.append(character)
                }

                sanitizedCharacters.append(character)
            }
        }

        return String(SingleQuote) + String(sanitizedCharacters) + String(SingleQuote)
    }
}
