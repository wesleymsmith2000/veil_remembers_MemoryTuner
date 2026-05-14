local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MouseKeyboardInputAdapter = {}
MouseKeyboardInputAdapter.__index = MouseKeyboardInputAdapter

function MouseKeyboardInputAdapter.new(config, selectionState, callbacks)
    local self = setmetatable({}, MouseKeyboardInputAdapter)

    self.config = config
    self.selectionState = selectionState
    self.callbacks = callbacks or {}
    self.localPlayer = Players.LocalPlayer
    self.mouse = self.localPlayer:GetMouse()
    self.threadPartsById = {}
    self.hoveredThreadId = nil
    self.connections = {}
    self.actionByKeyCode = {}

    for actionId, actionConfig in pairs(config.Actions) do
        self.actionByKeyCode[actionConfig.keyCode] = actionId
    end

    return self
end

function MouseKeyboardInputAdapter:_notifySelectionChanged()
    if self.callbacks.onSelectionChanged then
        self.callbacks.onSelectionChanged(self.hoveredThreadId)
    end
end

function MouseKeyboardInputAdapter:_setHoveredThread(threadId)
    if self.hoveredThreadId == threadId then
        return
    end

    if self.hoveredThreadId then
        self.selectionState:UnfocusThread(self.hoveredThreadId)
    end

    self.hoveredThreadId = threadId

    if self.hoveredThreadId then
        self.selectionState:FocusThread(self.hoveredThreadId)
    end

    self:_notifySelectionChanged()
end

function MouseKeyboardInputAdapter:_updateHoverTarget()
    local target = self.mouse.Target
    local threadId = nil

    if target then
        threadId = target:GetAttribute("ThreadId")
    end

    if threadId and not self.threadPartsById[threadId] then
        threadId = nil
    end

    self:_setHoveredThread(threadId)
end

function MouseKeyboardInputAdapter:_handleInputBegan(inputObject, gameProcessedEvent)
    if gameProcessedEvent then
        return
    end

    if inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
        if self.hoveredThreadId then
            self.selectionState:ToggleMarkThread(self.hoveredThreadId)
            self:_notifySelectionChanged()
        end
        return
    end

    if inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
        self.selectionState:ClearMarks()
        self:_notifySelectionChanged()
        return
    end

    local actionId = self.actionByKeyCode[inputObject.KeyCode]

    if actionId and self.callbacks.onActionRequested then
        self.callbacks.onActionRequested(actionId)
    end
end

function MouseKeyboardInputAdapter:Start(threadPartsById)
    self.threadPartsById = threadPartsById

    table.insert(self.connections, RunService.RenderStepped:Connect(function()
        self:_updateHoverTarget()
    end))

    table.insert(self.connections, UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
        self:_handleInputBegan(inputObject, gameProcessedEvent)
    end))
end

function MouseKeyboardInputAdapter:Stop()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end

    table.clear(self.connections)
    self:_setHoveredThread(nil)
end

return MouseKeyboardInputAdapter
