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
        -- CSV file to load (optional - if not set, you'll get a lesson picker)
        -- Can be just the filename (e.g., "french_verbs") or full path
        csv_file = "", -- Leave empty to show lesson selection menu
        
        -- Game mode: "multiple_choice" or "speedrun"
        game_mode = "multiple_choice",
        
        -- Multiple choice settings
        reveal_correct = true, -- Highlight correct answer when you get it wrong
        
        -- Reinforcement learning: re-quiz on mistakes
        reinforce = true, -- 70% chance to show questions you got wrong
        
        -- Speedrun mode settings
        input_keymap = "", -- Keymap for speedrun input (e.g., "kana" for Japanese)
        -- View available keymaps: :echo globpath(&rtp, "keymap/*.vim")
        -- Or create custom ones in ~/.config/nvim/keymap/example.vim
        
        -- Data directory (auto-detected, usually don't need to change)
        data_directory = nil, -- Plugin will find lua/birdee_brains/data/
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
Create CSV files in `lua/birdee_brains/data/` with this format:
```csv
en,fr
Question text here,answer
Another question,another answer
```
The plugin will automatically detect and list all CSV files in the data directory.

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
    - [ ] **UserDefined Directories:** Allow users to easily set bird directory.
      Abillity to use an obsidian vault as a path.
