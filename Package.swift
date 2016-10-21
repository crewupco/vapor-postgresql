import PackageDescription

let package = Package(
	name: "VaporPostgreSQL",
	dependencies: [
		.Package(url: "https://github.com/vapor/cpostgresql.git", majorVersion: 1)
	]
)
