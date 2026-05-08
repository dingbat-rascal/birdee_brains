local M = {}

function M.setup_highlights()
    vim.api.nvim_set_hl(0, "GameCorrect", { fg = "#000000", bg = "#98be65", bold = true })
    vim.api.nvim_set_hl(0, "GameWrong", { fg = "#ffffff", bg = "#ff6c6b", bold = true })
end

function M.build_layout(engine, dict_a, choices, game_mode)
    local accuracy = engine:get_accuracy()
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
            " Review: " .. #engine.mistake_bucket,
            "",
            " TRANSLATE: " .. dict_a[engine.target_idx],
            "",
            " > "
        }
        layout.input_line = #layout.lines - 1
    else
        layout.lines = {
            "  SELECT THE CORRECT TRANSLATION",
            "  " .. string.rep("━", 22),
            string.format("  Acc: %.1f%% | Streak: %d | Correct: %d | Wrong: %d", accuracy, engine.streak, engine.correct, engine.wrong),
            "",
            "  Question: " .. dict_a[engine.target_idx],
            "",
            " Review: " .. #engine.mistake_bucket,
        }
        layout.choice_start_line = #layout.lines
        local keys = { "j", "k", "l", ";" }
        for i, choice in ipairs(choices) do
            table.insert(layout.lines, string.format("  [%s] %s", keys[i], choice))
        end
        table.insert(layout.lines, "")
        table.insert(layout.lines, "  [jkl;] Select | [Q] Quit")
    end

    return layout
end

function M.render(buf, win, layout, game_mode)
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
