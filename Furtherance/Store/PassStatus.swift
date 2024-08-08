//
//  PassStatus.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 08.08.2024.
//

import StoreKit
import SwiftUI

enum PassStatus: Comparable, Hashable {
	case notSubscribed
	case yearly

	init?(productID: Product.ID, ids: PassIdentifiers) {
		switch productID {
		case ids.yearly: self = .yearly
		default: return nil
		}
	}

	var description: String {
		switch self {
		case .notSubscribed:
			"Not Subscribed"
		case .yearly:
			"Yearly"
		}
	}
}

struct PassIdentifiers {
	var group: String
	var yearly: String
}

extension EnvironmentValues {
	private enum PassIDsKey: EnvironmentKey {
		static var defaultValue = PassIdentifiers(
			group: "21523359",
			yearly: "yearly10"
		)
	}

	var passIDs: PassIdentifiers {
		get { self[PassIDsKey.self] }
		set { self[PassIDsKey.self] = newValue }
	}
}
