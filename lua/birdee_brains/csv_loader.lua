local M = {}

-- Module configuration
local config = {
    debug = false
}

-- Setup function to sync configuration
function M.setup(user_config)
    if user_config then
        config = vim.tbl_deep_extend("force", config, user_config)
    end
end

-- Debug print function - only prints if debug is enabled
local function dprint(...)
    if config.debug then
        print(...)
    end
end

-- Parse a CSV line, handling quoted fields
local function parse_csv_line(line)
    local fields = {}
    local field = ""
    local in_quotes = false
    local i = 1

    while i <= #line do
        local char = line:sub(i, i)

        if char == '"' then
            if in_quotes and i < #line and line:sub(i + 1, i + 1) == '"' then
                -- Escaped quote
                field = field .. '"'
                i = i + 1
            else
                -- Toggle quote state
                in_quotes = not in_quotes
            end
        elseif char == ',' and not in_quotes then
            -- End of field
            table.insert(fields, field)
            field = ""
        else
            field = field .. char
        end

        i = i + 1
    end

    -- Add the last field
    table.insert(fields, field)

    return fields
end

-- Load CSV file and return data as array of row objects + headers
function M.load_csv(filepath)
    -- Check if file exists
    local file = io.open(filepath, "r")
    if not file then
        return {}, {}, "Could not open CSV file: " .. filepath
    end

    local lines = {}
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()

    if #lines == 0 then
        return {}, {}, "CSV file is empty: " .. filepath
    end

    -- Parse header (first line)
    local headers = parse_csv_line(lines[1])

    if #headers == 0 then
        return {}, {}, "CSV file has no headers: " .. filepath
    end

    -- Extract filename without extension for ID generation
    -- Handle filenames with multiple dots by taking everything before the first dot
    local filename = filepath:match("([^/]+)$") or "unknown"
    filename = filename:match("^([^%.]+)") or filename

    -- Parse data rows
    local data = {}
    local row_number = 0
    for i = 2, #lines do
        local line = lines[i]
        -- Skip empty lines (lines with only whitespace or no content)
        if line and line:match("%S") then
            local fields = parse_csv_line(line)

            -- Only process rows that have at least one non-empty field
            local has_content = false
            for _, field in ipairs(fields) do
                if field and field:match("%S") then
                    has_content = true
                    break
                end
            end

            if has_content then
                row_number = row_number + 1
                local row = {}

                -- Generate automatic ID
                row.id = filename .. "_" .. row_number

                -- Populate row with CSV data
                for j, header in ipairs(headers) do
                    row[header] = fields[j] or ""
                end

                table.insert(data, row)
            end
        end
    end

    return data, headers, nil
end

-- Extract a single column from the data as an array
function M.extract_column(data, column_name)
    local result = {}
    for _, row in ipairs(data) do
        table.insert(result, row[column_name] or "")
    end
    return result
end

-- Check if a directory exists using Neovim API
local function directory_exists(path)
    if not path or path == "" then
        return false
    end
    local stat = vim.loop.fs_stat(path)
    return stat and stat.type == "directory"
end

-- Scan a directory for CSV files and return a list of filenames
function M.scan_csv_files(directory)
    local cwd = vim.fn.getcwd()
    dprint("DEBUG: Current working directory: " .. cwd)

    -- Build search paths in priority order
    local search_paths = {}
    
    -- 1. User-provided override directory (highest priority)
    if directory and directory ~= "" then
        table.insert(search_paths, directory)
    end
    
    -- 2. Neovim runtime path (plugin's own data folder)
    local runtime_paths = vim.api.nvim_get_runtime_file("lua/birdee_brains/data/", false)
    if runtime_paths and #runtime_paths > 0 then
        table.insert(search_paths, runtime_paths[1])
    end
    
    -- 3. Fallback to local development path
    table.insert(search_paths, "./data/")

    -- Find the first valid directory
    local found_dir = nil
    for _, path in ipairs(search_paths) do
        if directory_exists(path) then
            found_dir = path
            break
        end
    end

    if not found_dir then
        dprint("DEBUG: Searched paths: " .. table.concat(search_paths, ", "))
        dprint("DEBUG: No valid data directory found")
        return {}, nil
    end

    dprint("DEBUG: Final path being used: " .. found_dir)

    -- Use Neovim's globpath to find CSV files (cross-platform)
    local csv_pattern = found_dir .. "/*.csv"
    local file_paths = vim.fn.glob(csv_pattern, false, true)

    local files = {}
    for _, filepath in ipairs(file_paths) do
        -- Extract just the filename from the full path
        local filename = filepath:match("([^/]+)$")
        if filename then
            table.insert(files, filename)
        end
    end

    if #files > 0 then
        dprint("DEBUG: Found CSV files: " .. table.concat(files, ", "))
    else
        dprint("DEBUG: No CSV files found in " .. found_dir)
    end

    return files, found_dir
end

-- Get lesson name from CSV filename (removes .csv extension, case-insensitive)
function M.get_lesson_name(filename)
    return filename:gsub("%.csv$", ""):gsub("%.CSV$", "")
end

return M
