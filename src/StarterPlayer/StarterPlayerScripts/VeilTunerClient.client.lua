local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local sharedRoot = ReplicatedStorage:WaitForChild("VeilTuner")
local TunerConfig = require(sharedRoot:WaitForChild("TunerConfig"))
local SelectionState = require(sharedRoot:WaitForChild("SelectionState"))
local ThreadState = require(sharedRoot:WaitForChild("ThreadState"))
local ActionResolver = require(sharedRoot:WaitForChild("ActionResolver"))
local MouseKeyboardInputAdapter = require(script.Parent:WaitForChild("InputAdapters"):WaitForChild("MouseKeyboardInputAdapter"))

local selectionState = SelectionState.new()
local threadStates = ThreadState.CreateThreads(TunerConfig.Challenge.threadCount)
local prototype = workspace:WaitForChild("TunerPrototype")
local threadsFolder = prototype:WaitForChild("Threads")
local rng = Random.new()

local challengeState = {
    stability = TunerConfig.Challenge.startingStability,
    memoryProgress = 0,
    statusMessage = "Tune the unstable threads.",
}

local worldTweens = {}
local threadViews = {}
local hud = nil
local spawnClock = 0
local runtimeClock = 0

local function clampChallengeState()
    challengeState.stability = math.clamp(challengeState.stability, 0, 100)
    challengeState.memoryProgress = math.clamp(
        challengeState.memoryProgress,
        0,
        TunerConfig.Challenge.targetMemoryProgress
    )
end

local function createText(parent, name, size, position, text, font, textSize, color)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Font = font
    label.Text = text
    label.TextColor3 = color
    label.TextSize = textSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    return label
end

local function createActionChip(parent, actionId, actionConfig, order)
    local chip = Instance.new("Frame")
    chip.Name = actionId
    chip.Size = UDim2.new(0.235, 0, 0, 56)
    chip.Position = UDim2.new((order - 1) * 0.255, 0, 0, 0)
    chip.BackgroundColor3 = Color3.fromRGB(18, 24, 36)
    chip.BorderSizePixel = 0
    chip.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = chip

    local stroke = Instance.new("UIStroke")
    stroke.Color = actionConfig.color
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    stroke.Parent = chip

    createText(
        chip,
        "KeyLabel",
        UDim2.fromOffset(42, 26),
        UDim2.fromOffset(10, 7),
        actionConfig.keyCode.Name,
        Enum.Font.GothamBold,
        18,
        actionConfig.color
    )

    local nameLabel = createText(
        chip,
        "NameLabel",
        UDim2.new(1, -20, 0, 20),
        UDim2.fromOffset(10, 29),
        actionConfig.displayName,
        Enum.Font.Gotham,
        14,
        Color3.fromRGB(235, 240, 255)
    )
    nameLabel.TextWrapped = true

    return chip
end

local function createHud()
    local existing = playerGui:FindFirstChild("TunerHud")

    if existing then
        existing:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TunerHud"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(380, 218)
    panel.Position = UDim2.fromOffset(28, 28)
    panel.BackgroundColor3 = TunerConfig.Visuals.panelBackground
    panel.BackgroundTransparency = 0.12
    panel.BorderSizePixel = 0
    panel.Parent = screenGui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 18)
    panelCorner.Parent = panel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = TunerConfig.Visuals.panelAccent
    panelStroke.Thickness = 1.4
    panelStroke.Transparency = 0.15
    panelStroke.Parent = panel

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 18, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 30, 42)),
    })
    gradient.Rotation = 90
    gradient.Parent = panel

    createText(
        panel,
        "TitleLabel",
        UDim2.new(1, -32, 0, 28),
        UDim2.fromOffset(16, 14),
        "VEIL MEMORY TUNER",
        Enum.Font.GothamBold,
        20,
        Color3.fromRGB(245, 235, 190)
    )

    local stabilityLabel = createText(
        panel,
        "StabilityLabel",
        UDim2.new(0.48, -16, 0, 26),
        UDim2.fromOffset(16, 52),
        "",
        Enum.Font.GothamMedium,
        15,
        Color3.fromRGB(191, 232, 255)
    )

    local memoryLabel = createText(
        panel,
        "MemoryLabel",
        UDim2.new(0.48, -16, 0, 26),
        UDim2.fromOffset(196, 52),
        "",
        Enum.Font.GothamMedium,
        15,
        Color3.fromRGB(245, 225, 170)
    )

    local focusLabel = createText(
        panel,
        "FocusLabel",
        UDim2.new(1, -32, 0, 24),
        UDim2.fromOffset(16, 84),
        "",
        Enum.Font.Gotham,
        14,
        Color3.fromRGB(226, 233, 255)
    )

    local messageLabel = createText(
        panel,
        "MessageLabel",
        UDim2.new(1, -32, 0, 38),
        UDim2.fromOffset(16, 108),
        "",
        Enum.Font.GothamMedium,
        15,
        Color3.fromRGB(250, 250, 255)
    )
    messageLabel.TextWrapped = true

    local actionsRow = Instance.new("Frame")
    actionsRow.Name = "ActionsRow"
    actionsRow.Size = UDim2.new(1, -32, 0, 56)
    actionsRow.Position = UDim2.fromOffset(16, 154)
    actionsRow.BackgroundTransparency = 1
    actionsRow.Parent = panel

    local actionChips = {}

    for order, actionId in ipairs(TunerConfig.ActionOrder) do
        actionChips[actionId] = createActionChip(actionsRow, actionId, TunerConfig.Actions[actionId], order)
    end

    return {
        screenGui = screenGui,
        stabilityLabel = stabilityLabel,
        memoryLabel = memoryLabel,
        focusLabel = focusLabel,
        messageLabel = messageLabel,
        actionChips = actionChips,
    }
