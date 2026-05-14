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
    statusTone = "Neutral",
}

local worldTweens = {}
local threadViews = {}
local hud = nil
local spawnClock = 0
local runtimeClock = 0
local feedbackState = {
    tone = "Neutral",
    text = "",
    endsAt = 0,
    actionId = nil,
    iconKey = "Stable",
}

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

local function createStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.Transparency = transparency
    stroke.Parent = parent

    return stroke
end

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent

    return corner
end

local function createSheetImage(parent, name, imageId, rect, size, position)
    local image = Instance.new("ImageLabel")
    image.Name = name
    image.Size = size
    image.Position = position
    image.BackgroundTransparency = 1
    image.Image = imageId
    image.ImageRectOffset = rect.offset
    image.ImageRectSize = rect.size
    image.ScaleType = Enum.ScaleType.Fit
    image.Parent = parent

    return image
end

local function setSheetImageRect(image, rect)
    image.ImageRectOffset = rect.offset
    image.ImageRectSize = rect.size
end

local function createMeter(parent, name, position, color)
    local group = Instance.new("Frame")
    group.Name = name
    group.Size = UDim2.new(1, -32, 0, 48)
    group.Position = position
    group.BackgroundTransparency = 1
    group.Parent = parent

    local label = createText(
        group,
        "Label",
        UDim2.new(1, -70, 0, 18),
        UDim2.fromOffset(0, 0),
        "",
        Enum.Font.GothamMedium,
        13,
        TunerConfig.Visuals.mutedTextColor
    )

    local valueLabel = createText(
        group,
        "Value",
        UDim2.fromOffset(64, 18),
        UDim2.new(1, -64, 0, 0),
        "",
        Enum.Font.GothamBold,
        14,
        color
    )
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, 0, 0, 16)
    track.Position = UDim2.fromOffset(0, 24)
    track.BackgroundColor3 = Color3.fromRGB(9, 18, 30)
    track.BorderSizePixel = 0
    track.Parent = group
    createCorner(track, 4)
    createStroke(track, TunerConfig.Visuals.panelAccentDim, 1, 0.15)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = track
    createCorner(fill, 4)

    local fillGradient = Instance.new("UIGradient")
    fillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color:Lerp(Color3.new(1, 1, 1), 0.15)),
        ColorSequenceKeypoint.new(1, color),
    })
    fillGradient.Parent = fill

    return {
        group = group,
        label = label,
        valueLabel = valueLabel,
        fill = fill,
    }
end

