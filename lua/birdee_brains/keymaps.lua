local M = {}

function M.setup_keymaps(buf, win, engine, dict_a, dict_b, settings, on_next_round)
    local kb = settings.keybinds

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
    vim.keymap.set({ 'n', 'i' }, kb.refresh, function()
        on_next_round()
    end, { buffer = buf, desc = "Clear input and refresh" })

    -- Escape to quit game
    vim.keymap.set('n', kb.escape, '<cmd>q!<cr>', { buffer = buf, silent = true })
    vim.keymap.set('i', kb.escape, '<cmd>q!<cr>', { buffer = buf, silent = true })

    -- Quit with custom key
    vim.keymap.set('n', kb.quit, '<cmd>q!<CR>', { buffer = buf })
end

function M.setup_speedrun_input(buf, engine, dict_a, dict_b, settings, ns_id, on_next_round)
    local kb = settings.keybinds

    vim.keymap.set('i', kb.submit, function()
        local line = vim.api.nvim_get_current_line()
        local input = vim.trim((line:match(">%s*(.*)") or ""):lower())
        local is_correct = (input == dict_b[engine.target_idx]:lower())

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

        vim.defer_fn(function()
            if buf and vim.api.nvim_buf_is_valid(buf) then
                vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
                on_next_round()
            end
        end, 200)
    end, { buffer = buf })
end

function M.setup_multiple_choice_input(buf, engine, dict_b, settings, ns_id, on_next_round)
    local kb = settings.keybinds
    local keys = kb.choice_keys

    for i, key in ipairs(keys) do
        vim.keymap.set({ 'n', 'i' }, key, function()
            local is_correct = (engine.current_choices[i] == dict_b[engine.target_idx])

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
                        if c == dict_b[engine.target_idx] then
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