end

local function collectThreadViews()
    local memoryCore = prototype:WaitForChild("MemoryCore")

    for _, threadModel in ipairs(threadsFolder:GetChildren()) do
        if threadModel:IsA("Model") then
            local threadId = threadModel:GetAttribute("ThreadId") or threadModel.Name
            local coreAttachment = memoryCore:WaitForChild(string.format("CoreAttachment_%02d", threadStates[threadId].order))

            threadViews[threadId] = {
                model = threadModel,
                anchorPart = threadModel:WaitForChild("AnchorPart"),
                nodeOrb = threadModel:WaitForChild("NodeOrb"),
                nodePart = threadModel:WaitForChild("NodePart"),
                beam = threadModel:WaitForChild("ThreadBeam"),
                auraBeam = threadModel:WaitForChild("AuraBeam"),
                coreAttachment = coreAttachment,
                coreAttachmentBasePosition = coreAttachment.Position,
                billboard = threadModel.NodeOrb:WaitForChild("ThreadBillboard"),
                nameLabel = threadModel.NodeOrb.ThreadBillboard:WaitForChild("NameLabel"),
                statusLabel = threadModel.NodeOrb.ThreadBillboard:WaitForChild("StatusLabel"),
                selectionLabel = threadModel.NodeOrb.ThreadBillboard:WaitForChild("SelectionLabel"),
                problemEmitter = threadModel.NodeOrb:WaitForChild("ProblemEmitter"),
            }
        end
    end
end

local function tweenWorldPart(part, properties, duration)
    if worldTweens[part] then
        worldTweens[part]:Cancel()
    end

    local tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    worldTweens[part] = tween
    tween:Play()
end

local function updateHud()
    local focusedIds = selectionState:GetFocusedThreadIds()
    local markedIds = selectionState:GetMarkedThreadIds()
    local focusedThreadId = focusedIds[1]
    local focusedProblem = focusedThreadId and threadStates[focusedThreadId].problemId or nil

    hud.stabilityLabel.Text = string.format("Stability  %d%%", math.floor(challengeState.stability + 0.5))
    hud.memoryLabel.Text = string.format(
        "Memory  %d%%",
        math.floor((challengeState.memoryProgress / TunerConfig.Challenge.targetMemoryProgress) * 100 + 0.5)
    )

    if focusedThreadId then
        hud.focusLabel.Text = string.format(
            "Focus: %s%s",
            focusedThreadId,
            focusedProblem and string.format("  |  Problem: %s", focusedProblem) or "  |  Problem: Stable"
        )
    else
        hud.focusLabel.Text = string.format("Focus: none  |  Marked: %d", #markedIds)
    end

    hud.messageLabel.Text = challengeState.statusMessage
end

local function colorSequence(fromColor, toColor)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0, fromColor),
        ColorSequenceKeypoint.new(1, toColor),
    })
end

local function setEmitterState(emitter, enabled, color, rate)
    emitter.Enabled = enabled
    emitter.Color = ColorSequence.new(color)
    emitter.Rate = rate
