local inspect = require("inspect")
local File = require("file")
local Renderer = require("renderer")
local parser = require("parser")

local FILE_PATH = "./sample.ezml"

local COMMAND_SETS = {
	"command_sets.core",
	"command_sets.basic",
	"command_sets.short",
	-- add more module paths here
}

local renderer = Renderer.new(COMMAND_SETS)

local function run_application()
	local file_contents, read_error = File.read_file(FILE_PATH)

	if not file_contents then
		io.stderr:write("Error reading file: " .. read_error .. "\n")
		os.exit(1)
	end

	local ast = parser:parse(file_contents)
	local simplified_ast = parser:parse(file_contents, { simplified = true })

	-- print("Parsed result:")
	-- print(inspect(ast))
	-- print(inspect(simplified_ast))

	local rendered_result = renderer:render_html(ast)

	-- print("Rendered result:")
	print(inspect(rendered_result))

	local file = io.open("output.html", "w")
	if file then
		file:write(rendered_result)
		file:close()
	else
		error("Could not write to file.")
	end
end

run_application()
