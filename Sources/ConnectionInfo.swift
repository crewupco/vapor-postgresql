// The MIT License (MIT)
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

import Foundation

public struct ConnectionInfo {
  public let host: String
  public let port: Int
  public let database: String
  public let username: String?
  public let password: String?
  public let options: String?
  public let tty: String?
  
  public init?(uri: URL, options: String? = nil, tty: String? = nil) {
    do {
      try self.init(uri)
    }
    catch {
      return nil
    }
  }
  
  public init(_ uri: URL, options: String? = nil, tty: String? = nil) throws {
    guard let host = uri.host, let port = uri.port else {
      throw ConnectionError(description: "Failed to extract host, port, database name from URI")
    }
    
    let database = uri.path.trimmingCharacters(in: ["/"])
    
    self.init(host: host, port: port, database: database, username: uri.user, password: uri.password, options: options, tty: tty)
  }
  
  public init(host: String, port: Int = 5432, database: String, username: String? = nil, password: String? = nil, options: String? = nil, tty: String? = nil) {
    self.host = host
    self.port = port
    self.database = database
    self.username = username
    self.password = password
    self.options = options
    self.tty = tty
  }
}