end

local function updateThreadVisual(threadId, now)
    local state = threadStates[threadId]
    local view = threadViews[threadId]
    local problemConfig = state.problemId and TunerConfig.Problems[state.problemId] or nil
    local isFocused = selectionState:IsFocused(threadId)
    local isMarked = selectionState:IsMarked(threadId)

    ThreadState.ClearInactivePulse(state, now)

    local beamColor = TunerConfig.Visuals.stableColor
    local auraColor = TunerConfig.Visuals.stableAccentColor
    local nodeColor = TunerConfig.Visuals.stableAccentColor
    local beamWidth = 0.26
    local auraWidth = 0.7
    local emitterRate = 0
    local emitterEnabled = false
    local statusText = "Stable"
    local selectionText = ""

    view.coreAttachment.Position = view.coreAttachmentBasePosition
    view.beam.TextureSpeed = 0.25
    view.beam.CurveSize0 = 0
    view.beam.CurveSize1 = 0

    if problemConfig then
        beamColor = problemConfig.color
        auraColor = problemConfig.color
        nodeColor = problemConfig.color
        statusText = string.format("%s  %s", problemConfig.glyph, problemConfig.displayName)
        emitterEnabled = true
        emitterRate = 8

        if state.problemId == "Static" then
            view.beam.TextureSpeed = 1.75
            beamWidth = 0.3
            auraWidth = 0.8
        elseif state.problemId == "Drift" then
            local driftOffset = Vector3.new(
                math.sin(now * 2.6 + state.order) * 0.8,
                math.cos(now * 3 + state.order) * 0.4,
                math.cos(now * 1.8 + state.order) * 0.35
            )
            view.coreAttachment.Position = view.coreAttachmentBasePosition + driftOffset
            view.beam.CurveSize0 = 1.8
            view.beam.CurveSize1 = -1.8
        elseif state.problemId == "Dissonance" then
            local pulseScale = 0.05 + math.abs(math.sin(now * 5 + state.order)) * 0.08
            beamWidth = 0.24 + pulseScale
            auraWidth = 0.68 + pulseScale * 1.4
        elseif state.problemId == "Overload" then
            beamWidth = 0.34
            auraWidth = 0.92
            emitterRate = 13
        end
    end

    if isFocused then
        selectionText ..= TunerConfig.Visuals.focusGlyph
    end

    if isMarked then
        if selectionText ~= "" then
            selectionText ..= " "
        end
        selectionText ..= TunerConfig.Visuals.markGlyph
    end

    if selectionText == "" then
        selectionText = " "
    end

    if ThreadState.IsPulseActive(state, now) then
        if state.pulseType == "Success" then
            nodeColor = TunerConfig.Visuals.successColor
            auraColor = TunerConfig.Visuals.successColor
            beamWidth += 0.08
            auraWidth += 0.15
        elseif state.pulseType == "Error" then
            nodeColor = TunerConfig.Visuals.errorColor
            auraColor = TunerConfig.Visuals.errorColor
            beamWidth += 0.04
            auraWidth += 0.08
        end
    end

    view.beam.Width0 = beamWidth
    view.beam.Width1 = math.max(0.16, beamWidth - 0.04)
    view.auraBeam.Width0 = auraWidth
    view.auraBeam.Width1 = math.max(0.4, auraWidth - 0.12)
    view.beam.Color = colorSequence(beamColor, TunerConfig.Visuals.stableAccentColor)
    view.auraBeam.Color = colorSequence(auraColor, beamColor)
    view.nodeOrb.Color = nodeColor
    view.nameLabel.TextColor3 = isFocused and Color3.fromRGB(255, 255, 255) or TunerConfig.Visuals.stableAccentColor
    view.statusLabel.Text = statusText
    view.statusLabel.TextColor3 = beamColor
    view.selectionLabel.Text = selectionText
    view.selectionLabel.TextColor3 = isMarked and TunerConfig.Visuals.stableAccentColor or Color3.fromRGB(255, 255, 255)
    setEmitterState(view.problemEmitter, emitterEnabled, beamColor, emitterRate)
end

local function updateAllVisuals(now)
    for _, threadId in ipairs(ThreadState.GetOrderedIds(threadStates)) do
        updateThreadVisual(threadId, now)
    end

    updateHud()
end

local function setStatusMessage(message)
    challengeState.statusMessage = message
    updateHud()
end

