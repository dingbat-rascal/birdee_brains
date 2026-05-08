local M = {}

function M.setup_keymaps(buf, win, engine, dict_a, dict_b, settings, on_next_round)
    -- Restore prompt if edited (speedrun mode)
    vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP" }, {
        buffer = buf,
        callback = function()
            local line = vim.api.nvim_get_current_line()
            if not line:match("^ > ") then
                local cursor = vim.api.nvim_win_get_cursor(0)
                local fixed_line = " > " .. line:gsub("^%s*>?%s*", "")
                vim.api.nvim_set_current_line(fixed_line)
                vim.api.nvim_win_set_cursor(0, { cursor[1], math.max(3, cursor[2]) })
            end
        end
    })

    -- Protect the prompt from being removed (backspace)
    vim.keymap.set('i', '<BS>', function()
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        if col <= 3 or #line <= 3 then
            return ""
        end
        return "<BS>"
    end, { expr = true, buffer = buf })

    -- Panic button - clear input and refresh
    vim.keymap.set({ 'n', 'i' }, 'dd', function()
        on_next_round()
        if settings.game_mode == "speedrun" then
            vim.cmd("startinsert!")
        end
    end, { buffer = buf, desc = "Clear input and refresh" })

    -- Escape to quit game
    vim.keymap.set('n', '<esc>', '<cmd>q!<cr>', { buffer = buf, silent = true })
    vim.keymap.set('i', '<esc>', '<cmd>q!<cr>', { buffer = buf, silent = true })

    -- Quit with 'q'
    vim.keymap.set('n', 'q', '<cmd>q!<CR>', { buffer = buf })
end

function M.setup_speedrun_input(buf, engine, dict_a, dict_b, settings, ns_id, speedrun_prompt_line, on_next_round)
    vim.keymap.set('i', '<CR>', function()
        local line = vim.api.nvim_get_current_line()
        local input = vim.trim((line:match(">%s*(.*)") or ""):lower())
        local is_correct = (input == dict_b[engine.target_idx]:lower())

        -- Highlight the input line
        vim.api.nvim_buf_set_extmark(buf, ns_id, speedrun_prompt_line, 0, {
            end_row = speedrun_prompt_line + 1,
            hl_group = is_correct and "GameCorrect" or "GameWrong",
            hl_eol = true,
        })

        if is_correct then
            engine:record_correct(engine.target_idx)
            vim.defer_fn(function()
                if buf and vim.api.nvim_buf_is_valid(buf) then
                    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
                    on_next_round()
                end
            end, 200)
        else
            engine:record_wrong(engine.target_idx)
            vim.defer_fn(function()
                if buf and vim.api.nvim_buf_is_valid(buf) then
                    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
                    on_next_round()
                end
            end, 200)
        end
    end, { buffer = buf })
end

function M.setup_multiple_choice_input(buf, engine, dict_b, settings, ns_id, choice_start_line, choices, on_next_round)
    local keys = { "j", "k", "l", ";" }
    for i, key in ipairs(keys) do
        vim.keymap.set({ 'n', 'i' }, key, function()
            local is_correct = (choices[i] == dict_b[engine.target_idx])
            local line_num = choice_start_line + i - 1

            vim.api.nvim_buf_set_extmark(buf, ns_id, line_num, 0, {
                end_row = line_num + 1,
                hl_group = is_correct and "GameCorrect" or "GameWrong",
                hl_eol = true,
            })

            if is_correct then
                engine:record_correct(engine.target_idx)
            else
                engine:record_wrong(engine.target_idx)
                if settings.reveal_correct == true then
                    for j, c in ipairs(choices) do
                        if c == dict_b[engine.target_idx] then
                            vim.api.nvim_buf_set_extmark(buf, ns_id, choice_start_line + j - 1, 0, {
                                end_row = choice_start_line + j,
                                hl_group = "GameCorrect",
                                hl_eol = true,
                            })
                        end
                    end
                end
            end

            vim.defer_fn(function()
                if buf and vim.api.nvim_buf_is_valid(buf) then
                    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
                    on_next_round()
                end
            end, 600)
        end, { buffer = buf, silent = true, nowait = true })
    end
end

return M
