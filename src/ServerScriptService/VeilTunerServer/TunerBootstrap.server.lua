local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local TunerConfig = require(ReplicatedStorage:WaitForChild("VeilTuner"):WaitForChild("TunerConfig"))

local prototypeName = "TunerPrototype"

local function createPart(parent, name, size, cframe, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent

    return part
end

local function createAttachment(parent, name, position)
    local attachment = Instance.new("Attachment")
    attachment.Name = name
    attachment.Position = position
    attachment.Parent = parent

    return attachment
end

local function createPointLight(parent, color, brightness, range)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = brightness
    light.Range = range
    light.Shadows = false
    light.Parent = parent

    return light
end

local function createLabel(parent, name, size, position, text, textSize, color)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.TextColor3 = color
    label.TextScaled = false
    label.TextSize = textSize
    label.TextStrokeTransparency = 0.4
    label.Parent = parent

    return label
end

local existingPrototype = Workspace:FindFirstChild(prototypeName)

if existingPrototype then
    existingPrototype:Destroy()
end

Workspace.Terrain.WaterColor = TunerConfig.Visuals.worldBackground
Lighting.Ambient = Color3.fromRGB(18, 22, 34)
Lighting.OutdoorAmbient = Color3.fromRGB(8, 12, 22)
Lighting.Brightness = 1.6
Lighting.ClockTime = 0

local prototype = Instance.new("Model")
prototype.Name = prototypeName
prototype.Parent = Workspace

local worldOrigin = TunerConfig.World.origin
local base = createPart(
    prototype,
    "ConsoleBase",
    TunerConfig.World.consoleSize,
    worldOrigin * CFrame.new(0, -2.5, 0),
    TunerConfig.Visuals.worldBackground,
    Enum.Material.Slate
)

local consoleDeck = createPart(
    prototype,
    "ConsoleDeck",
    Vector3.new(20, 1, 20),
    worldOrigin * CFrame.new(0, -0.8, 0),
    Color3.fromRGB(20, 28, 42),
    Enum.Material.Metal
)

local memoryCore = createPart(
    prototype,
    "MemoryCore",
    Vector3.new(4, 4, 4),
    worldOrigin * CFrame.new(0, 2, 0),
    TunerConfig.Visuals.stableAccentColor,
    Enum.Material.Neon
)
memoryCore.Shape = Enum.PartType.Ball

local coreGlow = createPart(
    prototype,
    "CoreGlow",
    Vector3.new(6, 6, 6),
    memoryCore.CFrame,
    TunerConfig.Visuals.stableColor,
    Enum.Material.ForceField
)
coreGlow.Shape = Enum.PartType.Ball
coreGlow.Transparency = 0.55
coreGlow.CanCollide = false
createPointLight(memoryCore, TunerConfig.Visuals.stableAccentColor, 2.6, 26)

local threadsFolder = Instance.new("Folder")
threadsFolder.Name = "Threads"
threadsFolder.Parent = prototype

for index = 1, TunerConfig.Challenge.threadCount do
    local angle = ((index - 1) / TunerConfig.Challenge.threadCount) * math.pi * 2 - math.pi / 2
    local threadId = string.format("Thread_%02d", index)
    local threadModel = Instance.new("Model")
    threadModel.Name = threadId
    threadModel:SetAttribute("ThreadId", threadId)
    threadModel.Parent = threadsFolder

    local anchorPosition = worldOrigin.Position + Vector3.new(
        math.cos(angle) * TunerConfig.World.threadRadius,
        0,
        math.sin(angle) * TunerConfig.World.threadRadius
    )

    local anchorPart = createPart(
        threadModel,
        "AnchorPart",
        Vector3.new(2.5, 6, 2.5),
        CFrame.new(anchorPosition + Vector3.new(0, 1, 0)),
        Color3.fromRGB(24, 33, 48),
        Enum.Material.Metal
    )

    local anchorTop = createPart(
        threadModel,
        "AnchorCap",
        Vector3.new(3.4, 0.8, 3.4),
        anchorPart.CFrame * CFrame.new(0, 3.2, 0),
        TunerConfig.Visuals.stableAccentColor,
        Enum.Material.Neon
    )
    anchorTop.CanCollide = false

    local nodePosition = ((anchorPosition + Vector3.new(0, 4.2, 0)) + memoryCore.Position) / 2
    nodePosition = nodePosition + Vector3.new(0, TunerConfig.World.nodeHeight - 4, 0)

    local nodeOrb = createPart(
        threadModel,
        "NodeOrb",
        Vector3.new(1.2, 1.2, 1.2),
        CFrame.new(nodePosition),
        TunerConfig.Visuals.stableColor,
        Enum.Material.Neon
    )
    nodeOrb.Shape = Enum.PartType.Ball
    nodeOrb.CanCollide = false
    nodeOrb:SetAttribute("ThreadId", threadId)
    createPointLight(nodeOrb, TunerConfig.Visuals.stableColor, 1.2, 12)

    local nodePart = createPart(
        threadModel,
        "NodePart",
        Vector3.new(4.6, 4.6, 4.6),
        nodeOrb.CFrame,
        Color3.new(1, 1, 1),
        Enum.Material.SmoothPlastic
    )
    nodePart.Transparency = 1
    nodePart.CanCollide = false
    nodePart.CanTouch = false
    nodePart:SetAttribute("ThreadId", threadId)

    local anchorAttachment = createAttachment(anchorTop, "AnchorAttachment", Vector3.new(0, 0.45, 0))
    local coreAttachment = createAttachment(memoryCore, string.format("CoreAttachment_%02d", index), Vector3.new(
        math.cos(angle) * 1.4,
        math.sin(index) * 0.35,
        math.sin(angle) * 1.4
    ))

    local beam = Instance.new("Beam")
    beam.Name = "ThreadBeam"
    beam.Attachment0 = anchorAttachment
    beam.Attachment1 = coreAttachment
    beam.Width0 = 0.26
    beam.Width1 = 0.2
    beam.Color = ColorSequence.new(TunerConfig.Visuals.stableColor)
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.FaceCamera = true
    beam.TextureSpeed = 0.25
    beam.Parent = threadModel

    local auraBeam = Instance.new("Beam")
    auraBeam.Name = "AuraBeam"
    auraBeam.Attachment0 = anchorAttachment
    auraBeam.Attachment1 = coreAttachment
    auraBeam.Width0 = 0.7
    auraBeam.Width1 = 0.55
    auraBeam.Transparency = NumberSequence.new(0.8)
    auraBeam.Color = ColorSequence.new(TunerConfig.Visuals.stableAccentColor)
    auraBeam.LightEmission = 1
    auraBeam.LightInfluence = 0
    auraBeam.FaceCamera = true
    auraBeam.Parent = threadModel

    local labelGui = Instance.new("BillboardGui")
    labelGui.Name = "ThreadBillboard"
    labelGui.Adornee = nodeOrb
    labelGui.AlwaysOnTop = true
    labelGui.Size = UDim2.fromOffset(150, 84)
    labelGui.StudsOffset = Vector3.new(0, 2.7, 0)
    labelGui.Parent = nodeOrb

    local nameLabel = createLabel(
        labelGui,
        "NameLabel",
        UDim2.fromScale(1, 0.32),
        UDim2.fromScale(0, 0),
        string.format("THREAD %02d", index),
        18,
        TunerConfig.Visuals.stableAccentColor
    )
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center

    local statusLabel = createLabel(
        labelGui,
        "StatusLabel",
        UDim2.fromScale(1, 0.28),
        UDim2.fromScale(0, 0.34),
        "Stable",
        16,
        TunerConfig.Visuals.stableColor
    )
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center

    local selectionLabel = createLabel(
        labelGui,
        "SelectionLabel",
        UDim2.fromScale(1, 0.26),
        UDim2.fromScale(0, 0.66),
        "",
        18,
        Color3.fromRGB(255, 255, 255)
    )
    selectionLabel.TextXAlignment = Enum.TextXAlignment.Center

    local problemEmitter = Instance.new("ParticleEmitter")
    problemEmitter.Name = "ProblemEmitter"
    problemEmitter.Color = ColorSequence.new(TunerConfig.Visuals.stableColor)
    problemEmitter.LightEmission = 1
    problemEmitter.Lifetime = NumberRange.new(0.25, 0.45)
    problemEmitter.Rate = 0
    problemEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.08),
        NumberSequenceKeypoint.new(0.5, 0.22),
        NumberSequenceKeypoint.new(1, 0),
    })
    problemEmitter.Speed = NumberRange.new(0.8, 1.8)
    problemEmitter.SpreadAngle = Vector2.new(70, 70)
    problemEmitter.Parent = nodeOrb
end

prototype.PrimaryPart = consoleDeck
