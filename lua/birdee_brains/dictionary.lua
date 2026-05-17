local M = {}
local csv_loader = require("birdee_brains.csv_loader")

-- Detect if CSV is in multiple-choice format and count answer columns
local function detect_multiple_choice_format(headers)
    local has_correct = false
    local answer_columns = {}
    
    for _, header in ipairs(headers) do
        if header == "Correct" then 
            has_correct = true 
        end
        -- Match "Answer A", "Answer B", etc.
        local letter = header:match("^Answer ([A-Z])$")
        if letter then
            table.insert(answer_columns, letter)
        end
    end
    
    -- Need at least 2 answer columns and a Correct column
    if has_correct and #answer_columns >= 2 then
        return true, answer_columns
    end
    
    return false, {}
end

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

    -- Check if this is a multiple-choice format CSV
    local is_mc, answer_letters = detect_multiple_choice_format(headers)
    if is_mc then
        -- Extract questions
        local questions = csv_loader.extract_column(data, "Question")
        
        -- Build correct answers by looking up the letter in the Correct column
        local answers = {}
        local correct_col = csv_loader.extract_column(data, "Correct")
        
        for i, row in ipairs(data) do
            local correct_letter = correct_col[i]
            local answer_column_name = "Answer " .. correct_letter
            local correct_answer = row[answer_column_name]
            
            if not correct_answer then
                error("Row " .. i .. ": Correct column says '" .. correct_letter .. 
                      "' but 'Answer " .. correct_letter .. "' column not found or empty")
            end
            
            table.insert(answers, correct_answer)
        end
        
        -- Detect optional columns that might be useful later
        local optional_columns = {}
        for _, header in ipairs(headers) do
            if header == "Explanation" or header == "Phonetic" or header == "Pronunciation" then
                optional_columns[header] = true
            end
        end
        
        return questions, answers, {
            data = data,  -- Full row data for accessing any column
            headers = headers,
            question_column = "Question",
            answer_column = "Correct",
            is_multiple_choice = true,
            answer_letters = answer_letters,
            optional_columns = optional_columns,  -- Track which optional columns exist
        }
    end

    -- Default to first and second columns if not specified (original behavior)
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

    -- Detect optional columns for 2-column format too
    local optional_columns = {}
    for _, header in ipairs(headers) do
        if header == "Explanation" or header == "Phonetic" or header == "Pronunciation" then
            optional_columns[header] = true
        end
    end

    return questions, answers, {
        data = data,  -- Full row data for accessing any column
        headers = headers,
        question_column = question_column,
        answer_column = answer_column,
        optional_columns = optional_columns,  -- Track which optional columns exist
    }
end

return M
