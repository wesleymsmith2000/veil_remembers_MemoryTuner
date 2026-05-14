local ActionResolver = {}

local function createResult(actionType, targetThreadStates)
    local targetThreads = {}

    for _, threadState in ipairs(targetThreadStates) do
        table.insert(targetThreads, threadState.id)
    end

    table.sort(targetThreads)

    return {
        actionType = actionType,
        targetThreads = targetThreads,
        perThread = {},
        memoryProgressChange = 0,
        stabilityChange = 0,
        backlash = false,
    }
end

function ActionResolver.ResolveAction(actionType, targetThreadStates, config)
    local result = createResult(actionType, targetThreadStates)
    local challengeConfig = config.Challenge

    for _, threadState in ipairs(targetThreadStates) do
        local threadResult = {
            success = false,
            previousProblem = threadState.problemId,
            clearedProblem = false,
        }

        if threadState.problemId then
            local problemConfig = config.Problems[threadState.problemId]

            if problemConfig.correctAction == actionType then
                threadResult.success = true
                threadResult.clearedProblem = true
                result.memoryProgressChange += challengeConfig.correctProgressGain
                result.stabilityChange += challengeConfig.correctStabilityGain
            else
                threadResult.failureReason = "WrongAction"
                result.stabilityChange -= challengeConfig.wrongStabilityPenalty
                result.backlash = true
            end
        else
            threadResult.failureReason = "NoProblem"
            result.stabilityChange -= challengeConfig.emptyTargetPenalty
        end

        result.perThread[threadState.id] = threadResult
    end

    return result
end

return ActionResolver
