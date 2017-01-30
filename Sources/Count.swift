// The MIT License (MIT)
//
// Copyright (c) 2016 Formbound
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

public struct Count: CountQuery {
  public let tableName: String
  public var condition: Condition?
  public var joins: [Join] = []
  
  public init(from tableName: String) {
    self.tableName = tableName
  }
    
  public func join(_ tableName: String, using type: [Join.JoinType], leftKey: String, rightKey: String) -> Count {
    var new = self
    
    new.joins.append(Join(tableName, type: type, leftKey: leftKey, rightKey: rightKey))
        
    return new
  }
    
  public func join(_ tableName: String, using type: Join.JoinType, leftKey: String, rightKey: String) -> Count {
    return join(tableName, using: [type], leftKey: leftKey, rightKey: rightKey)
  }
}

public struct ModelCount<T: Model>: CountQuery, ModelQuery {
  public typealias ModelType = T
    
  public var tableName: String {
    return T.tableName
  }
    
  public var condition: Condition?
  public var joins: [Join] = []
  
  public func join<R: Model>(_ model: R.Type, using type: [Join.JoinType], leftKey: ModelType.Field, rightKey: R.Field) -> ModelCount<T> {
    var new = self
    
    new.joins.append(
      Join(R.tableName, type: type, leftKey: ModelType.field(leftKey).qualifiedName, rightKey: R.field(rightKey).qualifiedName)
    )
        
    return new
  }
    
  public func join<R: Model>(_ model: R.Type, using type: Join.JoinType, leftKey: ModelType.Field, rightKey: R.Field) -> ModelCount<T> {
    return join(model, using: [type], leftKey: leftKey, rightKey: rightKey)
  }
}

public protocol CountQuery: FilteredQuery, TableQuery {
  var joins: [Join] { get set }
}

public extension CountQuery {
  public var queryComponents: QueryComponents {
    var components = QueryComponents(components: [
      "SELECT COUNT(",
      QueryComponents("\(tableName).*"),
      ") FROM",
      QueryComponents(tableName)
    ])
        
    if !joins.isEmpty {
      components.append(joins.queryComponents)
    }
        
    if let condition = condition {
      components.append("WHERE")
      components.append(condition.queryComponents)
    }
    
    return components
  }
  
  public func fetch(_ connection: Connection) throws -> Int {
    return try connection.execute(self).first?.value("count") ?? 0
  }
}
