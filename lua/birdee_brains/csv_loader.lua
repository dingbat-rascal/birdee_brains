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
    local file = io.open(filepath, "r")
    if not file then
        error("Could not open CSV file: " .. filepath)
    end

    local lines = {}
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()

    if #lines == 0 then
        error("CSV file is empty: " .. filepath)
    end

    -- Parse header
    local headers = parse_csv_line(lines[1])

    -- Parse data rows
    local data = {}
    for i = 2, #lines do
        if lines[i]:match("%S") then -- Skip empty lines
            local fields = parse_csv_line(lines[i])
            local row = {}
            for j, header in ipairs(headers) do
                row[header] = fields[j] or ""
            end
            table.insert(data, row)
        end
    end

    return data, headers
end

-- Extract a single column from the data as an array
function M.extract_column(data, column_name)
    local result = {}
    for _, row in ipairs(data) do
        table.insert(result, row[column_name] or "")
    end
    return result
end

return M
