//
//  ViewStates.swift
//  LiveTesting
//

import Foundation

enum ViewState<DataType, ProgressType, ErrorType: Error> {
	case loading(ProgressType)
	case error(ErrorType)
	case empty
	case content(data: DataType)
}
