local M = {}
local csv_loader = require("birdee_brains.csv_loader")

-- Load CSV-based dictionary and extract question/answer columns
function M.load_dictionary(settings)
    local data, headers = csv_loader.load_csv(settings.csv_file)

    -- Validate columns exist
    local has_question = false
    local has_answer = false
    for _, header in ipairs(headers) do
        if header == settings.question_column then has_question = true end
        if header == settings.answer_column then has_answer = true end
    end

    if not has_question then
        error("Question column '" ..
        settings.question_column .. "' not found in CSV. Available columns: " .. table.concat(headers, ", "))
    end
    if not has_answer then
        error("Answer column '" ..
        settings.answer_column .. "' not found in CSV. Available columns: " .. table.concat(headers, ", "))
    end

    -- Extract the columns as arrays for compatibility with existing game engine
    local questions = csv_loader.extract_column(data, settings.question_column)
    local answers = csv_loader.extract_column(data, settings.answer_column)

    return questions, answers, {
        data = data,
        headers = headers,
        question_column = settings.question_column,
        answer_column = settings.answer_column,
    }
end

return M
