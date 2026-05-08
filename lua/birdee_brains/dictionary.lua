local M = {}

-- Path helper
function M.load_dictionary(bird, num)
    local relative_path = string.format("lua/birdee_brains/%s/%s%d.lua", bird, bird, num)
    local files = vim.api.nvim_get_runtime_file(relative_path, false)

    if #files == 0 then
        error("Dictionary not found: " .. relative_path)
    end
    return dofile(files[1])
end

return M
