//
//  DataParser.swift
//  LiveTesting
//

import Foundation

protocol DataParserProtocol {
	func parse<T: Decodable>(data: Data) throws -> T
	func parse<T: Decodable>(string: String) throws -> T
}

class DataParser: DataParserProtocol {
	private var jsonDecoder: JSONDecoder

	init(jsonDecoder: JSONDecoder = JSONDecoder()) {
		self.jsonDecoder = jsonDecoder
		self.jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
	}

	func parse<T: Decodable>(data: Data) throws -> T {
		return try jsonDecoder.decode(T.self, from: data)
	}
	
	func parse<T: Decodable>(string: String) throws -> T {
		let data = string.data(using: .utf8)
		return try self.parse(data: data!)
	}
}
