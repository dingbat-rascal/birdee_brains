<p align="center">
  <pre>
  _______
 < Hoo! >
  ------\ ,_,
 _       (O,o)    _             
( )    _ {`"'}   ( )            
| |_  (_)_-_-   _| |  __    __  
|  _ \| |  __)/ _  |/ __ \/ __ \  ,_,
| |_) ) | |  ( (_| |  ___/  ___/ {O,o}/)
(_ __/(_)_)   \__ _)\____)\____) /)__)'
   B  R  A  I  N  S               " "
  </pre>
</p>

# Birdee Brains a fully Customizable Quiz Mini Game for Neovim
> Named after wicked smart nix_cats creator Birdee (https://github.com/BirdeeHub)

A quick fun, interactive way to practice flash card style, or multiple choice vocabulary directly inside your editor with vim motions. 
Features multiple-choice and speedrun modes with reinforcement learning for mistakes.
Initially made for language learning and foreign keyboard typing in downtime between master-minding. Behold the ability to communicate. But also made to
be fully customizable for any subject or topic that you need to reinforce.
Sweet tasty delicious strength training for your brain mhmm goooood delicious.
Oh the burn do you feel it, get those neurons fired up and smoking.

Two directories bird_a and bird_b (interchangable answer and key). Simply set both to the same
bird and course/brain If you want to practice your
typing, keybinds (Portuguese dvorak, Swedish colmac/w accents).

## 📦 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
return {
    "dingbat-rascal/birdee_brains",
    keys = {
        { "<C-g>", function () require("birdee_brains").launch() end, desc = "Start Birdee Brains" },
    },
    opts = {
        -- CSV file to load (optional - leave empty to show lesson picker on launch)
        -- Can be just the filename (e.g., "french_verbs") or full path
        -- Set this to skip the lesson menu and load a default lesson automatically
        csv_file = "", -- Leave empty to show lesson selection menu
        
        -- Data directory (optional - auto-detected if not set)
        -- Set this to use a custom directory for your CSV lessons
        -- Examples: "~/my_lessons/", "/path/to/obsidian/vault/flashcards/"
        data_directory = nil, -- Default: plugin's lua/birdee_brains/data/
        
        -- CSV column configuration (optional - defaults to first two columns)
        -- Specify which columns contain questions and answers
        question_column = nil, -- Default: first column (e.g., "en")
        answer_column = nil,   -- Default: second column (e.g., "fr")
        -- Note: CSV files can have 2+ columns; only question/answer columns are used
        
        -- Game mode: "multiple_choice" or "speedrun"
        game_mode = "multiple_choice",
        
        -- Multiple choice settings
        reveal_correct = true, -- Highlight correct answer when you get it wrong
        reveal_delay = 2000,   -- Milliseconds to show correct answer (default: 2000ms / 2 seconds)
        
        -- Reinforcement learning: re-quiz on mistakes
        reinforce = true,         -- Enable mistake reinforcement
        reinforce_chance = 0.7,   -- Probability (0.0-1.0) to show questions from mistake bucket (default: 0.7 = 70%)
        
        -- Speedrun mode settings
        input_keymap = "", -- Keymap for speedrun input (e.g., "kana" for Japanese)
        -- View available keymaps: :echo globpath(&rtp, "keymap/*.vim")
        -- Or create custom ones in ~/.config/nvim/keymap/example.vim
    },

    keybinds = {
        submit = "<CR>",           -- speedrun: submit answer
        refresh = "dd",            -- clear and refresh round
        quit = "q",                -- quit game
        escape = "<esc>",          -- escape to quit
        choice_keys = { "j", "k", "l", ";" },  -- multiple choice selection keys
    },
}
```

### Quick Start
1. Install the plugin
2. Press `<C-g>` to launch
3. Select a lesson from the menu (or configure `csv_file` to skip the menu)
4. In **multiple choice** mode: Press `jkl;` to select answers
5. In **speedrun** mode: Type the answer and press Enter

### Creating Custom Lessons

#### Basic CSV Format
Create CSV files with at least 2 columns. The first row contains column headers:
```csv
example - en,fr
Question text here,answer
Another question,another answer
```

By default, the plugin uses:
- **First column** as questions
- **Second column** as answers

#### Custom Column Configuration
You can add more columns and specify which to use:
```csv
en,fr,notes
Je ___ un étudiant,suis,verb: être (to be)
Tu ___ un chat,as,verb: avoir (to have)
or a third translation
```

Then configure which columns to use:
by default its 1 and 2.
```lua
opts = {
    question_column = "en",  -- Use the "en" column for questions
    answer_column = "fr",    -- Use the "fr" column for answers
    -- The "notes" column will be ignored
}
```

#### Custom Data Directory
Store your lessons anywhere:
```lua
opts = {
    data_directory = "~/Documents/flashcards/",
    -- or use an Obsidian vault:
    -- data_directory = "~/obsidian/my-vault/language-learning/",
}
```

#### Skip Lesson Menu
Set a default lesson to load automatically:
```lua
opts = {
    csv_file = "french_verbs",  -- Just the filename (no .csv needed)
    -- or use full path:
    -- csv_file = "~/my_lessons/spanish_vocab.csv",
}
```

The plugin will automatically detect and list all CSV files in the data directory when no default is set.

## History
    Originally conceived as an opensource **Duolingo** alternitive Neovim, birdee_brains
    has evolved into a general purpose learning tool to reinforce consepts.
    "HOOOO!". No more pencils no more books. Weather its a forign language,
    keybinds, bash_commands, you fill in the blanks. The world is your bash_shell.

## Roadmap
    - [ ] **Curriculum Creator:** Add another app/program to easily add, modify and expand lessons. This
      will let you make your own curriculum.
    - [ ] **Analytics Suit:** A grading/progression system to display highscores and charts of your
      record allowing you to easily identify your strengths, and weak points.
    - [ ] **Streak System:** Reminder to check in. Display steak to insitivise
      daily practice. 
    - [ ] **Phonetic Alphabet:** Incorporate a way to display the International
      Phonetic Alphabet.
    - [ ] *Obsidian:** Abillity to use an obsidian vault as a path.
