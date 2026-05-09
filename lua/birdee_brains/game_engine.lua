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
        -- Start with correct answer
        local choices = { correct_answer }
        
        -- Collect all unique answers different from correct answer
        local available = {}
        for _, ans in ipairs(answers) do
            if ans ~= correct_answer then
                local already_added = false
                for _, existing in ipairs(available) do
                    if existing == ans then
                        already_added = true
                        break
                    end
                end
                if not already_added then
                    table.insert(available, ans)
                end
            end
        end
        
        -- Add up to 3 random wrong answers from available pool
        while #choices < 4 and #available > 0 do
            local idx = math.random(1, #available)
            table.insert(choices, available[idx])
            table.remove(available, idx)
        end
        
        -- Shuffle only the non-empty choices
        local num_real_choices = #choices
        for i = num_real_choices, 2, -1 do
            local j = math.random(i)
            choices[i], choices[j] = choices[j], choices[i]
        end
        
        -- Pad with empty strings at the end to always have exactly 4 choices
        while #choices < 4 do
            table.insert(choices, "")
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
