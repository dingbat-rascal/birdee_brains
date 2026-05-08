local M = {}

function M.setup_highlights()
    vim.api.nvim_set_hl(0, "GameCorrect", { fg = "#000000", bg = "#98be65", bold = true })
    vim.api.nvim_set_hl(0, "GameWrong", { fg = "#ffffff", bg = "#ff6c6b", bold = true })
end

function M.render_speedrun(buf, win, engine, dict_a, speedrun_prompt_line)
    local accuracy = engine:get_accuracy()
    local lines = {
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
    speedrun_prompt_line = #lines - 1
    vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(win, { #lines, 4 })
    vim.cmd("startinsert!")
    return speedrun_prompt_line
end

function M.render_multiple_choice(buf, engine, dict_a, choices)
    local accuracy = engine:get_accuracy()
    local lines = {
        "  SELECT THE CORRECT TRANSLATION",
        "  " .. string.rep("━", 22),
        string.format("  Acc: %.1f%% | Streak: %d | Correct: %d | Wrong: %d", accuracy, engine.streak, engine.correct, engine.wrong),
        "",
        "  Question: " .. dict_a[engine.target_idx],
        "",
        " Review: " .. #engine.mistake_bucket,
    }
    local choice_start_line = #lines
    local keys = { "j", "k", "l", ";" }
    for i, choice in ipairs(choices) do
        table.insert(lines, string.format("  [%s] %s", keys[i], choice))
    end

    table.insert(lines, "")
    table.insert(lines, "  [jkl;] Select | [Q] Quit")

    vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    return choice_start_line
end

return M
