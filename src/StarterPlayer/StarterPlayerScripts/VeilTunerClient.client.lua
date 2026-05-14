local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

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
local operatorState = {
    active = false,
    prompt = nil,
    lockCFrame = nil,
    previousWalkSpeed = nil,
    previousJumpPower = nil,
    previousJumpHeight = nil,
    previousAutoRotate = nil,
    previousCameraType = nil,
    previousCameraSubject = nil,
    controls = nil,
}
local feedbackState = {
    tone = "Neutral",
    text = "",
    endsAt = 0,
    actionId = nil,
    iconKey = "Stable",
}
local eventLog = {}

local function clampChallengeState()
    challengeState.stability = math.clamp(challengeState.stability, 0, 100)
    challengeState.memoryProgress = math.clamp(
        challengeState.memoryProgress,
        0,
        TunerConfig.Challenge.targetMemoryProgress
    )
end

local addEventLogMessage
local resetGameSession
local checkSessionEnd
local updateAllVisuals

local function getCharacterRig()
    local character = localPlayer.Character

    if not character then
        return nil, nil, nil
    end

    return character, character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart")
end

local function getPlayerControls()
    if operatorState.controls then
        return operatorState.controls
    end

    local playerScripts = localPlayer:WaitForChild("PlayerScripts")
    local playerModule = playerScripts:WaitForChild("PlayerModule")
    local controls = require(playerModule):GetControls()
    operatorState.controls = controls

    return controls
end

local function aimOperatorCamera()
    camera = workspace.CurrentCamera

    local lockPoint = prototype:WaitForChild("OperatorStation"):WaitForChild("OperatorLockPoint")
    local crystal = prototype:WaitForChild("MemoryCore")
    local cameraPosition = lockPoint.Position + Vector3.new(0, 2.2, 5.8)
    local lookAtPosition = crystal.Position + Vector3.new(0, 0.6, 0)

    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = select(2, getCharacterRig())
    camera.CFrame = CFrame.lookAt(cameraPosition, lookAtPosition)
end

local function setOperatorMode(enabled, prompt, resetOnRelease)
    if enabled == operatorState.active then
        return
    end

    local character, humanoid, rootPart = getCharacterRig()

    if not humanoid or not rootPart then
        return
    end

    operatorState.active = enabled
    operatorState.prompt = prompt or operatorState.prompt

    if enabled then
        if hud then
            hud.screenGui.Enabled = true
        end

        if resetGameSession then
            resetGameSession("Tuner session started.")
        end

        local lockPoint = prototype:WaitForChild("OperatorStation"):WaitForChild("OperatorLockPoint")
        operatorState.lockCFrame = lockPoint.CFrame
        operatorState.previousWalkSpeed = humanoid.WalkSpeed
        operatorState.previousJumpPower = humanoid.JumpPower
        operatorState.previousJumpHeight = humanoid.JumpHeight
        operatorState.previousAutoRotate = humanoid.AutoRotate

        getPlayerControls():Disable()
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        humanoid.JumpHeight = 0
        humanoid.AutoRotate = false
        character:PivotTo(operatorState.lockCFrame)
        aimOperatorCamera()

        if operatorState.prompt then
            operatorState.prompt.ActionText = "Step Away"
        end

        addEventLogMessage("Operator station locked. Movement disabled.")
    else
        getPlayerControls():Enable()
        humanoid.WalkSpeed = operatorState.previousWalkSpeed or 16
        humanoid.JumpPower = operatorState.previousJumpPower or 50
        humanoid.JumpHeight = operatorState.previousJumpHeight or 7.2
        humanoid.AutoRotate = operatorState.previousAutoRotate ~= false

        if operatorState.prompt then
            operatorState.prompt.ActionText = "Tune"
        end

        addEventLogMessage("Operator station released.")

        if resetOnRelease ~= false and resetGameSession then
            resetGameSession("Tuner session reset.")
        end

        if hud then
            hud.screenGui.Enabled = false
        end
    end
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

