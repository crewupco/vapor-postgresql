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

public indirect enum Condition: QueryComponentsConvertible {
  public enum Key {
    case value(SQLData?)
    case property(DeclaredField)
  }

  case equals(DeclaredField, Key)
  case greaterThan(DeclaredField, Key)
  case greaterThanOrEquals(DeclaredField, Key)
  case lessThan(DeclaredField, Key)
  case lessThanOrEquals(DeclaredField, Key)
  case like(DeclaredField, SQLData?)
  case ilike(DeclaredField, SQLData?)
  case `in`(DeclaredField, [SQLData?])
  case notIn(DeclaredField, [SQLData?])
  case null(DeclaredField)
  case notNull(DeclaredField)
  case and([Condition])
  case or([Condition])
  case not(Condition)
  case sql(String, [SQLData?])
  
  public var queryComponents: QueryComponents {
    func statementWithKeyValue(_ key: String, _ op: String, _ value: Key) -> QueryComponents {
      switch value {
        case .value(let value):
          return QueryComponents("\(key) \(op) \(QueryComponents.valuePlaceholder)", values: [value])
        case .property(let name):
          return QueryComponents("\(key) \(op) \(name)", values: [])
      }
    }

    switch self {
      case let .equals(key, value):
        return statementWithKeyValue(key.qualifiedName, "=", value)
      case let .greaterThan(key, value):
        return statementWithKeyValue(key.qualifiedName, ">", value)
      case let .greaterThanOrEquals(key, value):
        return statementWithKeyValue(key.qualifiedName, ">=", value)
      case let .lessThan(key, value):
        return statementWithKeyValue(key.qualifiedName, "<", value)
      case let .lessThanOrEquals(key, value):
        return statementWithKeyValue(key.qualifiedName, "<=", value)
      case let .in(key, values):
        let strings = [String](repeating: QueryComponents.valuePlaceholder, count: values.count)
        return QueryComponents("\(key) IN (\(strings.joined(separator: ", ")))", values: values)
      case let .notIn(key, values):
        return (!Condition.in(key, values)).queryComponents
      case let .null(key):
        return QueryComponents("\(key) IS NULL", values: [])
      case let .notNull(key):
        return QueryComponents("\(key) IS NOT NULL", values: [])
      case let .and(conditions):
        return QueryComponents(components: conditions.map { $0.queryComponents }, mergedByString: "AND").isolate()
      case let .or(conditions):
        return QueryComponents(components: conditions.map { $0.queryComponents }, mergedByString: "OR").isolate()
      case let .not(condition):
        var queryComponents = condition.queryComponents.isolate()
        queryComponents.prepend("NOT")
        return queryComponents
      case let .like(key, value):
        return QueryComponents(strings: [key.qualifiedName, "LIKE", QueryComponents.valuePlaceholder], values: [value])
      case let .ilike(key, value):
        return QueryComponents(strings: [key.qualifiedName, "ILIKE", QueryComponents.valuePlaceholder], values: [value])
      case let .sql(sql, values):
        return QueryComponents(sql, values: values).isolate()
    }
  }
}

public prefix func ! (condition: Condition) -> Condition {
  return .not(condition)
}

public func && (lhs: Condition, rhs: Condition) -> Condition {
  return .and([lhs, rhs])
}

public func || (lhs: Condition, rhs: Condition) -> Condition {
  return .or([lhs, rhs])
}
