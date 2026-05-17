local M = {}
local csv_loader = require("birdee_brains.csv_loader")

-- Detect if CSV is in multiple-choice format based on settings
local function detect_multiple_choice_format(headers, settings)
    -- If user explicitly configured multiple choice columns, use those
    if settings.choice_columns and settings.correct_column then
        local has_correct = false
        local choice_cols_exist = true
        
        for _, header in ipairs(headers) do
            if header == settings.correct_column then
                has_correct = true
            end
        end
        
        for _, col in ipairs(settings.choice_columns) do
            local found = false
            for _, header in ipairs(headers) do
                if header == col then
                    found = true
                    break
                end
            end
            if not found then
                choice_cols_exist = false
                break
            end
        end
        
        if has_correct and choice_cols_exist then
            return true, settings.choice_columns
        end
    end
    
    -- Otherwise try to auto-detect standard format: "Answer A", "Answer B", etc. with "Correct"
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
    local is_mc, choice_info = detect_multiple_choice_format(headers, settings)
    if is_mc then
        -- Determine question column (user-specified or default to "Question")
        local question_col = settings.question_column or "Question"
        
        -- Validate question column exists
        local has_question = false
        for _, header in ipairs(headers) do
            if header == question_col then
                has_question = true
                break
            end
        end
        
        if not has_question then
            error("Question column '" .. question_col .. "' not found in CSV. Available columns: " .. table.concat(headers, ", "))
        end
        
        -- Extract questions
        local questions = csv_loader.extract_column(data, question_col)
        
        -- Determine correct answer column (user-specified or default to "Correct")
        local correct_col_name = settings.correct_column or "Correct"
        
        -- Build correct answers by looking up the indicator in the Correct column
        local answers = {}
        local correct_col = csv_loader.extract_column(data, correct_col_name)
        
        -- Determine if we're using letter-based (A, B, C) or column name based lookup
        local use_letter_format = type(choice_info[1]) == "string" and #choice_info[1] == 1
        
        for i, row in ipairs(data) do
            local correct_indicator = correct_col[i]
            local answer_column_name
            
            if use_letter_format then
                -- Standard format: "Answer A", "Answer B", etc.
                answer_column_name = "Answer " .. correct_indicator
            else
                -- Custom format: correct_indicator is the actual column name
                answer_column_name = correct_indicator
            end
            
            local correct_answer = row[answer_column_name]
            
            if not correct_answer then
                error("Row " .. i .. ": Correct column says '" .. correct_indicator .. 
                      "' but column '" .. answer_column_name .. "' not found or empty")
            end
            
            table.insert(answers, correct_answer)
        end
        
        return questions, answers, {
            data = data,  -- Full row data for accessing any column
            headers = headers,
            question_column = question_col,
            answer_column = correct_col_name,
            is_multiple_choice = true,
            choice_columns = choice_info,
            choice_format = use_letter_format and "letter" or "column",
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

    return questions, answers, {
        data = data,  -- Full row data for accessing any column
        headers = headers,
        question_column = question_column,
        answer_column = answer_column,
    }
end

return M