local function createActionChip(parent, actionId, actionConfig, order)
    local chip = Instance.new("Frame")
    chip.Name = actionId
    chip.Size = UDim2.new(0.235, 0, 1, 0)
    chip.Position = UDim2.new((order - 1) * 0.255, 0, 0, 0)
    chip.BackgroundColor3 = Color3.fromRGB(10, 18, 30)
    chip.BorderSizePixel = 0
    chip.Parent = parent

    createCorner(chip, 6)

    local stroke = createStroke(chip, actionConfig.color, 1.5, 0.15)

    local icon = createSheetImage(
        chip,
        "Icon",
        TunerConfig.SpriteSheets.CoreActionIcons,
        actionConfig.iconRect,
        UDim2.fromOffset(34, 34),
        UDim2.fromOffset(7, 6)
    )

    createText(
        chip,
        "KeyLabel",
        UDim2.fromOffset(30, 18),
        UDim2.new(1, -36, 0, 8),
        actionConfig.keyCode.Name,
        Enum.Font.GothamBold,
        13,
        TunerConfig.Visuals.textColor
    )

    local nameLabel = createText(
        chip,
        "NameLabel",
        UDim2.new(1, -50, 0, 18),
        UDim2.fromOffset(42, 32),
        actionConfig.shortName,
        Enum.Font.GothamBold,
        12,
        TunerConfig.Visuals.textColor
    )
    nameLabel.TextWrapped = true

    local taglineLabel = createText(
        chip,
        "TaglineLabel",
        UDim2.new(1, -50, 0, 16),
        UDim2.fromOffset(42, 49),
        actionConfig.tagline,
        Enum.Font.Gotham,
        11,
        TunerConfig.Visuals.mutedTextColor
    )
    taglineLabel.TextWrapped = true

    return {
        frame = chip,
        stroke = stroke,
        icon = icon,
        keyLabel = chip.KeyLabel,
        nameLabel = nameLabel,
        taglineLabel = taglineLabel,
    }
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
    panel.Size = UDim2.fromOffset(470, 190)
    panel.Position = UDim2.fromOffset(28, 28)
    panel.BackgroundColor3 = TunerConfig.Visuals.panelBackground
    panel.BackgroundTransparency = 0.12
    panel.BorderSizePixel = 0
    panel.Parent = screenGui

    createCorner(panel, 8)
    createStroke(panel, TunerConfig.Visuals.panelAccent, 1.6, 0.05)

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 10, 18)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 22, 34)),
    })
    gradient.Rotation = 90
    gradient.Parent = panel

    createText(
        panel,
        "TitleLabel",
        UDim2.new(1, -32, 0, 30),
        UDim2.fromOffset(16, 14),
        "VEIL MEMORY TUNER",
        Enum.Font.GothamBold,
        20,
        TunerConfig.Visuals.textColor
    )

    local subtitleLabel = createText(
        panel,
        "SubtitleLabel",
        UDim2.new(1, -32, 0, 18),
        UDim2.fromOffset(16, 40),
        "Tune the veil. Restore the memory.",
        Enum.Font.Gotham,
        12,
        TunerConfig.Visuals.mutedTextColor
    )
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Center

    local stabilityMeter = createMeter(panel, "StabilityMeter", UDim2.fromOffset(16, 66), TunerConfig.Visuals.stableColor)
    stabilityMeter.label.Text = "STABILITY"

    local memoryMeter = createMeter(panel, "MemoryMeter", UDim2.fromOffset(16, 116), TunerConfig.Visuals.memoryColor)
    memoryMeter.label.Text = "MEMORY PROGRESS"

    local focusLabel = createText(
        panel,
        "FocusLabel",
        UDim2.new(1, -32, 0, 24),
        UDim2.fromOffset(16, 166),
        "",
        Enum.Font.GothamMedium,
        14,
        TunerConfig.Visuals.textColor
    )

    local banner = Instance.new("Frame")
    banner.Name = "FeedbackBanner"
    banner.Size = UDim2.fromOffset(390, 108)
    banner.Position = UDim2.new(0.5, -195, 0, 26)
    banner.BackgroundColor3 = Color3.fromRGB(12, 20, 31)
    banner.BackgroundTransparency = 0.08
    banner.BorderSizePixel = 0
    banner.Parent = screenGui
    createCorner(banner, 6)
    local bannerStroke = createStroke(banner, TunerConfig.Visuals.panelAccentDim, 1.6, 0.08)

    local bannerIcon = createSheetImage(
        banner,
        "StatusIcon",
        TunerConfig.SpriteSheets.StatusAndTargetingIcons,
        TunerConfig.StatusFeedbackIconRects.Stable,
        UDim2.fromOffset(92, 82),
        UDim2.fromOffset(14, 13)
    )

    local bannerLabelImage = createSheetImage(
        banner,
        "StatusLabelImage",
        TunerConfig.SpriteSheets.StatusAndTargetingIcons,
        TunerConfig.StatusFeedbackLabelRects.Stable,
        UDim2.fromOffset(248, 76),
        UDim2.fromOffset(118, 16)
    )

    local messageLabel = createText(
        banner,
        "MessageLabel",
        UDim2.fromScale(1, 1),
        UDim2.fromOffset(0, 0),
        "",
        Enum.Font.GothamBold,
        18,
        TunerConfig.Visuals.textColor
    )
    messageLabel.Visible = false
    messageLabel.TextWrapped = true
    messageLabel.TextYAlignment = Enum.TextYAlignment.Center

    local actionsRow = Instance.new("Frame")
    actionsRow.Name = "ActionsRow"
    actionsRow.Size = UDim2.fromOffset(560, 78)
    actionsRow.Position = UDim2.new(0.5, -280, 1, -96)
    actionsRow.BackgroundTransparency = 1
    actionsRow.Parent = screenGui

    local actionChips = {}

    for order, actionId in ipairs(TunerConfig.ActionOrder) do
        actionChips[actionId] = createActionChip(actionsRow, actionId, TunerConfig.Actions[actionId], order)
    end

    return {
        screenGui = screenGui,
        stabilityMeter = stabilityMeter,
        memoryMeter = memoryMeter,
        focusLabel = focusLabel,
        messageLabel = messageLabel,
        banner = banner,
        bannerIcon = bannerIcon,
        bannerLabelImage = bannerLabelImage,
        bannerStroke = bannerStroke,
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
                nodeOrbBaseSize = threadModel:WaitForChild("NodeOrb").Size,
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

local function pulseThreadView(threadId, tone)
    local view = threadViews[threadId]

    if not view then
        return
    end

    local scale = tone == "Success" and 1.75 or 1.45
    local pulseSize = view.nodeOrbBaseSize * scale

    tweenWorldPart(view.nodeOrb, { Size = pulseSize }, 0.08)

    task.delay(0.09, function()
        if view.nodeOrb then
            tweenWorldPart(view.nodeOrb, { Size = view.nodeOrbBaseSize }, 0.22)
        end
    end)
end

local function getToneColor(tone)
    if tone == "Success" then
        return TunerConfig.Visuals.successColor
    elseif tone == "Error" then
        return TunerConfig.Visuals.errorColor
    elseif tone == "Warning" then
        return TunerConfig.Visuals.warningColor
    end

    return TunerConfig.Visuals.panelAccent
end

local function setMeterValue(meter, value, maxValue)
    local percent = math.clamp(value / maxValue, 0, 1)

    meter.fill.Size = UDim2.fromScale(percent, 1)
    meter.valueLabel.Text = string.format("%d%%", math.floor(percent * 100 + 0.5))
end

local function pulseHud(tone, text, actionId, iconKey)
    feedbackState.tone = tone
    feedbackState.text = text
    feedbackState.actionId = actionId
    feedbackState.iconKey = iconKey or "Warning"
    feedbackState.endsAt = runtimeClock + TunerConfig.Visuals.feedbackDuration

    local toneColor = getToneColor(tone)
    hud.banner.BackgroundColor3 = tone == "Error" and Color3.fromRGB(42, 13, 12) or Color3.fromRGB(10, 22, 30)
    hud.bannerStroke.Color = toneColor
    hud.bannerStroke.Thickness = tone == "Neutral" and 1.4 or 2.4
    hud.messageLabel.TextColor3 = toneColor

    if actionId and hud.actionChips[actionId] then
        local chip = hud.actionChips[actionId]
        chip.stroke.Thickness = 3
        chip.frame.BackgroundColor3 = tone == "Error" and Color3.fromRGB(42, 13, 12) or Color3.fromRGB(16, 38, 34)
    end
end

local function updateHudFeedback(now)
    local active = now < feedbackState.endsAt
    local toneColor = active and getToneColor(feedbackState.tone) or TunerConfig.Visuals.panelAccentDim
    local iconKey = active and feedbackState.iconKey or "Stable"
    local iconRect = TunerConfig.StatusFeedbackIconRects[iconKey] or TunerConfig.StatusFeedbackIconRects.Stable
    local labelRect = TunerConfig.StatusFeedbackLabelRects[iconKey] or TunerConfig.StatusFeedbackLabelRects.Stable

    hud.messageLabel.Text = active and feedbackState.text or challengeState.statusMessage
    hud.messageLabel.TextColor3 = active and toneColor or TunerConfig.Visuals.textColor
    hud.bannerIcon.ImageColor3 = Color3.new(1, 1, 1)
    hud.bannerIcon.ImageTransparency = 0
    hud.bannerLabelImage.ImageColor3 = Color3.new(1, 1, 1)
    hud.bannerLabelImage.ImageTransparency = 0
    setSheetImageRect(hud.bannerIcon, iconRect)
    setSheetImageRect(hud.bannerLabelImage, labelRect)
    hud.bannerStroke.Color = toneColor
    hud.bannerStroke.Thickness = active and 2.4 or 1.4
    hud.banner.BackgroundColor3 = active and Color3.fromRGB(12, 25, 32) or Color3.fromRGB(12, 20, 31)

    for actionId, chip in pairs(hud.actionChips) do
        local actionColor = TunerConfig.Actions[actionId].color
        local isActiveAction = active and feedbackState.actionId == actionId

        chip.stroke.Color = isActiveAction and toneColor or actionColor
        chip.stroke.Thickness = isActiveAction and 3 or 1.5
        chip.frame.BackgroundColor3 = isActiveAction and Color3.fromRGB(20, 34, 34) or Color3.fromRGB(10, 18, 30)
    end
end

local function updateHud()
    local focusedIds = selectionState:GetFocusedThreadIds()
    local markedIds = selectionState:GetMarkedThreadIds()
    local focusedThreadId = focusedIds[1]
    local focusedProblem = focusedThreadId and threadStates[focusedThreadId].problemId or nil

    setMeterValue(hud.stabilityMeter, challengeState.stability, 100)
    setMeterValue(hud.memoryMeter, challengeState.memoryProgress, TunerConfig.Challenge.targetMemoryProgress)

    if focusedThreadId then
        hud.focusLabel.Text = string.format(
            "FOCUS  %s%s",
            focusedThreadId,
            focusedProblem and string.format("  /  %s", focusedProblem) or "  /  STABLE"
        )
    else
        hud.focusLabel.Text = string.format("FOCUS  NONE  /  MARKED %d", #markedIds)
    end

    updateHudFeedback(runtimeClock)
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

local function setStatusMessage(message, tone, actionId, iconKey)
    challengeState.statusMessage = message
    challengeState.statusTone = tone or "Neutral"

    if tone and tone ~= "Neutral" then
        pulseHud(tone, message, actionId, iconKey)
    end

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
    local problemConfig = TunerConfig.Problems[problemId]

    ThreadState.SetProblem(state, problemId, now, TunerConfig)
    setStatusMessage(
        string.format("WARNING  %s destabilized: %s.", threadId, problemId),
        "Warning",
        nil,
        problemConfig.iconKey
    )
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
        pulseThreadView(threadId, "Error")

        setStatusMessage(
            string.format("FAILURE  %s slipped past calibration on %s.", expiredProblem or "A problem", threadId),
            "Error",
            nil,
            expiredProblem and TunerConfig.Problems[expiredProblem].iconKey or "Warning"
        )
    end

    clampChallengeState()
end

local function resolveAction(actionId, now)
    local targetIds = selectionState:GetEffectiveTargets()

    if #targetIds == 0 then
        challengeState.stability -= TunerConfig.Challenge.emptyTargetPenalty
        clampChallengeState()
        setStatusMessage(string.format("NO TARGET  %s had no thread lock.", actionId), "Error", actionId, "Warning")
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
            pulseThreadView(threadId, "Success")
            successCount += 1
        else
            ThreadState.SetPulse(state, "Error", now, TunerConfig.Challenge.pulseDuration)
            state.integrity = math.max(0, state.integrity - math.ceil(TunerConfig.Challenge.wrongStabilityPenalty / 2))
            threadViews[threadId].problemEmitter:Emit(6)
            pulseThreadView(threadId, "Error")
            failureCount += 1
        end
    end

    if successCount > 0 and failureCount == 0 then
        setStatusMessage(string.format("SYNC COMPLETE  %s stabilized the thread.", actionId), "Success", actionId, "Stable")
    elseif successCount > 0 then
        setStatusMessage(string.format("PARTIAL SYNC  %s helped, but backlash spread.", actionId), "Warning", actionId, "Warning")
    else
        setStatusMessage(string.format("MISFIRE  %s destabilized the target.", actionId), "Error", actionId, "Warning")
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
