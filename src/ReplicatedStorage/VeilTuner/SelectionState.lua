local SelectionState = {}
SelectionState.__index = SelectionState

local function sortedKeys(source)
    local keys = {}

    for key in pairs(source) do
        table.insert(keys, key)
    end

    table.sort(keys)

    return keys
end

function SelectionState.new()
    return setmetatable({
        focused = {},
        marked = {},
    }, SelectionState)
end

function SelectionState:FocusThread(threadId)
    self.focused[threadId] = true
end

function SelectionState:UnfocusThread(threadId)
    self.focused[threadId] = nil
end

function SelectionState:ToggleMarkThread(threadId)
    if self.marked[threadId] then
        self.marked[threadId] = nil
    else
        self.marked[threadId] = true
    end
end

function SelectionState:MarkThread(threadId)
    self.marked[threadId] = true
end

function SelectionState:UnmarkThread(threadId)
    self.marked[threadId] = nil
end

function SelectionState:ClearFocus()
    table.clear(self.focused)
end

function SelectionState:ClearMarks()
    table.clear(self.marked)
end

function SelectionState:IsFocused(threadId)
    return self.focused[threadId] == true
end

function SelectionState:IsMarked(threadId)
    return self.marked[threadId] == true
end

function SelectionState:GetFocusedThreadIds()
    return sortedKeys(self.focused)
end

function SelectionState:GetMarkedThreadIds()
    return sortedKeys(self.marked)
end

function SelectionState:GetEffectiveTargets()
    local targets = {}
    local seen = {}

    for threadId in pairs(self.marked) do
        if not seen[threadId] then
            table.insert(targets, threadId)
            seen[threadId] = true
        end
    end

    for threadId in pairs(self.focused) do
        if not seen[threadId] then
            table.insert(targets, threadId)
            seen[threadId] = true
        end
    end

    table.sort(targets)

    return targets
end

return SelectionState
