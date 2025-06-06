-- utils/file.lua
-- Utility module for reading files

local File = {}

--- Reads the entire contents of a text file.
-- @param path string: Path to the file.
-- @return string|nil: File contents, or nil on error.
-- @return string|nil: Error message if reading failed.
function File.read_file(path)
    assert(type(path) == "string", "Expected file path to be a string")

    local file_handle, error_message = io.open(path, "r")
    if not file_handle then
        return nil, "Could not open file: " .. error_message
    end

    local file_contents = file_handle:read("*a")
    file_handle:close()

    return file_contents
end

return File
