local M = {}

---------------------------------------------------------
-- SETTINGS SECTION
---------------------------------------------------------
local SETTINGS = {
    -- You can also point both bird_dir to the same ex (english, and english) to get a typing trainer.
    bird_a         = "spanish",
    bird_b         = "english",
    course_number  = 1,

    game_mode      = "multiple_choice",
    -- options "speedrun" or multiple_choice
    reveal_correct = true,
    reinforce      = true, -- reinforce things you get wrong

    input_keymap   = "german-qwertz",

    -- empty "" for english or view available with
    -- :echo globpath(&rtp, "keymap/*.vim")
    -- stored default list in available
    -- or you can use custom ones from ./nvim/keymap/example.vim dir
    -- you dont need full path just example.vim
}
local MISTAKE_BUCKET = {}

-- Path helper
local function load_dictionary(bird, num)
    local relative_path = string.format("lua/birdee_brains/%s/%s%d.lua", bird, bird, num)
    local files = vim.api.nvim_get_runtime_file(relative_path, false)

    if #files == 0 then
        error("Dictionary not found: " .. relative_path)
    end
    return dofile(files[1])
    -- return vim.api.nvim_get_runtime_file("lua/translator/" .. file, false)[1]
end

function M.setup(opts)
    vim.keymap.set('n', '<C-g>', M.launch, { silent = true, desc = "Start Game"})
    M.SETTINGS = vim.tbl_deep_extend("force", SETTINGS, opts or {})
end

