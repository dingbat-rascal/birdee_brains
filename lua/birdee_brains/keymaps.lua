local M = {}

-- ============================================================================
-- Helper Functions
-- ============================================================================

--- Validate buffer is valid
--- @param buf number Buffer handle
--- @return boolean valid True if buffer is valid
local function validate_buffer(buf)
    return buf and vim.api.nvim_buf_is_valid(buf)
end

--- Validate window is valid
--- @param win number Window handle
--- @return boolean valid True if window is valid
local function validate_window(win)
    return win and vim.api.nvim_win_is_valid(win)
end

-- ============================================================================
-- Public API
-- ============================================================================

--- Setup common keymaps for the game
--- @param buf number Buffer handle
--- @param win number Window handle
--- @param engine table Game engine
--- @param dict_a table Questions dictionary
--- @param dict_b table Answers dictionary
--- @param settings table Game settings
--- @param on_next_round function Callback for next round
function M.setup_keymaps(buf, win, engine, dict_a, dict_b, settings, on_next_round)
    if not validate_buffer(buf) then
        return
    end
    local kb = settings.keybinds

    -- Restore prompt if edited (speedrun mode only)
    if settings.game_mode == "speedrun" then
        vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP" }, {
            buffer = buf,
            callback = function()
                if not validate_buffer(buf) then
                    return
                end
                local line = vim.api.nvim_get_current_line()
                if not line:match("^ > ") then
                    local cursor = vim.api.nvim_win_get_cursor(0)
                    local fixed_line = " > " .. line:gsub("^%s*>?%s*", "")
                    vim.api.nvim_set_current_line(fixed_line)
                    vim.api.nvim_win_set_cursor(0, { cursor[1], math.max(3, cursor[2]) })
                end
            end
        })
    end

    -- Protect the prompt from being removed (backspace, speedrun mode only)
    if settings.game_mode == "speedrun" then
        vim.keymap.set('i', '<BS>', function()
            local line = vim.api.nvim_get_current_line()
            local col = vim.api.nvim_win_get_cursor(0)[2]
            if col <= 3 or #line <= 3 then
                return ""
            end
            return "<BS>"
        end, { expr = true, buffer = buf })
    end

    -- Panic button - clear input and refresh
    vim.keymap.set({ 'n', 'i' }, kb.refresh, function()
        on_next_round()
    end, { buffer = buf, desc = "Clear input and refresh" })

    -- Escape to quit game
    vim.keymap.set('n', kb.escape, '<cmd>q!<cr>', { buffer = buf, silent = true })
    vim.keymap.set('i', kb.escape, '<cmd>q!<cr>', { buffer = buf, silent = true })

    -- Quit with custom key
    vim.keymap.set('n', kb.quit, '<cmd>q!<CR>', { buffer = buf })
end

--- Setup input handling for speedrun mode
--- @param buf number Buffer handle
--- @param engine table Game engine
--- @param dict_a table Questions dictionary
--- @param dict_b table Answers dictionary
--- @param settings table Game settings
--- @param ns_id number Namespace ID for extmarks
--- @param on_next_round function Callback for next round
function M.setup_speedrun_input(buf, engine, dict_a, dict_b, settings, ns_id, on_next_round)
    if not validate_buffer(buf) then
        return
    end
    local kb = settings.keybinds

    vim.keymap.set('i', kb.submit, function()
        if not validate_buffer(buf) then
            return
        end

        local line = vim.api.nvim_get_current_line()
        local input = vim.trim((line:match(">%s*(.*)") or ""):lower())
        
        -- Guard clause: validate target index
        if not engine.target_idx or not dict_b[engine.target_idx] then
            vim.notify("Invalid target index", vim.log.levels.ERROR)
            return
        end

        local correct_answer = dict_b[engine.target_idx]:lower()
        local is_correct = (input == correct_answer)

        -- Find the input line in the buffer
        local input_line = nil
        for i = 0, vim.api.nvim_buf_line_count(buf) - 1 do
            if vim.api.nvim_buf_get_lines(buf, i, i + 1, false)[1]:match("^ > ") then
                input_line = i
                break
            end
        end

        if input_line then
            vim.api.nvim_buf_set_extmark(buf, ns_id, input_line, 0, {
                end_row = input_line + 1,
                hl_group = is_correct and "GameCorrect" or "GameWrong",
                hl_eol = true,
            })
        end

        if is_correct then
            engine:record_correct(engine.target_idx)
        else
            engine:record_wrong(engine.target_idx)
        end

        local delay = settings.reveal_delay or 2000
        vim.defer_fn(function()
            if buf and vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
                on_next_round()
            end
        end, delay)
    end, { buffer = buf })