local function spawnProblem(now)
    if ThreadState.GetActiveProblemCount(threadStates) >= TunerConfig.Challenge.maxSimultaneousProblems then
        return
    end

    local stableThreadIds = ThreadState.GetStableThreadIds(threadStates)

    if #stableThreadIds == 0 then
        return
    end

    local threadId = stableThreadIds[rng:NextInteger(1, #stableThreadIds)]
    local problemId = TunerConfig.ProblemOrder[rng:NextInteger(1, #TunerConfig.ProblemOrder)]
    local state = threadStates[threadId]

    ThreadState.SetProblem(state, problemId, now, TunerConfig)
    setStatusMessage(string.format("%s destabilized with %s.", threadId, problemId))
end

local function expireProblems(now)
    local expiredIds = ThreadState.GetExpiredThreadIds(threadStates, now)

    for _, threadId in ipairs(expiredIds) do
        local state = threadStates[threadId]
        local expiredProblem = state.problemId

        ThreadState.ClearProblem(state)
        ThreadState.SetPulse(state, "Error", now, TunerConfig.Challenge.pulseDuration)
        challengeState.stability -= TunerConfig.Challenge.expiredProblemPenalty
        state.integrity = math.max(0, state.integrity - TunerConfig.Challenge.expiredProblemPenalty)
        threadViews[threadId].problemEmitter:Emit(8)

        setStatusMessage(string.format("%s slipped past calibration on %s.", expiredProblem or "A problem", threadId))
    end

    clampChallengeState()
end

local function resolveAction(actionId, now)
    local targetIds = selectionState:GetEffectiveTargets()

    if #targetIds == 0 then
        challengeState.stability -= TunerConfig.Challenge.emptyTargetPenalty
        clampChallengeState()
        setStatusMessage(string.format("%s had no target lock.", actionId))
        return
    end

    local targetStates = {}

    for _, threadId in ipairs(targetIds) do
        table.insert(targetStates, threadStates[threadId])
    end

    local result = ActionResolver.ResolveAction(actionId, targetStates, TunerConfig)

    challengeState.memoryProgress += result.memoryProgressChange
    challengeState.stability += result.stabilityChange
    clampChallengeState()

    local successCount = 0
    local failureCount = 0

    for threadId, threadResult in pairs(result.perThread) do
        local state = threadStates[threadId]

        if threadResult.clearedProblem then
            ThreadState.ClearProblem(state)
            ThreadState.SetPulse(state, "Success", now, TunerConfig.Challenge.pulseDuration)
            threadViews[threadId].problemEmitter:Emit(10)
            successCount += 1
        else
            ThreadState.SetPulse(state, "Error", now, TunerConfig.Challenge.pulseDuration)
            state.integrity = math.max(0, state.integrity - math.ceil(TunerConfig.Challenge.wrongStabilityPenalty / 2))
            threadViews[threadId].problemEmitter:Emit(6)
            failureCount += 1
        end
    end

    if successCount > 0 and failureCount == 0 then
        setStatusMessage(string.format("%s synchronized cleanly.", actionId))
    elseif successCount > 0 then
        setStatusMessage(string.format("%s helped some threads, but backlash spread.", actionId))
    else
        setStatusMessage(string.format("%s misfired. Stability dropped.", actionId))
    end
end

collectThreadViews()
hud = createHud()

local adapter = MouseKeyboardInputAdapter.new(TunerConfig, selectionState, {
    onSelectionChanged = function()
        updateHud()
    end,
    onActionRequested = function(actionId)
        resolveAction(actionId, runtimeClock)
    end,
})

local threadPartsById = {}

for threadId, view in pairs(threadViews) do
    threadPartsById[threadId] = view.nodePart
end

adapter:Start(threadPartsById)

updateAllVisuals(runtimeClock)
tweenWorldPart(prototype.MemoryCore, { Size = Vector3.new(4.6, 4.6, 4.6) }, 1.8)
tweenWorldPart(prototype.CoreGlow, { Size = Vector3.new(7.4, 7.4, 7.4) }, 1.8)

RunService.Heartbeat:Connect(function(deltaTime)
    runtimeClock += deltaTime
    spawnClock += deltaTime

    expireProblems(runtimeClock)

    if spawnClock >= TunerConfig.Challenge.problemSpawnInterval then
        spawnClock = 0
        spawnProblem(runtimeClock)
    end

    updateAllVisuals(runtimeClock)
end)