function M.launch()
    -- local config = M.SETTINGS or SETTINGS
    -- Load Display
    local next_round --
    local target_idx = 1
    local correct = 0
    local wrong = 0
    local streak = 0
    local max_streak = 0

    local choice_start_line = 0

    local dict_a = (load_dictionary(SETTINGS.bird_a, SETTINGS.course_number))
    local dict_b = (load_dictionary(SETTINGS.bird_b, SETTINGS.course_number))



    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = 45,
        height = 12,
        col = (vim.o.columns - 50) / 2,
        row = (vim.o.lines - 12) / 2,
        style = 'minimal',
        border = 'rounded'
    })
    local ns_id = vim.api.nvim_create_namespace("game_feedback")

    -- vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })

    vim.api.nvim_buf_call(buf, function()
        -- only load keymap for speecrun

        if SETTINGS.game_mode == "speedrun" and SETTINGS.input_keymap ~= "" then
            vim.cmd("setlocal keymap=" .. SETTINGS.input_keymap)
            vim.cmd("setlocal iminsert=1")
        else
            vim.cmd("setlocal keymap=")
            vim.cmd("setlocal iminsert=0")
        end
    end)

    -- ==========================================================================
    -- 2. UI RENDERERS
    -- ==========================================================================
    vim.api.nvim_set_hl(0, "GameCorrect", { fg = "#000000", bg = "#98be65", bold = true })
    vim.api.nvim_set_hl(0, "GameWrong", { fg = "#ffffff", bg = "#ff6c6b", bold = true })

    local speedrun_prompt_line = 0
    local function render_ui_speedrun()
        local total = correct + wrong
        local accuracy = total > 0 and (correct / total * 100) or 0
        local lines = {
            " --- TRANSLATION GAME --- ",
            string.format(" Correct:  %d", correct),
            string.format(" Wrong:    %d", wrong),
            string.format(" Accuracy: %.1f%%", accuracy),
            string.format(" Streak:   %d", streak),
            string.format(" Best:     %d", max_streak),
            " Review: " .. #MISTAKE_BUCKET,
            "",
            " TRANSLATE: " .. dict_a[target_idx],
            "",
            " > "
        }
        speedrun_prompt_line = #lines - 1
        vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_win_set_cursor(win, { #lines, 4 })
        vim.cmd("startinsert!")
    end

    local function render_multi_choice_ui(question, choices)
        local total = correct + wrong
        local accuracy = total > 0 and (correct / total * 100) or 0
        local lines = {
            "  SELECT THE CORRECT TRANSLATION",
            "  " .. string.rep("━", 22),
            string.format("  Acc: %.1f%% | Streak: %d | Correct: %d | Wrong: %d", accuracy, streak, correct, wrong),
            "",
            "  Question: " .. question,
            "",
            " Review: " .. #MISTAKE_BUCKET,
        }
        choice_start_line = #lines
        local keys = { "j", "k", "l", ";", }
        for i, choice in ipairs(choices) do
            table.insert(lines, string.format("  [%s] %s", keys[i], choice))
        end

        table.insert(lines, "")
        table.insert(lines, "  [jkl;] Select | [Q] Quit")

        vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    end

    local function render_ui()
        -- TODO: nest and organize functions.
        -- local lines = {
        --     " Mistakes to Review: " .. #MISTAKE_BUCKET,
        -- }
        if SETTINGS.game_mode == "multiple_choice" then
            -- multiple choice is handled by nextround() this is here for panic reset "dd"
            next_round()
        else
            render_ui_speedrun()
        end
    end

    -- ==========================================================================
    -- 3. GAME ENGINE
    -- ==========================================================================
    local function bucketcheck(status, idx)
        if SETTINGS.reinforce == true then
            if status == "correct" then
                for i, v in ipairs(MISTAKE_BUCKET) do
                    if v == idx then
                        table.remove(MISTAKE_BUCKET, i)
                        break
                    end
                end
            else
                local already_in = false
                for _, v in ipairs(MISTAKE_BUCKET) do
                    if v == idx then
                        already_in = true
                        break
                    end
                end
                if not already_in then
                    table.insert(MISTAKE_BUCKET, idx)
                end
            end
        end
    end


    function next_round()
        if SETTINGS.reinforce == false then
            target_idx = math.random(1, #dict_a)
        else
            if #MISTAKE_BUCKET > 0 and math.random() > 0.3 then
                local bucket_pos = math.random(1, #MISTAKE_BUCKET)
                target_idx = MISTAKE_BUCKET[bucket_pos]
                -- remove from buckeet once picked so its not a loop
                -- or keep it until they get it right
            else
                target_idx = math.random(1, #dict_a)
            end
        end

        if SETTINGS.game_mode == "multiple_choice" then
            -- Generate choices
            local choices = { dict_b[target_idx] }
            while #choices < 4 do
                local r = math.random(1, #dict_b)
                if dict_b[r] ~= dict_b[target_idx] then
                    local exists = false
                    for _, v in ipairs(choices) do if v == dict_b[r] then exists = true end end
                    if not exists then table.insert(choices, dict_b[r]) end
                end
            end
            -- Shuffle
            for i = #choices, 2, -1 do
                local j = math.random(i)
                choices[i], choices[j] = choices[j], choices[i]
            end

            render_multi_choice_ui(dict_a[target_idx], choices)

            -- Key handling for Multiple Choice
            -- 3. Home-Row Keymaps (j=1, k=2, l=3, ;=4)
            local keys = { "j", "k", "l", ";" }
            for i, key in ipairs(keys) do
                vim.keymap.set({ 'n', 'i' }, key, function()
                    local is_correct = (choices[i] == dict_b[target_idx])
                    -- Apply Highlighting
                    local line_num = choice_start_line + i - 1

                    vim.api.nvim_buf_set_extmark(buf, ns_id, line_num, 0, {
                        end_row = line_num + 1,
                        hl_group = is_correct and "GameCorrect" or "GameWrong",
                        hl_eol = true,
                    })


                    if is_correct then
                        correct = correct + 1
                        streak = streak + 1
                        max_streak = math.max(streak, max_streak)
                        bucketcheck("correct", target_idx)
                    else
                        wrong = wrong + 1
                        streak = 0
                        bucketcheck("wrong", target_idx)
                        if SETTINGS.reveal_correct == true then
                            for j, c in ipairs(choices) do
                                if c == dict_b[target_idx] then
                                    vim.api.nvim_buf_set_extmark(buf, ns_id, 6 + j, 0, {
                                        end_row = 5 + j + 1,
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
                            next_round()
                        end
                    end, 600)
                end, { buffer = buf, silent = true, nowait = true })
            end
        else
            render_ui_speedrun()
        end
    end

    -- ==========================================================================
    -- 4. GAME INPUT
    -- ==========================================================================
    _G.CheckGameInput = function()
        local line = vim.api.nvim_get_current_line()
        local input = vim.trim((line:match(">%s*(.*)") or ""):lower())
        local is_correct = (input == dict_b[target_idx]:lower())
        local prompt_line = 9

        -- Highlight the input line
        vim.api.nvim_buf_set_extmark(buf, ns_id, speedrun_prompt_line, 0, {
            end_row = speedrun_prompt_line + 1,
            hl_group = is_correct and "GameCorrect" or "GameWrong",
            hl_eol = true,
        })

        -- Check against the same index in the Spanish dictionary
        if input == dict_b[target_idx]:lower() then
            correct, streak = correct + 1, streak + 1
            max_streak = math.max(streak, max_streak)
            bucketcheck("correct", target_idx)

            vim.defer_fn(function()
                if buf and vim.api.nvim_buf_is_valid(buf) then
                    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
                    next_round()
                end
            end, 200)
        else
            wrong, streak = wrong + 1, 0
            bucketcheck("wrong", target_idx)
            vim.defer_fn(function()
                if buf and vim.api.nvim_buf_is_valid(buf) then
                    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
                    render_ui_speedrun()
                end
            end, 200)
        end
    end

    -- ==========================================================================
    -- 4. MAPPINGS
    -- ==========================================================================

    -- Restore prompt if edited
    vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP" }, {
        buffer = buf,
        callback = function()
            local line = vim.api.nvim_get_current_line()
            -- If the line doesn't start with our prompt, fix it
            if not line:match("^ > ") then
                local cursor = vim.api.nvim_win_get_cursor(0)
                -- Reset the line to have the prompt + whatever was left of the input
                local fixed_line = " > " .. line:gsub("^%s*>?%s*", "")
                vim.api.nvim_set_current_line(fixed_line)
                -- Keep cursor from jumping to the start
                vim.api.nvim_win_set_cursor(0, { cursor[1], math.max(3, cursor[2]) })
            end
        end
    })

    -- protect the prompt from being removed
    vim.keymap.set('i', '<BS>', function()
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        if col <= 3 or #line <= 3 then
            return ""
        end

        return "<BS>"
    end, { expr = true, buffer = buf })

    -- panic button
    vim.keymap.set({ 'n', 'i', }, 'dd', function()
        render_ui()
        if SETTINGS.game_mode == "speedrun" then vim.cmd("startinsert!") end
    end, { buffer = buf, desc = "Clear input and refresh" })

    -- Escape to quit game
    vim.keymap.set('n', '<esc>', '<cmd>q!<cr>', { buffer = buf, silent = true })
    vim.keymap.set('i', '<esc>', '<cmd>q!<cr>', { buffer = buf, silent = true })

    vim.keymap.set('i', '<CR>', '<cmd>lua _G.CheckGameInput()<CR>', { buffer = buf })
    vim.keymap.set('n', 'q', '<cmd>q!<CR>', { buffer = buf })

    next_round()
end

return M
