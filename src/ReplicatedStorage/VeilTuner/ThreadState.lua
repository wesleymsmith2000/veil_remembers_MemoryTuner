local ThreadState = {}

function ThreadState.GetThreadId(index)
    return string.format("Thread_%02d", index)
end

function ThreadState.CreateThreads(threadCount)
    local threads = {}

    for index = 1, threadCount do
        local threadId = ThreadState.GetThreadId(index)

        threads[threadId] = {
            id = threadId,
            displayName = string.format("Thread %02d", index),
            order = index,
            integrity = 100,
            problemId = nil,
            problemExpiresAt = nil,
            pulseType = nil,
            pulseEndsAt = 0,
        }
    end

    return threads
end

function ThreadState.GetOrderedIds(threads)
    local ids = {}

    for threadId in pairs(threads) do
        table.insert(ids, threadId)
    end

    table.sort(ids)

    return ids
end

function ThreadState.GetActiveProblemCount(threads)
    local count = 0

    for _, threadState in pairs(threads) do
        if threadState.problemId then
            count += 1
        end
    end

    return count
end

function ThreadState.GetStableThreadIds(threads)
    local stableIds = {}

    for threadId, threadState in pairs(threads) do
        if not threadState.problemId then
            table.insert(stableIds, threadId)
        end
    end

    table.sort(stableIds)

    return stableIds
end

function ThreadState.SetProblem(threadState, problemId, now, config)
    local problemConfig = config.Problems[problemId]

    threadState.problemId = problemId
    threadState.problemExpiresAt = now + problemConfig.duration
end

function ThreadState.ClearProblem(threadState)
    threadState.problemId = nil
    threadState.problemExpiresAt = nil
end

function ThreadState.GetExpiredThreadIds(threads, now)
    local expiredIds = {}

    for threadId, threadState in pairs(threads) do
        if threadState.problemId and threadState.problemExpiresAt and now >= threadState.problemExpiresAt then
            table.insert(expiredIds, threadId)
        end
    end

    table.sort(expiredIds)

    return expiredIds
end

function ThreadState.SetPulse(threadState, pulseType, now, duration)
    threadState.pulseType = pulseType
    threadState.pulseEndsAt = now + duration
end

function ThreadState.IsPulseActive(threadState, now)
    return threadState.pulseType ~= nil and now < threadState.pulseEndsAt
end

function ThreadState.ClearInactivePulse(threadState, now)
    if threadState.pulseType and now >= threadState.pulseEndsAt then
        threadState.pulseType = nil
        threadState.pulseEndsAt = 0
    end
end

return ThreadState
