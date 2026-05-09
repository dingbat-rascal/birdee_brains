local M = {}

-- ============================================================================
-- Requires
-- ============================================================================

local settings_module = require("birdee_brains.settings")
local dictionary_module = require("birdee_brains.dictionary")
local game_engine_module = require("birdee_brains.game_engine")
local ui_module = require("birdee_brains.ui")
local keymaps_module = require("birdee_brains.keymaps")
local csv_loader = require("birdee_brains.csv_loader")

-- ============================================================================
-- Local State
-- ============================================================================

M.SETTINGS = {}

-- ============================================================================
-- Helper Functions
-- ============================================================================

--- Show lesson selection menu
--- @param lessons table Array of lesson names
--- @param callback function Callback function when lesson is selected
local function show_lesson_menu(lessons, callback)
    if not lessons or #lessons == 0 then
        vim.notify("No lessons available", vim.log.levels.ERROR)
        return
    end
    local buf = vim.api.nvim_create_buf(false, true)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        vim.notify("Failed to create menu buffer", vim.log.levels.ERROR)
        return
    end

    local width = 50
    local height = math.min(#lessons + 6, 20)
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
    
    if not win or not vim.api.nvim_win_is_valid(win) then
        vim.notify("Failed to create menu window", vim.log.levels.ERROR)
        return
    end

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
    
    -- Setup keymaps for selection (only for lessons 1-9)
    for i, lesson in ipairs(lessons) do
        if i <= 9 then
            vim.keymap.set('n', tostring(i), function()
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_close(win, true)
                end
                callback(lesson)
            end, { buffer = buf, silent = true })
        end
    end
    
    vim.keymap.set('n', 'q', function()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end, { buffer = buf, silent = true })
    
    vim.keymap.set('n', '<Esc>', function()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end, { buffer = buf, silent = true })
end

-- ============================================================================
-- Public API
-- ============================================================================

--- Launch the game with lesson selection
function M.launch()
    -- Guard clause: check if settings are initialized
    if not M.SETTINGS or not M.SETTINGS.data_directory then
        vim.notify("Plugin not initialized. Call setup() first.", vim.log.levels.ERROR)
        return
    end

    local SETTINGS = M.SETTINGS
    
    -- Scan for available lessons
    local csv_files, found_dir = csv_loader.scan_csv_files(SETTINGS.data_directory)
    
    -- Guard clause: no CSV files found
    if not csv_files or #csv_files == 0 then
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
    
    -- If CSV file is already declared in settings, resolve and start game directly
    if SETTINGS.csv_file and SETTINGS.csv_file ~= "" then
        -- Check if it's already a full path
        if SETTINGS.csv_file:match("^/") or SETTINGS.csv_file:match("^%a:") then
            -- Already a full path, use as-is
            M.start_game(SETTINGS)
        else
            -- Relative path or just filename, resolve it
            local csv_path = SETTINGS.csv_file
            -- Add .csv extension if missing
            if not csv_path:match("%.csv$") then
                csv_path = csv_path .. ".csv"
            end
            -- Prepend data directory if not already included
            if not csv_path:match("^" .. vim.pesc(data_dir)) then
                csv_path = data_dir .. csv_path
            end
            SETTINGS.csv_file = csv_path
            M.start_game(SETTINGS)
        end
        return
    end
    
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
        if not selected_lesson then
            return
        end

        -- Find the corresponding CSV file
        for _, filename in ipairs(csv_files) do
            if csv_loader.get_lesson_name(filename) == selected_lesson then
                SETTINGS.csv_file = data_dir .. filename
                M.start_game(SETTINGS)
                return
            end
        end
        
        vim.notify("Could not find lesson file", vim.log.levels.ERROR)
    end)
end

--- Start the game with the given settings
--- @param SETTINGS table Game settings
function M.start_game(SETTINGS)
    -- Guard clause: validate settings
    if not SETTINGS or not SETTINGS.csv_file then
        vim.notify("Invalid settings or missing CSV file", vim.log.levels.ERROR)
        return
    end

    -- Load dictionaries from CSV
    local questions, answers, csv_metadata = dictionary_module.load_dictionary(SETTINGS)

    -- Guard clause: validate loaded data
    if not questions or #questions == 0 then
        vim.notify("Failed to load questions from CSV", vim.log.levels.ERROR)
        return
    end
    if not answers or #answers == 0 then
        vim.notify("Failed to load answers from CSV", vim.log.levels.ERROR)
        return
    end

    -- Create game engine
    local engine = game_engine_module.create_engine(SETTINGS)
    engine.csv_metadata = csv_metadata  -- Store metadata for potential future use

    -- Create buffer and window
    local buf = vim.api.nvim_create_buf(false, true)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        vim.notify("Failed to create game buffer", vim.log.levels.ERROR)
        return
    end
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        width = 45,
        height = 12,
        col = (vim.o.columns - 50) / 2,
        row = (vim.o.lines - 12) / 2,
        style = 'minimal',
        border = 'rounded'
    })

    if not win or not vim.api.nvim_win_is_valid(win) then
        vim.notify("Failed to create game window", vim.log.levels.ERROR)
        return
    end

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
        if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
            return
        end

        engine:select_target(questions)

        local choices = nil
        if SETTINGS.game_mode == "multiple_choice" then
            -- Guard clause: validate target index before generating choices
            if not engine.target_idx or not answers[engine.target_idx] then
                vim.notify("Invalid target index", vim.log.levels.ERROR)
                return
            end

            choices = engine:generate_choices(answers, answers[engine.target_idx])
            
            -- Guard clause: ensure choices were generated
            if not choices or type(choices) ~= "table" then
                vim.notify("Failed to generate choices", vim.log.levels.ERROR)
                return
            end
            
            -- Force exactly 4 choices - create new table to avoid reference issues
            local safe_choices = {}
            for i = 1, 4 do
                safe_choices[i] = choices[i] or ""
            end

            -- Store choices in engine state for keymap access
            engine.current_choices = safe_choices
            choices = safe_choices
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

-- ============================================================================
-- Setup
-- ============================================================================

--- Setup the plugin with user configuration
--- @param opts table|nil User configuration options
function M.setup(opts)
    -- Merge user config with defaults
    M.SETTINGS = vim.tbl_deep_extend("force", settings_module.DEFAULTS, opts or {})
    
    -- Setup csv_loader with configuration
    csv_loader.setup(M.SETTINGS)
    
    -- Setup global keymap to launch game
    vim.keymap.set('n', '<C-g>', M.launch, { silent = true, desc = "Start Game" })
end

return M
