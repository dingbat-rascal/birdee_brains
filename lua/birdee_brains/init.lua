local M = {}

local settings_module = require("birdee_brains.settings")
local dictionary_module = require("birdee_brains.dictionary")
local game_engine_module = require("birdee_brains.game_engine")
local ui_module = require("birdee_brains.ui")
local keymaps_module = require("birdee_brains.keymaps")

function M.setup(opts)
    vim.keymap.set('n', '<C-g>', M.launch, { silent = true, desc = "Start Game" })
    M.SETTINGS = vim.tbl_deep_extend("force", settings_module.DEFAULTS, opts or {})
end

-- Show lesson selection menu
local function show_lesson_menu(lessons, callback)
    local buf = vim.api.nvim_create_buf(false, true)
    local width = 50
    local height = math.min(#lessons + 4, 20)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = width,
        height = height,
        col = (vim.o.columns - width) / 2,
        row = (vim.o.lines - height) / 2,
        style = 'minimal',
        border = 'rounded',
        title = ' Choose a Lesson ',
        title_pos = 'center'
    })
    
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    
    -- Build menu content
    local lines = { "", "  Select a lesson:", "" }
    for i, lesson in ipairs(lessons) do
        table.insert(lines, string.format("  [%d] %s", i, lesson))
    end
    table.insert(lines, "")
    table.insert(lines, "  Press number to select, 'q' to quit")
    
    vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    
    -- Setup keymaps for selection
    for i, lesson in ipairs(lessons) do
        vim.keymap.set('n', tostring(i), function()
            vim.api.nvim_win_close(win, true)
            callback(lesson)
        end, { buffer = buf, silent = true })
    end
    
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
    
    vim.keymap.set('n', '<Esc>', function()
        vim.api.nvim_win_close(win, true)
    end, { buffer = buf, silent = true })
end

function M.launch()
    local SETTINGS = M.SETTINGS
    local csv_loader = require("birdee_brains.csv_loader")
    
    -- Scan for available lessons
    local csv_files, found_dir = csv_loader.scan_csv_files(SETTINGS.data_directory)
    
    if #csv_files == 0 then
        local error_msg = "No CSV lesson files found"
        if found_dir then
            error_msg = error_msg .. " in " .. found_dir
        else
            error_msg = error_msg .. ". Could not locate data directory."
        end
        vim.notify(error_msg, vim.log.levels.ERROR)
        return
    end
    
    -- Use the found directory for loading files
    local data_dir = found_dir or SETTINGS.data_directory
    
    -- If only one lesson, load it directly
    if #csv_files == 1 then
        SETTINGS.csv_file = data_dir .. csv_files[1]
        M.start_game(SETTINGS)
        return
    end
    
    -- Show lesson selection menu
    local lesson_names = {}
    for _, filename in ipairs(csv_files) do
        table.insert(lesson_names, csv_loader.get_lesson_name(filename))
    end
    
    show_lesson_menu(lesson_names, function(selected_lesson)
        -- Find the corresponding CSV file
        for _, filename in ipairs(csv_files) do
            if csv_loader.get_lesson_name(filename) == selected_lesson then
                SETTINGS.csv_file = data_dir .. filename
                M.start_game(SETTINGS)
                return
            end
        end
    end)
end

function M.start_game(SETTINGS)
    -- Load dictionaries from CSV
    local questions, answers, csv_metadata = dictionary_module.load_dictionary(SETTINGS)

    -- Create game engine
    local engine = game_engine_module.create_engine(SETTINGS)
    engine.csv_metadata = csv_metadata  -- Store metadata for potential future use

    -- Create buffer and window
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

    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })

    vim.api.nvim_buf_call(buf, function()
        -- Disable autocomplete
        vim.cmd("setlocal completeopt=")
        vim.cmd("setlocal completefunc=")
        vim.cmd("setlocal omnifunc=")

        if SETTINGS.game_mode == "speedrun" and SETTINGS.input_keymap ~= "" then
            vim.cmd("setlocal keymap=" .. SETTINGS.input_keymap)
            vim.cmd("setlocal iminsert=1")
        else
            vim.cmd("setlocal keymap=")
            vim.cmd("setlocal iminsert=0")
        end
    end)

    -- Setup UI
    ui_module.setup_highlights()

    -- Next round function
    local function next_round()
        engine:select_target(questions)

        local choices
        if SETTINGS.game_mode == "multiple_choice" then
            choices = engine:generate_choices(answers, answers[engine.target_idx])
            engine.current_choices = choices
        end

        local layout = ui_module.build_layout(engine, questions, choices, SETTINGS.game_mode)
        ui_module.render(buf, win, layout, SETTINGS.game_mode)
    end

    -- Setup keymaps
    keymaps_module.setup_keymaps(buf, win, engine, questions, answers, SETTINGS, next_round)

    -- Setup game-specific input handlers
    if SETTINGS.game_mode == "speedrun" then
        keymaps_module.setup_speedrun_input(buf, engine, questions, answers, SETTINGS, ns_id, next_round)
    else
        keymaps_module.setup_multiple_choice_input(buf, engine, answers, SETTINGS, ns_id, next_round)
    end

    -- Start the game
    next_round()
end

return M
