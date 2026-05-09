local M = {}

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
    local filename = filepath:match("([^/]+)%.csv$") or filepath:match("([^/]+)$") or "unknown"
    filename = filename:gsub("%.csv$", "")

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

-- Scan a directory for CSV files and return a list of filenames
function M.scan_csv_files(directory)
    local handle = io.popen('ls "' .. directory .. '"*.csv 2>/dev/null')
    if not handle then
        return {}
    end
    
    local result = handle:read("*a")
    handle:close()
    
    local files = {}
    for filename in result:gmatch("[^\n]+") do
        -- Extract just the filename without path
        local basename = filename:match("([^/]+)$")
        if basename and basename:match("%.csv$") then
            table.insert(files, basename)
        end
    end
    
    return files
end

-- Get lesson name from CSV filename (removes .csv extension)
function M.get_lesson_name(filename)
    return filename:gsub("%.csv$", "")
end

return M
