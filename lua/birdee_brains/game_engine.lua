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

    function engine:select_target(dict_a)
        if self.settings.reinforce == false then
            self.target_idx = math.random(1, #dict_a)
        else
            if #self.mistake_bucket > 0 and math.random() > 0.3 then
                local bucket_pos = math.random(1, #self.mistake_bucket)
                self.target_idx = self.mistake_bucket[bucket_pos]
            else
                self.target_idx = math.random(1, #dict_a)
            end
        end
    end

    function engine:generate_choices(dict_b, correct_answer)
        local choices = { correct_answer }
        while #choices < 4 do
            local r = math.random(1, #dict_b)
            if dict_b[r] ~= correct_answer then
                local exists = false
                for _, v in ipairs(choices) do
                    if v == dict_b[r] then
                        exists = true
                    end
                end
                if not exists then
                    table.insert(choices, dict_b[r])
                end
            end
        end
        -- Shuffle
        for i = #choices, 2, -1 do
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
