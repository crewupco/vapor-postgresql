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

public protocol SelectQuery: FilteredQuery, TableQuery {
  var joins: [Join] { get set }
  var fields: [DeclaredField] { get }
  var distinct: Bool { get set }
  var offset: Offset? { get set }
  var limit: Limit? { get set }
  var orderBy: [OrderBy] { get set }
}

public extension SelectQuery {
  public var pageSize: Int? {
    get {
      return limit?.value
    }
    set {
      guard let value = newValue else {
        limit = nil
        return
      }
      limit = Limit(value)
    }
  }
  
  public func page(_ value: Int?) -> Self {
    var new = self
    new.page = value
    return new
  }
  
  public func pageSize(_ value: Int?) -> Self {
    var new = self
    new.pageSize = value
    return new
  }
  
  public var page: Int? {
    set {
      guard let value = newValue, let limit = limit else {
        offset = nil
        return
      }
      
      offset = Offset(value * limit.value)
    }
    
    get {
      guard let offset = offset, let limit = limit else {
        return nil
      }
      
      return offset.value / limit.value
    }
  }
  
  public func orderBy(_ values: [OrderBy]) -> Self {
    var new = self
    new.orderBy.append(contentsOf: values)
    return new
  }
  
  public func orderBy(_ values: OrderBy...) -> Self {
    return orderBy(values)
  }
  
  public func orderBy(_ values: [DeclaredFieldOrderBy]) -> Self {
    return orderBy(values.map { $0.normalize })
  }
  
  public func orderBy(_ values: DeclaredFieldOrderBy...) -> Self {
    return orderBy(values)
  }
  
  public func limit(_ value: Int?) -> Self {
    var new = self
    
    if let value = value {
      new.limit = Limit(value)
    }
    else {
      new.limit = nil
    }
    
    return new
  }
  
  public func offset(_ value: Int?) -> Self {
    var new = self
    
    if let value = value {
      new.offset = Offset(value)
    }
    else {
      new.offset = nil
    }
    
    return new
  }

  public var queryComponents: QueryComponents {
    var components = QueryComponents(components: [
      distinct ? "SELECT DISTINCT" : "SELECT",
      fields.isEmpty ? QueryComponents("\(tableName).*") : fields.queryComponentsForSelectingFields(useQualifiedNames: true, useAliasing: true, isolateQueryComponents: false),
      "FROM",
      QueryComponents(tableName)
    ])
        
    if !joins.isEmpty {
      components.append(joins.queryComponents)
    }
        
    if let condition = condition {
      components.append("WHERE")
      components.append(condition.queryComponents)
    }
        
    if !orderBy.isEmpty {
      components.append("ORDER BY")
      components.append(orderBy.queryComponents(mergedByString: ","))
    }
        
    if let limit = limit {
      components.append(limit.queryComponents)
      }
        
    if let offset = offset {
      components.append(offset.queryComponents)
    }
        
    return components
  }
}

public struct Select: SelectQuery {
  public let fields: [DeclaredField]
  public let tableName: String
  public var distinct: Bool = false
  public var condition: Condition?
  public var joins: [Join] = []
  public var offset: Offset?
  public var limit: Limit?
  public var orderBy: [OrderBy] = []
    
  public init(_ fields: [DeclaredField], from tableName: String) {
    self.tableName = tableName
    self.fields = fields
  }
    
  public init(from tableName: String) {
    self.tableName = tableName
    self.fields = []
  }
    
  public init(_ fields: [String], from tableName: String) {
    self.init(fields.map { DeclaredField(name: $0) }, from: tableName)
  }
  
  public func distinct(_ distinct: Bool = true) -> Select {
    var new = self
    
    new.distinct = distinct
    
    return new
  }
    
  public func join(_ tableName: String, using type: [Join.JoinType], leftKey: String, rightKey: String) -> Select {
    var new = self
    
    new.joins.append(Join(tableName, type: type, leftKey: leftKey, rightKey: rightKey))
        
    return new
  }
    
  public func join(_ tableName: String, using type: Join.JoinType, leftKey: String, rightKey: String) -> Select {
    return join(tableName, using: [type], leftKey: leftKey, rightKey: rightKey)
  }
}

public struct ModelSelect<T: Model>: SelectQuery, ModelQuery {
  public typealias ModelType = T
    
  public var tableName: String {
    return T.tableName
  }
    
  public let fields: [DeclaredField]
  public var distinct: Bool = false
  public var condition: Condition?
  public var joins: [Join] = []
  public var offset: Offset?
  public var limit: Limit?
  public var orderBy: [OrderBy] = []

  public func distinct(_ distinct: Bool = true) -> ModelSelect<T> {
    var new = self
    
    new.distinct = distinct
    
    return new
  }
  
  public func join<R: Model>(_ model: R.Type, using type: [Join.JoinType], leftKey: ModelType.Field, rightKey: R.Field) -> ModelSelect<T> {
    var new = self
    
    new.joins.append(
      Join(R.tableName, type: type, leftKey: ModelType.field(leftKey).qualifiedName, rightKey: R.field(rightKey).qualifiedName)
    )
        
    return new
  }
    
  public func join<R: Model>(_ model: R.Type, using type: Join.JoinType, leftKey: ModelType.Field, rightKey: R.Field) -> ModelSelect<T> {
    return join(model, using: [type], leftKey: leftKey, rightKey: rightKey)
  }

  public init(_ fields: [DeclaredField]? = nil) {
    self.fields = fields ?? T.selectFields.map { T.field($0) }
  }
}
