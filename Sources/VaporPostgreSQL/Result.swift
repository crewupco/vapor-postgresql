// The MIT License (MIT)
//
// Copyright (c) 2015 Formbound
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import CPostgreSQL
import Foundation

public enum ResultError: Error {
  case badStatus(Result.Status, String)
}

public class Result {
  public enum Status: Int {
    case emptyQuery
    case commandOK
    case tuplesOK
    case copyOut
    case copyIn
    case badResponse
    case nonFatalError
    case fatalError
    case copyBoth
    case singleTuple
    case unknown
        
    public init(status: ExecStatusType) {
      switch status {
        case PGRES_EMPTY_QUERY:
          self = .emptyQuery
        case PGRES_COMMAND_OK:
          self = .commandOK
        case PGRES_TUPLES_OK:
          self = .tuplesOK
        case PGRES_COPY_OUT:
          self = .copyOut
        case PGRES_COPY_IN:
          self = .copyIn
        case PGRES_BAD_RESPONSE:
          self = .badResponse
        case PGRES_NONFATAL_ERROR:
          self = .nonFatalError
        case PGRES_FATAL_ERROR:
          self = .fatalError
        case PGRES_COPY_BOTH:
          self = .copyBoth
        case PGRES_SINGLE_TUPLE:
          self = .singleTuple
        default:
          self = .unknown
      }
    }
        
    public var successful: Bool {
      return self != .badResponse && self != .fatalError
    }
  }

  public var status: Status {
    return Status(status: PQresultStatus(resultPointer))
  }
  
  fileprivate lazy var fields: [String] = {
    var result: [String] = []
    
    for i in 0..<PQnfields(self.resultPointer) {
      guard let fieldName = String(validatingUTF8: PQfname(self.resultPointer, i)) else {
        continue
      }
      
      result.append(fieldName)
    }
    
    return result
  }()

  fileprivate let resultPointer: OpaquePointer
  
  internal init(_ resultPointer: OpaquePointer) throws {
    self.resultPointer = resultPointer
        
    guard status.successful else {
      throw ResultError.badStatus(status, String(validatingUTF8: PQresultErrorMessage(resultPointer)) ?? "No error message")
    }
  }
    
  deinit {
    clear()
  }
    
  public func clear() {
    PQclear(resultPointer)
  }
}

extension Result: Collection {
  public var count: Int {
    return Int(PQntuples(self.resultPointer))
  }
  
  public var startIndex: Int {
    return 0
  }
  
  public var endIndex: Int {
    return count
  }
  
  public func index(after: Int) -> Int {
    return after + 1
  }

  public func makeIterator() -> RowIterator {
    var index = 0
    
    return RowIterator {
      if index < 0 || index >= self.count {
        return nil
      }
      
      let row = self[index]
      index += 1
      return row
    }
  }
  
  public subscript(position: Int) -> Row {
    let index = Int32(position)
    var result: [String: Data?] = [:]
    
    for (fieldIndex, field) in fields.enumerated() {
      let fieldIndex = Int32(fieldIndex)
      
      if PQgetisnull(resultPointer, index, fieldIndex) == 1 {
        // Set the key to nil to distinguish between a null field and a missing field.
        result.updateValue(nil, forKey: field)
      }
      else {
        result[field] = Data(bytes: PQgetvalue(resultPointer, index, fieldIndex),
                             count: Int(PQgetlength(resultPointer, index, fieldIndex)))
      }
    }
    
    return Row(dataByfield: result)
  }
}