local function createThreadOverlay(nodeOrb, name, rect, size, studsOffset)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = name
    billboard.Adornee = nodeOrb
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Size = size
    billboard.StudsOffset = studsOffset
    billboard.Parent = nodeOrb

    local image = createSheetImage(
        billboard,
        "Icon",
        TunerConfig.SpriteSheets.StatusAndTargetingIcons,
        rect,
        UDim2.fromScale(1, 1),
        UDim2.fromScale(0, 0)
    )

    return {
        billboard = billboard,
        image = image,
    }
end

local function createOrbGauge(parent)
    local group = Instance.new("Frame")
    group.Name = "ResourceOrb"
    group.Size = UDim2.fromOffset(270, 146)
    group.Position = UDim2.new(0, 28, 1, -232)
    group.BackgroundTransparency = 1
    group.BorderSizePixel = 0
    group.Parent = parent

    local stabilityLabel = createText(
        group,
        "StabilityValue",
        UDim2.fromOffset(76, 48),
        UDim2.fromOffset(0, 48),
        "",
        Enum.Font.GothamBold,
        22,
        TunerConfig.Visuals.stableColor
    )
    stabilityLabel.TextXAlignment = Enum.TextXAlignment.Center

    local stabilityCaption = createText(
        group,
        "StabilityCaption",
        UDim2.fromOffset(76, 20),
        UDim2.fromOffset(0, 88),
        "STABILITY",
        Enum.Font.GothamBold,
        10,
        TunerConfig.Visuals.mutedTextColor
    )
    stabilityCaption.TextXAlignment = Enum.TextXAlignment.Center

    local orb = Instance.new("Frame")
    orb.Name = "Orb"
    orb.Size = UDim2.fromOffset(118, 118)
    orb.Position = UDim2.fromOffset(76, 14)
    orb.BackgroundColor3 = Color3.fromRGB(5, 10, 18)
    orb.BackgroundTransparency = 0.1
    orb.BorderSizePixel = 0
    orb.ClipsDescendants = true
    orb.Parent = group
    createCorner(orb, 59)
    local orbStroke = createStroke(orb, TunerConfig.Visuals.panelAccent, 2, 0.08)

    local fillRows = {}
    local rowCount = 28
    local rowHeight = 118 / rowCount
    local radius = 59

    for index = 1, rowCount do
        local yCenter = 118 - ((index - 0.5) * rowHeight)
        local distanceFromCenter = math.abs(yCenter - radius)
        local halfWidth = math.sqrt(math.max(0, radius * radius - distanceFromCenter * distanceFromCenter))
        local rowWidth = halfWidth * 2

        local row = Instance.new("Frame")
        row.Name = string.format("FillRow%02d", index)
        row.AnchorPoint = Vector2.new(0.5, 1)
        row.Size = UDim2.fromOffset(rowWidth, rowHeight + 0.8)
        row.Position = UDim2.fromOffset(radius, 118 - ((index - 1) * rowHeight))
        row.BackgroundColor3 = TunerConfig.Visuals.stableColor
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.Parent = orb

        table.insert(fillRows, row)
    end

    local glint = Instance.new("Frame")
    glint.Name = "Glint"
    glint.Size = UDim2.fromOffset(36, 12)
    glint.Position = UDim2.fromOffset(26, 24)
    glint.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glint.BackgroundTransparency = 0.68
    glint.BorderSizePixel = 0
    glint.Parent = orb
    createCorner(glint, 6)

    local memoryLabel = createText(
        group,
        "MemoryValue",
        UDim2.fromOffset(76, 48),
        UDim2.fromOffset(194, 48),
        "",
        Enum.Font.GothamBold,
        22,
        TunerConfig.Visuals.memoryColor
    )
    memoryLabel.TextXAlignment = Enum.TextXAlignment.Center

    local memoryCaption = createText(
        group,
        "MemoryCaption",
        UDim2.fromOffset(76, 20),
        UDim2.fromOffset(194, 88),
        "MEMORY",
        Enum.Font.GothamBold,
        10,
        TunerConfig.Visuals.mutedTextColor
    )
    memoryCaption.TextXAlignment = Enum.TextXAlignment.Center

    return {
        frame = group,
        orb = orb,
        stroke = orbStroke,
        fillRows = fillRows,
        stabilityLabel = stabilityLabel,
        memoryLabel = memoryLabel,
    }
