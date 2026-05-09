local M = {}

function M.create_engine(settings)
    local engine = {
        correct = 0,
        wrong = 0,
        streak = 0,
        max_streak = 0,
        target_idx = 1,
        mistake_bucket = {},
        settings = settings,
    }

    function engine:bucketcheck(status, idx)
        if self.settings.reinforce == true then
            if status == "correct" then
                for i, v in ipairs(self.mistake_bucket) do
                    if v == idx then
                        table.remove(self.mistake_bucket, i)
                        break
                    end
                end
            else
                local already_in = false
                for _, v in ipairs(self.mistake_bucket) do
                    if v == idx then
                        already_in = true
                        break
                    end
                end
                if not already_in then
                    table.insert(self.mistake_bucket, idx)
                end
            end
        end
    end

    function engine:select_target(questions)
        if self.settings.reinforce == false then
            self.target_idx = math.random(1, #questions)
        else
            if #self.mistake_bucket > 0 and math.random() > 0.3 then
                local bucket_pos = math.random(1, #self.mistake_bucket)
                self.target_idx = self.mistake_bucket[bucket_pos]
            else
                self.target_idx = math.random(1, #questions)
            end
        end
    end

    function engine:generate_choices(answers, correct_answer)
        local choices = { correct_answer }
        -- Try to fill with unique answers from the pool
        local attempts = 0
        while #choices < 4 and attempts < #answers * 2 do
            local r = math.random(1, #answers)
            if answers[r] ~= correct_answer then
                local exists = false
                for _, v in ipairs(choices) do
                    if v == answers[r] then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(choices, answers[r])
                end
            end
            attempts = attempts + 1
        end
        -- Pad with empty strings if we don't have 4 choices
        while #choices < 4 do
            table.insert(choices, "")
        end
        -- Ensure we have exactly 4 choices (truncate if somehow we have more)
        while #choices > 4 do
            table.remove(choices)
        end
        -- Shuffle all 4 positions
        for i = 4, 2, -1 do
            local j = math.random(i)
            choices[i], choices[j] = choices[j], choices[i]
        end
        return choices
    end

    function engine:record_correct(target_idx)
        self.correct = self.correct + 1
        self.streak = self.streak + 1
        self.max_streak = math.max(self.streak, self.max_streak)
        self:bucketcheck("correct", target_idx)
    end

    function engine:record_wrong(target_idx)
        self.wrong = self.wrong + 1
        self.streak = 0
        self:bucketcheck("wrong", target_idx)
    end

    function engine:get_accuracy()
        local total = self.correct + self.wrong
        return total > 0 and (self.correct / total * 100) or 0
    end

    return engine
end

return M