end

--- Setup input handling for multiple choice mode
--- @param buf number Buffer handle
--- @param engine table Game engine
--- @param dict_b table Answers dictionary
--- @param settings table Game settings
--- @param ns_id number Namespace ID for extmarks
--- @param on_next_round function Callback for next round
function M.setup_multiple_choice_input(buf, engine, dict_b, settings, ns_id, on_next_round)
    if not validate_buffer(buf) then
        return
    end
    local kb = settings.keybinds
    local keys = kb.choice_keys

    for i, key in ipairs(keys) do
        vim.keymap.set({ 'n', 'i' }, key, function()
            if not validate_buffer(buf) then
                return
            end

            -- Guard clause: validate current_choices
            if not engine.current_choices or #engine.current_choices == 0 then
                vim.notify("No choices available", vim.log.levels.ERROR)
                return
            end

            -- Guard clause: validate target index
            if not engine.target_idx or not dict_b[engine.target_idx] then
                vim.notify("Invalid target index", vim.log.levels.ERROR)
                return
            end

            -- Guard clause: validate choice index
            if not engine.current_choices[i] then
                vim.notify("Invalid choice index", vim.log.levels.ERROR)
                return
            end

            local correct_answer = dict_b[engine.target_idx]
            local is_correct = (engine.current_choices[i] == correct_answer)

            -- Find the choice line in the buffer
            local choice_line = nil
            for line_num = 0, vim.api.nvim_buf_line_count(buf) - 1 do
                local line_text = vim.api.nvim_buf_get_lines(buf, line_num, line_num + 1, false)[1]
                if line_text:match("%[" .. key .. "%]") then
                    choice_line = line_num
                    break
                end
            end

            if choice_line then
                vim.api.nvim_buf_set_extmark(buf, ns_id, choice_line, 0, {
                    end_row = choice_line + 1,
                    hl_group = is_correct and "GameCorrect" or "GameWrong",
                    hl_eol = true,
                })

                if not is_correct and settings.reveal_correct == true then
                    for j, c in ipairs(engine.current_choices) do
                        if c == correct_answer then
                            for line_num = 0, vim.api.nvim_buf_line_count(buf) - 1 do
                                local line_text = vim.api.nvim_buf_get_lines(buf, line_num, line_num + 1, false)[1]
                                local correct_key = keys[j]
                                if line_text:match("%[" .. correct_key .. "%]") then
                                    vim.api.nvim_buf_set_extmark(buf, ns_id, line_num, 0, {
                                        end_row = line_num + 1,
                                        hl_group = "GameCorrect",
                                        hl_eol = true,
                                    })
                                    break
                                end
                            end
                            break
                        end
                    end
                end
            end

            if is_correct then
                engine:record_correct(engine.target_idx)
            else
                engine:record_wrong(engine.target_idx)
            end

            local delay = settings.reveal_delay or 2000
            vim.defer_fn(function()
                if buf and vim.api.nvim_buf_is_valid(buf) then
                    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
                    on_next_round()
                end
            end, delay)
        end, { buffer = buf, silent = true, nowait = true })
    end
end

return M