end

local function createEdgeWarning(parent)
    local overlay = Instance.new("Frame")
    overlay.Name = "LowStabilityEdgeWarning"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.Position = UDim2.fromScale(0, 0)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.ZIndex = 50
    overlay.Parent = parent

    local edgeColor = Color3.fromRGB(255, 46, 122)
    local edges = {}

    local function createEdge(name, size, position, rotation)
        local edge = Instance.new("Frame")
        edge.Name = name
        edge.Size = size
        edge.Position = position
        edge.BackgroundColor3 = edgeColor
        edge.BackgroundTransparency = 1
        edge.BorderSizePixel = 0
        edge.ZIndex = overlay.ZIndex
        edge.Parent = overlay

        local gradient = Instance.new("UIGradient")
        gradient.Rotation = rotation
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        gradient.Parent = edge

        table.insert(edges, edge)
    end

    createEdge("Top", UDim2.new(1, 0, 0, 160), UDim2.fromOffset(0, 0), 90)
    createEdge("Bottom", UDim2.new(1, 0, 0, 160), UDim2.new(0, 0, 1, -160), 270)
    createEdge("Left", UDim2.new(0, 180, 1, 0), UDim2.fromOffset(0, 0), 0)
    createEdge("Right", UDim2.new(0, 180, 1, 0), UDim2.new(1, -180, 0, 0), 180)

    return {
        frame = overlay,
        edges = edges,
    }
end

