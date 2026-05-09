local M = {}
local csv_loader = require("birdee_brains.csv_loader")

-- Load CSV-based dictionary and extract question/answer columns
function M.load_dictionary(settings)
    local csv_file = settings.csv_file
    
    local data, headers, err = csv_loader.load_csv(csv_file)

    -- Handle loading errors
    if err then
        error("Failed to load CSV file '" .. tostring(csv_file) .. "': " .. err)
    end

    if #data == 0 then
        error("No data rows found in CSV file: " .. tostring(csv_file))
    end

    -- Default to first and second columns if not specified
    local question_column = settings.question_column
    local answer_column = settings.answer_column
    
    if not question_column or question_column == "" then
        if #headers > 0 then
            question_column = headers[1]
        else
            error("No columns found in CSV file: " .. tostring(csv_file))
        end
    end
    
    if not answer_column or answer_column == "" then
        if #headers > 1 then
            answer_column = headers[2]
        else
            error("CSV file must have at least 2 columns: " .. tostring(csv_file))
        end
    end

    -- Validate columns exist
    local has_question = false
    local has_answer = false
    for _, header in ipairs(headers) do
        if header == question_column then has_question = true end
        if header == answer_column then has_answer = true end
    end

    if not has_question then
        error("Question column '" ..
            question_column .. "' not found in CSV. Available columns: " .. table.concat(headers, ", "))
    end
    if not has_answer then
        error("Answer column '" ..
            answer_column .. "' not found in CSV. Available columns: " .. table.concat(headers, ", "))
    end

    -- Extract the columns as arrays for compatibility with existing game engine
    local questions = csv_loader.extract_column(data, question_column)
    local answers = csv_loader.extract_column(data, answer_column)

    return questions, answers, {
        data = data,
        headers = headers,
        question_column = question_column,
        answer_column = answer_column,
    }
end

return M
