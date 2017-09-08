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

public protocol Query: QueryComponentsConvertible {}

extension Query {
  public func execute(_ connection: Connection) throws -> Result {
    return try connection.execute(self)
  }
}

public protocol TableQuery: Query {
  var tableName: String { get }
}

public protocol ModelQuery: TableQuery {
  associatedtype ModelType: Model
}

extension ModelQuery where Self: SelectQuery {
  public func fetch(_ connection: Connection) throws -> [ModelType] {
    return try connection.execute(self).map { try ModelType(row: $0) }
  }
    
  public func first(_ connection: Connection) throws -> ModelType? {
    var new = self
    new.offset = 0
    new.limit = 1
    return try connection.execute(new).map { try ModelType(row: $0) }.first
  }
    
  public func orderBy(_ values: [ModelOrderBy<ModelType>]) -> Self {
    return orderBy(values.map { $0.normalize })
  }
    
  public func orderBy(_ values: ModelOrderBy<ModelType>...) -> Self {
    return orderBy(values)
  }
}

public struct Limit: QueryComponentsConvertible {
  public let value: Int
    
  public init(_ value: Int) {
    self.value = value
  }
    
  public var queryComponents: QueryComponents {
    return QueryComponents(strings: ["LIMIT", String(value)])
  }
}

extension Limit: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.value = value
  }
}

public struct Offset: QueryComponentsConvertible {
  public let value: Int
    
  public init(_ value: Int) {
    self.value = value
  }
    
  public var queryComponents: QueryComponents {
    return QueryComponents(strings: ["OFFSET", String(value)])
  }
}

extension Offset: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.value = value
  }
}

public enum OrderBy: QueryComponentsConvertible {
  case ascending(String)
  case descending(String)
    
  public var queryComponents: QueryComponents {
    switch self {
      case .ascending(let field):
        return QueryComponents(strings: [field, "ASC"])
      case .descending(let field):
        return QueryComponents(strings: [field, "DESC"])
    }
  }
}

public enum DeclaredFieldOrderBy {
  case ascending(DeclaredField)
  case descending(DeclaredField)
    
  public var normalize: OrderBy {
    switch self {
      case .ascending(let field):
        return .ascending(field.qualifiedName)
      case .descending(let field):
        return .descending(field.qualifiedName)
    }
  }
}

public enum ModelOrderBy<T: Model> {
  case ascending(T.Field)
  case descending(T.Field)
    
  public var normalize: DeclaredFieldOrderBy {
    switch self {
      case .ascending(let field):
        return .ascending(T.field(field))
      case .descending(let field):
        return .descending(T.field(field))
    }
  }
}

extension Sequence where Self.Iterator.Element == OrderBy {
  public var queryComponents: QueryComponents {
    return QueryComponents(components: map { $0.queryComponents })
  }
}

public protocol FilteredQuery: Query {
  var condition: Condition? { get set }
}

extension FilteredQuery {
  public func filter(_ condition: Condition) -> Self {
    let newCondition: Condition
    
    if let existing = self.condition {
      newCondition = .and([existing, condition])
    }
    else {
      newCondition = condition
    }
        
    var new = self
    new.condition = newCondition
        
    return new
  }
}

public struct Join: QueryComponentsConvertible {
  public enum JoinType: QueryComponentsConvertible {
    case inner
    case outer
    case left
    case right
        
    public var queryComponents: QueryComponents {
      switch self {
        case .inner:
          return "INNER"
        case .outer:
          return "OUTER"
        case .left:
          return "LEFT"
        case .right:
          return "RIGHT"
      }
    }
  }
    
  public let tableName: String
  public let types: [JoinType]
  public let leftKey: String
  public let rightKey: String
    
  public init(_ tableName: String, type: [JoinType], leftKey: String, rightKey: String) {
    self.tableName = tableName
    self.types = type
    self.leftKey = leftKey
    self.rightKey = rightKey
  }
    
  public var queryComponents: QueryComponents {
    return QueryComponents(components: [
      types.queryComponents,
      "JOIN",
      QueryComponents(strings: [
        tableName,
        "ON",
        leftKey,
        "=",
        rightKey
      ])
    ])
  }
}
