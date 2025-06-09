---@diagnostic disable: undefined-global, lowercase-global
package = "ezml"
version = "0.0-1"

source = {
	url = ".",
}

dependencies = {
	"lua >= 5.2",
	"lpeg >= 1.0",
	"inspect >= 3.1.0",
}

build = {
	type = "none",
}
