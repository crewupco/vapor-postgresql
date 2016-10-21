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

public struct DeclaredField: CustomStringConvertible {
  public let unqualifiedName: String
  public var tableName: String?
    
  public init(name: String, tableName: String? = nil) {
    self.unqualifiedName = name
    self.tableName = tableName
  }
}

extension DeclaredField: Hashable {
  public var hashValue: Int {
    return qualifiedName.hashValue
  }
}

public extension Sequence where Iterator.Element == DeclaredField {
  public func queryComponentsForSelectingFields(useQualifiedNames useQualified: Bool, useAliasing aliasing: Bool, isolateQueryComponents isolate: Bool) -> QueryComponents {
    let string = map { field in
      var str = useQualified ? field.qualifiedName : field.unqualifiedName
            
      if aliasing && field.qualifiedName != field.alias {
        str += " AS \(field.alias)"
      }
            
      return str
    }.joined(separator: ", ")
        
    if isolate {
      return QueryComponents(string).isolate()
    }
    else {
      return QueryComponents(string)
    }
  }
}

public extension Collection where Iterator.Element == (DeclaredField, Optional<SQLData>) {
  public func queryComponentsForSettingValues(useQualifiedNames useQualified: Bool) -> QueryComponents {
    let string = map { (field, value) in
      var str = useQualified ? field.qualifiedName : field.unqualifiedName
            
      str += " = " + QueryComponents.valuePlaceholder
            
      return str
    }.joined(separator: ", ")
        
    return QueryComponents(string, values: map { $0.1 })
  }
    
  public func queryComponentsForValuePlaceHolders(isolated isolate: Bool) -> QueryComponents {
    var strings = [String]()
        
    for _ in self {
      strings.append(QueryComponents.valuePlaceholder)
    }
        
    let string = strings.joined(separator: ", ")
    let components = QueryComponents(string, values: map { $0.1 })
        
    return isolate ? components.isolate() : components
  }
}

public func == (lhs: DeclaredField, rhs: DeclaredField) -> Bool {
  return lhs.hashValue == rhs.hashValue
}

public extension DeclaredField {
  public var qualifiedName: String {
    guard let tableName = tableName else {
      return unqualifiedName
    }
        
    return tableName + "." + unqualifiedName
  }

  public var alias: String {
    guard let tableName = tableName else {
      return unqualifiedName
    }
        
    return tableName + "__" + unqualifiedName
  }

  public var description: String {
    return qualifiedName
  }

  public func containedIn<T: SQLDataConvertible>(_ values: [T?]) -> Condition {
    return .in(self, values.map { $0?.sqlData })
  }

  public func containedIn<T: SQLDataConvertible>(_ values: T?...) -> Condition {
    return .in(self, values.map { $0?.sqlData })
  }

  public func notContainedIn<T: SQLDataConvertible>(_ values: [T?]) -> Condition {
    return .notIn(self, values.map { $0?.sqlData })
  }

  public func notContainedIn<T: SQLDataConvertible>(_ values: T?...) -> Condition {
    return .notIn(self, values.map { $0?.sqlData })
  }
    
  public func equals<T: SQLDataConvertible>(_ value: T?) -> Condition {
    return .equals(self, .value(value?.sqlData))
  }
    
  public func like<T: SQLDataConvertible>(_ value: T?) -> Condition {
    return .like(self, value?.sqlData)
  }

  public func likeIgnoringCase<T: SQLDataConvertible>(_ value: T?) -> Condition {
    return .ilike(self, value?.sqlData)
  }
}

public func == <T: SQLDataConvertible>(lhs: DeclaredField, rhs: T?) -> Condition {
  return lhs.equals(rhs)
}

public func == (lhs: DeclaredField, rhs: DeclaredField) -> Condition {
  return .equals(lhs, .property(rhs))
}

public func > <T: SQLDataConvertible>(lhs: DeclaredField, rhs: T?) -> Condition {
  return .greaterThan(lhs, .value(rhs?.sqlData))
}

public func > (lhs: DeclaredField, rhs: DeclaredField) -> Condition {
  return .greaterThan(lhs, .property(rhs))
}

public func >= <T: SQLDataConvertible>(lhs: DeclaredField, rhs: T?) -> Condition {
  return .greaterThanOrEquals(lhs, .value(rhs?.sqlData))
}

public func >= (lhs: DeclaredField, rhs: DeclaredField) -> Condition {
  return .greaterThanOrEquals(lhs, .property(rhs))
}

public func < <T: SQLDataConvertible>(lhs: DeclaredField, rhs: T?) -> Condition {
  return .lessThan(lhs, .value(rhs?.sqlData))
}

public func < (lhs: DeclaredField, rhs: DeclaredField) -> Condition {
  return .lessThan(lhs, .property(rhs))
}

public func <= <T: SQLDataConvertible>(lhs: DeclaredField, rhs: T?) -> Condition {
  return .lessThanOrEquals(lhs, .value(rhs?.sqlData))
}

public func <= (lhs: DeclaredField, rhs: DeclaredField) -> Condition {
  return .lessThanOrEquals(lhs, .property(rhs))
}

public protocol FieldProtocol: RawRepresentable, Hashable {
  var rawValue: String { get }
}