local function createLogLabel(parent, text)
    local label = createText(
        parent,
        "LogEntry",
        UDim2.new(1, -8, 0, 18),
        UDim2.fromOffset(0, 0),
        text,
        Enum.Font.Gotham,
        12,
        TunerConfig.Visuals.mutedTextColor
    )
    label.TextWrapped = true
    label.TextYAlignment = Enum.TextYAlignment.Center

    return label
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
    screenGui.Enabled = false
    screenGui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(288, 184)
    panel.Position = UDim2.new(0, 0, 0.1, 28)
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

    local logTitle = createText(
        panel,
        "LogTitle",
        UDim2.new(1, -32, 0, 24),
        UDim2.fromOffset(16, 66),
        "SIGNAL LOG",
        Enum.Font.GothamBold,
        13,
        TunerConfig.Visuals.textColor
    )

    local logFrame = Instance.new("Frame")
    logFrame.Name = "LogFrame"
    logFrame.Size = UDim2.new(1, -32, 0, 82)
    logFrame.Position = UDim2.fromOffset(16, 90)
    logFrame.BackgroundColor3 = Color3.fromRGB(8, 15, 24)
    logFrame.BackgroundTransparency = 0.08
    logFrame.BorderSizePixel = 0
    logFrame.Parent = panel
    createCorner(logFrame, 5)
    createStroke(logFrame, TunerConfig.Visuals.panelAccentDim, 1, 0.2)

    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Name = "LogScroll"
    logScroll.Size = UDim2.new(1, -16, 1, -10)
    logScroll.Position = UDim2.fromOffset(8, 5)
    logScroll.BackgroundTransparency = 1
    logScroll.BorderSizePixel = 0
    logScroll.ScrollBarThickness = 3
    logScroll.CanvasSize = UDim2.fromOffset(0, 0)
    logScroll.Parent = logFrame

    local logList = Instance.new("UIListLayout")
    logList.Name = "LogList"
    logList.Padding = UDim.new(0, 2)
    logList.SortOrder = Enum.SortOrder.LayoutOrder
    logList.Parent = logScroll

    local orbGauge = createOrbGauge(screenGui)
    local edgeWarning = createEdgeWarning(screenGui)

    local banner = Instance.new("Frame")
    banner.Name = "StatusBanner"
    banner.Size = UDim2.fromOffset(360, 112)
    banner.Position = UDim2.new(1, -388, 0, 26)
    banner.BackgroundColor3 = Color3.fromRGB(12, 20, 31)
    banner.BackgroundTransparency = 0.08
    banner.BorderSizePixel = 0
    banner.Parent = screenGui
    createCorner(banner, 6)
    local bannerStroke = createStroke(banner, TunerConfig.Visuals.panelAccentDim, 1.6, 0.08)

    local globalStatusLabel = createSheetImage(
        banner,
        "GlobalStatusLabel",
        TunerConfig.SpriteSheets.StatusAndTargetingIcons,
        TunerConfig.StatusFeedbackLabelRects.Stable,
        UDim2.fromOffset(128, 50),
        UDim2.fromOffset(14, 31)
    )

    local focusStatusCard = createSheetImage(
        banner,
        "FocusStatusCard",
        TunerConfig.SpriteSheets.StatusAndTargetingIcons,
        TunerConfig.StatusCardTopRects.Stable,
        UDim2.fromOffset(182, 82),
        UDim2.fromOffset(158, 15)
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

    local legendPanel = Instance.new("Frame")
    legendPanel.Name = "ConditionLegend"
    legendPanel.Size = UDim2.fromOffset(150, 424)
    legendPanel.Position = UDim2.new(1, -178, 0, 152)
    legendPanel.BackgroundColor3 = TunerConfig.Visuals.panelBackground
    legendPanel.BackgroundTransparency = 0.14
    legendPanel.BorderSizePixel = 0
    legendPanel.Parent = screenGui
    createCorner(legendPanel, 8)
    createStroke(legendPanel, TunerConfig.Visuals.panelAccent, 1.4, 0.2)

    local legendTitle = createText(
        legendPanel,
        "LegendTitle",
        UDim2.new(1, -24, 0, 24),
        UDim2.fromOffset(12, 10),
        "INDEX",
        Enum.Font.GothamBold,
        14,
        TunerConfig.Visuals.textColor
    )
    legendTitle.TextXAlignment = Enum.TextXAlignment.Center

    local legendEntries = {}

    for index, problemId in ipairs(TunerConfig.ProblemOrder) do
        local entryFrame = Instance.new("Frame")
        entryFrame.Name = problemId
        entryFrame.Size = UDim2.fromOffset(128, 88)
        entryFrame.Position = UDim2.fromOffset(11, 38 + (index - 1) * 94)
        entryFrame.BackgroundColor3 = Color3.fromRGB(8, 15, 24)
        entryFrame.BackgroundTransparency = 0.18
        entryFrame.BorderSizePixel = 0
        entryFrame.Parent = legendPanel
        createCorner(entryFrame, 5)
        local entryStroke = createStroke(entryFrame, TunerConfig.Problems[problemId].color, 1.2, 0.65)

        local entryImage = createSheetImage(
            entryFrame,
            "LegendImage",
            TunerConfig.SpriteSheets.StatusAndTargetingIcons,
            TunerConfig.StatusLegendRects[problemId],
            UDim2.fromOffset(118, 78),
            UDim2.fromOffset(5, 5)
        )
        entryImage.ImageTransparency = 0.48

        legendEntries[problemId] = {
            frame = entryFrame,
            stroke = entryStroke,
            image = entryImage,
        }
    end

    local actionChips = {}

    for order, actionId in ipairs(TunerConfig.ActionOrder) do
        actionChips[actionId] = createActionChip(actionsRow, actionId, TunerConfig.Actions[actionId], order)
    end

    return {
        screenGui = screenGui,
        orbGauge = orbGauge,
        edgeWarning = edgeWarning,
        logScroll = logScroll,
        logList = logList,
        messageLabel = messageLabel,
        banner = banner,
        globalStatusLabel = globalStatusLabel,
        focusStatusCard = focusStatusCard,
        bannerStroke = bannerStroke,
        legendEntries = legendEntries,
        actionChips = actionChips,
    }
end

local function collectThreadViews()
    local memoryCore = prototype:WaitForChild("MemoryCore")

    for _, threadModel in ipairs(threadsFolder:GetChildren()) do
        if threadModel:IsA("Model") then
            local threadId = threadModel:GetAttribute("ThreadId") or threadModel.Name
            local coreAttachment = memoryCore:WaitForChild(string.format("CoreAttachment_%02d", threadStates[threadId].order))
            local nodeOrb = threadModel:WaitForChild("NodeOrb")
            local focusOverlay = createThreadOverlay(
                nodeOrb,
                "FocusOverlay",
                TunerConfig.StatusIconRects.Focused,
                UDim2.fromOffset(82, 82),
                Vector3.new(0, 0, 0)
            )
            local markedOverlay = createThreadOverlay(
                nodeOrb,
                "MarkedOverlay",
                TunerConfig.StatusIconRects.Marked,
                UDim2.fromOffset(66, 66),
                Vector3.new(0, 0.12, 0)
            )

            threadViews[threadId] = {
                model = threadModel,
                anchorPart = threadModel:WaitForChild("AnchorPart"),
                nodeOrb = nodeOrb,
                nodeOrbBaseSize = nodeOrb.Size,
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
                focusReticleMesh = threadModel:WaitForChild("FocusReticleMesh"),
                markedGlyphMesh = threadModel:WaitForChild("MarkedGlyphMesh"),
                focusOverlay = focusOverlay,
                markedOverlay = markedOverlay,
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

local stabilityGradientStops = {
    { threshold = 100, color = Color3.fromRGB(111, 232, 255) },
    { threshold = 85, color = Color3.fromRGB(111, 232, 255) },
    { threshold = 70, color = Color3.fromRGB(63, 191, 214) },
    { threshold = 55, color = Color3.fromRGB(143, 234, 154) },
    { threshold = 40, color = Color3.fromRGB(255, 211, 106) },
    { threshold = 25, color = Color3.fromRGB(255, 154, 61) },
    { threshold = 10, color = Color3.fromRGB(255, 77, 77) },
    { threshold = 0, color = Color3.fromRGB(255, 46, 122) },
}

local function getStabilityColor(value)
    local percent = math.clamp(value, 0, 100)

    for index = 1, #stabilityGradientStops - 1 do
        local high = stabilityGradientStops[index]
        local low = stabilityGradientStops[index + 1]

        if percent <= high.threshold and percent >= low.threshold then
            local segmentRange = high.threshold - low.threshold
            local alpha = segmentRange > 0 and (high.threshold - percent) / segmentRange or 0

            return high.color:Lerp(low.color, alpha)
        end
    end

    return stabilityGradientStops[#stabilityGradientStops].color
end

local function setOrbGaugeValue(gauge, stabilityValue, memoryValue)
    local stabilityPercent = math.clamp(stabilityValue / 100, 0, 1)
    local memoryPercent = math.clamp(memoryValue / TunerConfig.Challenge.targetMemoryProgress, 0, 1)
    local stabilityColor = getStabilityColor(stabilityValue)

    local visibleRows = memoryPercent * #gauge.fillRows

    for index, row in ipairs(gauge.fillRows) do
        local rowFill = math.clamp(visibleRows - index + 1, 0, 1)

        row.BackgroundColor3 = stabilityColor:Lerp(Color3.new(1, 1, 1), rowFill * 0.12)
        row.BackgroundTransparency = rowFill > 0 and (0.08 + (1 - rowFill) * 0.5) or 1
    end

    gauge.stroke.Color = stabilityColor
    gauge.stroke.Transparency = 0.04 + (1 - stabilityPercent) * 0.32
    gauge.stabilityLabel.Text = string.format("%d%%", math.floor(stabilityValue + 0.5))
    gauge.stabilityLabel.TextColor3 = stabilityColor
    gauge.memoryLabel.Text = string.format("%d%%", math.floor(memoryPercent * 100 + 0.5))
end

local function updateEdgeWarning(edgeWarning, stabilityValue, now)
    if stabilityValue > 20 then
        for _, edge in ipairs(edgeWarning.edges) do
            edge.BackgroundTransparency = 1
        end

        return
    end

    local visibilityMultiplier = math.clamp((20 - stabilityValue) / 19, 0, 1)
    local cycleDuration = 8 - visibilityMultiplier * 6
    local pulse = (math.sin((now / cycleDuration) * math.pi * 2) + 1) / 2
    local baseOpacity = 0.34
    local pulseOpacity = pulse * 0.52
    local opacity = math.clamp((baseOpacity + pulseOpacity) * visibilityMultiplier, 0, 0.86)
    local transparency = 1 - opacity
    local warningColor = getStabilityColor(stabilityValue)

    for _, edge in ipairs(edgeWarning.edges) do
        edge.BackgroundColor3 = warningColor
        edge.BackgroundTransparency = transparency
    end
end

local function refreshEventLog()
    for _, child in ipairs(hud.logScroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    for index, message in ipairs(eventLog) do
        local label = createLogLabel(hud.logScroll, message)
        label.LayoutOrder = index
    end

    local contentHeight = hud.logList.AbsoluteContentSize.Y
    hud.logScroll.CanvasSize = UDim2.fromOffset(0, contentHeight)
    hud.logScroll.CanvasPosition = Vector2.new(0, math.max(0, contentHeight - hud.logScroll.AbsoluteWindowSize.Y))
end

function addEventLogMessage(message)
    table.insert(eventLog, string.format("%05.1fs  %s", runtimeClock, message))

    while #eventLog > 16 do
        table.remove(eventLog, 1)
    end

    if hud then
        refreshEventLog()
    end
end

function resetGameSession(message)
    threadStates = ThreadState.CreateThreads(TunerConfig.Challenge.threadCount)
    challengeState.stability = TunerConfig.Challenge.startingStability
    challengeState.memoryProgress = 0
    challengeState.statusMessage = "Tune the unstable threads."
    challengeState.statusTone = "Neutral"
    feedbackState.tone = "Neutral"
    feedbackState.text = ""
    feedbackState.endsAt = 0
    feedbackState.actionId = nil
    feedbackState.iconKey = "Stable"
    spawnClock = 0
    eventLog = {}

    selectionState:ClearFocus()
    selectionState:ClearMarks()

    if message then
        addEventLogMessage(message)
    elseif hud then
        refreshEventLog()
    end

    if hud then
        updateAllVisuals(runtimeClock)
    end
end

local function getActiveProblemIds()
    local activeProblemIds = {}

    for _, threadState in pairs(threadStates) do
        if threadState.problemId then
            activeProblemIds[threadState.problemId] = true
        end
    end

    return activeProblemIds
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

local function updateStatusBanner(now)
    local active = now < feedbackState.endsAt
    local toneColor = active and getToneColor(feedbackState.tone) or TunerConfig.Visuals.panelAccentDim
    local focusedIds = selectionState:GetFocusedThreadIds()
    local focusedThreadId = focusedIds[1]
    local focusedProblem = focusedThreadId and threadStates[focusedThreadId].problemId or nil
    local focusedIconKey = focusedProblem and TunerConfig.Problems[focusedProblem].iconKey or "Stable"
    local globalIconKey = ThreadState.GetActiveProblemCount(threadStates) > 0 and "Warning" or "Stable"
    local globalLabelRect = TunerConfig.StatusFeedbackLabelRects[globalIconKey]
    local focusedCardRect = TunerConfig.StatusCardTopRects[focusedIconKey] or TunerConfig.StatusCardTopRects.Stable
    local activeProblemIds = getActiveProblemIds()

    hud.messageLabel.Text = active and feedbackState.text or challengeState.statusMessage
    hud.messageLabel.TextColor3 = active and toneColor or TunerConfig.Visuals.textColor
    hud.globalStatusLabel.ImageColor3 = Color3.new(1, 1, 1)
    hud.globalStatusLabel.ImageTransparency = 0
    setSheetImageRect(hud.globalStatusLabel, globalLabelRect)
    hud.focusStatusCard.ImageColor3 = Color3.new(1, 1, 1)
    hud.focusStatusCard.ImageTransparency = focusedThreadId and 0 or 0.18
    setSheetImageRect(hud.focusStatusCard, focusedCardRect)
    hud.bannerStroke.Color = globalIconKey == "Warning" and TunerConfig.Visuals.warningColor or TunerConfig.Visuals.stableColor
    hud.bannerStroke.Thickness = 1.8
    hud.banner.BackgroundColor3 = globalIconKey == "Warning" and Color3.fromRGB(34, 14, 14) or Color3.fromRGB(12, 20, 31)

    for actionId, chip in pairs(hud.actionChips) do
        local actionColor = TunerConfig.Actions[actionId].color
        local isActiveAction = active and feedbackState.actionId == actionId

        chip.stroke.Color = isActiveAction and toneColor or actionColor
        chip.stroke.Thickness = isActiveAction and 3 or 1.5
        chip.frame.BackgroundColor3 = isActiveAction and Color3.fromRGB(20, 34, 34) or Color3.fromRGB(10, 18, 30)
    end

    for problemId, entry in pairs(hud.legendEntries) do
        local isActiveProblem = activeProblemIds[problemId] == true

        entry.image.ImageTransparency = isActiveProblem and 0 or 0.58
        entry.frame.BackgroundTransparency = isActiveProblem and 0.02 or 0.22
        entry.stroke.Transparency = isActiveProblem and 0.08 or 0.72
        entry.stroke.Thickness = isActiveProblem and 2 or 1.2
    end
end

local function updateHud()
    local focusedIds = selectionState:GetFocusedThreadIds()
    local markedIds = selectionState:GetMarkedThreadIds()
    local focusedThreadId = focusedIds[1]
    local focusedProblem = focusedThreadId and threadStates[focusedThreadId].problemId or nil

    setOrbGaugeValue(hud.orbGauge, challengeState.stability, challengeState.memoryProgress)
    updateEdgeWarning(hud.edgeWarning, challengeState.stability, runtimeClock)

    challengeState.statusMessage = focusedThreadId and string.format(
        "Focus %s%s",
        focusedThreadId,
        focusedProblem and string.format(" / %s", focusedProblem) or " / Stable"
    ) or string.format("Focus none / Marked %d", #markedIds)

    updateStatusBanner(runtimeClock)
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

local function getReticleCFrame(centerCFrame, now, spinDirection, phaseOffset)
    local spinPeriod = 1
    local axisPeriod = 8
    local axisAngle = ((now + phaseOffset) / axisPeriod) * math.pi * 2
    local tumbleAxis = Vector3.new(math.cos(axisAngle), 0, math.sin(axisAngle)).Unit
    local spinAngle = (now / spinPeriod) * math.pi * 2 * spinDirection

    return centerCFrame * CFrame.fromAxisAngle(tumbleAxis, spinAngle)
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
    view.selectionLabel.Text = " "
    view.selectionLabel.TextColor3 = isMarked and TunerConfig.Visuals.stableAccentColor or Color3.fromRGB(255, 255, 255)
    view.focusOverlay.billboard.Enabled = false
    view.markedOverlay.billboard.Enabled = false
    view.focusOverlay.image.ImageTransparency = 1
    view.markedOverlay.image.ImageTransparency = 1
    view.focusReticleMesh.CFrame = getReticleCFrame(view.nodeOrb.CFrame, now, 1, state.order * 0.31)
    view.markedGlyphMesh.CFrame = getReticleCFrame(view.nodeOrb.CFrame, now, -1, state.order * 0.31 + 2)
    view.focusReticleMesh.Material = Enum.Material.Neon
    view.markedGlyphMesh.Material = Enum.Material.Neon
    view.focusReticleMesh.Color = TunerConfig.Visuals.stableColor:Lerp(Color3.new(1, 1, 1), 0.18)
    view.markedGlyphMesh.Color = TunerConfig.Visuals.stableAccentColor:Lerp(Color3.new(1, 1, 1), 0.12)
    view.focusReticleMesh.Transparency = operatorState.active and isFocused and 0.46 or 1
    view.markedGlyphMesh.Transparency = operatorState.active and isMarked and 0.4 or 1
    setEmitterState(view.problemEmitter, emitterEnabled, beamColor, emitterRate)
end

function updateAllVisuals(now)
    for _, threadId in ipairs(ThreadState.GetOrderedIds(threadStates)) do
        updateThreadVisual(threadId, now)
    end

    updateHud()
end

local function setStatusMessage(message, tone, actionId, iconKey)
    challengeState.statusMessage = message
    challengeState.statusTone = tone or "Neutral"
    addEventLogMessage(message)

    if tone and tone ~= "Neutral" then
        pulseHud(tone, message, actionId, iconKey)
    end

    updateHud()
end

function checkSessionEnd()
    if not operatorState.active then
        return
    end

    if challengeState.memoryProgress >= TunerConfig.Challenge.targetMemoryProgress then
        addEventLogMessage("MEMORY RESTORED. Releasing operator station.")
        setOperatorMode(false, operatorState.prompt, false)
        resetGameSession("Tuner reset after memory restoration.")
    elseif challengeState.stability <= 0 then
        addEventLogMessage("STABILITY COLLAPSED. Releasing operator station.")
        setOperatorMode(false, operatorState.prompt, false)
        resetGameSession("Tuner reset after stability collapse.")
    end
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
    checkSessionEnd()
end

local function resolveAction(actionId, now)
    local targetIds = selectionState:GetEffectiveTargets()

    if #targetIds == 0 then
        setStatusMessage(string.format("NO TARGET  %s had no thread lock.", actionId), "Warning", actionId, "Warning")
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

    checkSessionEnd()
end

collectThreadViews()
hud = createHud()
addEventLogMessage("Tuner online. Monitoring memory threads.")

local adapter = MouseKeyboardInputAdapter.new(TunerConfig, selectionState, {
    isInputEnabled = function()
        return operatorState.active
    end,
    onSelectionChanged = function()
        updateHud()
    end,
    onActionRequested = function(actionId)
        if not operatorState.active then
            return
        end

        resolveAction(actionId, runtimeClock)
    end,
})

local threadPartsById = {}

for threadId, view in pairs(threadViews) do
    threadPartsById[threadId] = view.nodePart
end

adapter:Start(threadPartsById)

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if (player and player ~= localPlayer) or prompt.Name ~= "OperatorPrompt" then
        return
    end

    setOperatorMode(not operatorState.active, prompt)
end)

localPlayer.CharacterAdded:Connect(function()
    operatorState.active = false

    if operatorState.prompt then
        operatorState.prompt.ActionText = "Tune"
    end
end)

updateAllVisuals(runtimeClock)
tweenWorldPart(prototype.MemoryCore, { Size = Vector3.new(4.6, 4.6, 4.6) }, 1.8)
tweenWorldPart(prototype.CoreGlow, { Size = Vector3.new(7.4, 7.4, 7.4) }, 1.8)

RunService.Heartbeat:Connect(function(deltaTime)
    runtimeClock += deltaTime

    if operatorState.active then
        spawnClock += deltaTime
        expireProblems(runtimeClock)

        if spawnClock >= TunerConfig.Challenge.problemSpawnInterval then
            spawnClock = 0
            spawnProblem(runtimeClock)
        end
    end

    updateAllVisuals(runtimeClock)
end)
