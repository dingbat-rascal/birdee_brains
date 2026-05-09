local M = {}

-- ============================================================================
-- Helper Functions
-- ============================================================================

--- Validate engine data to prevent nil access
--- @param engine table The game engine
--- @return boolean valid True if engine has required fields
local function validate_engine(engine)
    if not engine then
        return false
    end
    if type(engine.correct) ~= "number" then
        return false
    end
    if type(engine.wrong) ~= "number" then
        return false
    end
    if type(engine.streak) ~= "number" then
        return false
    end
    if type(engine.max_streak) ~= "number" then
        return false
    end
    if type(engine.target_idx) ~= "number" then
        return false
    end
    if type(engine.mistake_bucket) ~= "table" then
        return false
    end
    return true
end

--- Validate dictionary data
--- @param dict table The dictionary array
--- @param idx number The target index
--- @return boolean valid True if dictionary and index are valid
local function validate_dict(dict, idx)
    if not dict or type(dict) ~= "table" then
        return false
    end
    if not idx or idx < 1 or idx > #dict then
        return false
    end
    return true
end

-- ============================================================================
-- Public API
-- ============================================================================

--- Setup highlight groups for game feedback
function M.setup_highlights()
    vim.api.nvim_set_hl(0, "GameCorrect", { fg = "#000000", bg = "#98be65", bold = true })
    vim.api.nvim_set_hl(0, "GameWrong", { fg = "#ffffff", bg = "#ff6c6b", bold = true })
end

--- Build layout for the game UI
--- @param engine table The game engine
--- @param dict_a table The questions dictionary
--- @param choices table|nil The answer choices (for multiple choice mode)
--- @param game_mode string The game mode ("speedrun" or "multiple_choice")
--- @return table layout The layout structure with lines and metadata
function M.build_layout(engine, dict_a, choices, game_mode)
    -- Guard clause: validate engine
    if not validate_engine(engine) then
        return {
            lines = { "ERROR: Invalid game engine" },
            input_line = nil,
            choice_start_line = nil,
        }
    end

    -- Guard clause: validate dictionary
    if not validate_dict(dict_a, engine.target_idx) then
        return {
            lines = { "ERROR: Invalid dictionary data" },
            input_line = nil,
            choice_start_line = nil,
        }
    end

    -- Get engine method safely
    local get_accuracy = engine.get_accuracy
    if type(get_accuracy) ~= "function" then
        return {
            lines = { "ERROR: Engine missing get_accuracy method" },
            input_line = nil,
            choice_start_line = nil,
        }
    end
    local accuracy = get_accuracy(engine)
    local question_text = dict_a[engine.target_idx] or "No question"
    local mistake_count = #engine.mistake_bucket

    local layout = {
        lines = {},
        input_line = nil,
        choice_start_line = nil,
    }

    if game_mode == "speedrun" then
        layout.lines = {
            " --- TRANSLATION GAME --- ",
            string.format(" Correct:  %d", engine.correct),
            string.format(" Wrong:    %d", engine.wrong),
            string.format(" Accuracy: %.1f%%", accuracy),
            string.format(" Streak:   %d", engine.streak),
            string.format(" Best:     %d", engine.max_streak),
            string.format(" Review: %d", mistake_count),
            "",
            " TRANSLATE: " .. question_text,
            "",
            " > "
        }
        layout.input_line = #layout.lines - 1
    else
        -- Guard clause: validate choices for multiple choice mode
        if not choices or type(choices) ~= "table" then
            choices = { "", "", "", "" }
        end
        
        -- Ensure we always have exactly 4 choices (pad with empty strings if needed)
        -- Use explicit array construction to guarantee 4 elements
        local safe_choices = {
            choices[1] or "",
            choices[2] or "",
            choices[3] or "",
            choices[4] or ""
        }

        layout.lines = {
            "  SELECT THE CORRECT TRANSLATION",
            "  " .. string.rep("━", 22),
            string.format("  Acc: %.1f%% | Streak: %d | Correct: %d | Wrong: %d", 
                accuracy, engine.streak, engine.correct, engine.wrong),
            "",
            "  Question: " .. question_text,
            "",
            string.format(" Review: %d", mistake_count),
        }
        layout.choice_start_line = #layout.lines
        local keys = { "j", "k", "l", ";" }
        -- Always display exactly 4 choices with jkl; keys - use explicit indices
        table.insert(layout.lines, string.format("  [%s] %s", keys[1], safe_choices[1]))
        table.insert(layout.lines, string.format("  [%s] %s", keys[2], safe_choices[2]))
        table.insert(layout.lines, string.format("  [%s] %s", keys[3], safe_choices[3]))
        table.insert(layout.lines, string.format("  [%s] %s", keys[4], safe_choices[4]))
        table.insert(layout.lines, "")
        table.insert(layout.lines, "  [jkl;] Select | [Q] Quit")
    end

    return layout
end

--- Render the layout to the buffer
--- @param buf number The buffer handle
--- @param win number The window handle
--- @param layout table The layout structure
--- @param game_mode string The game mode
function M.render(buf, win, layout, game_mode)
    -- Guard clause: validate buffer
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        return
    end

    -- Guard clause: validate layout
    if not layout or not layout.lines or #layout.lines == 0 then
        return
    end
    vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, layout.lines)
    
    if game_mode == "speedrun" then
        vim.api.nvim_win_set_cursor(win, { #layout.lines, 4 })
        vim.cmd("startinsert!")
    else
        vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    end
end

return M
