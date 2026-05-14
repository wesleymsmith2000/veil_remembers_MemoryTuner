local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

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

local function createMeshPart(parent, name, meshId, size, cframe, color, material)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = Vector3.new(1, 1, 1)
    part.CFrame = cframe
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0.18
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent

    local mesh = Instance.new("SpecialMesh")
    mesh.Name = "Mesh"
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = meshId
    mesh.Scale = size
    mesh.Parent = part

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

local function createPrompt(parent, actionText, objectText)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "OperatorPrompt"
    prompt.ActionText = actionText
    prompt.ObjectText = objectText
    prompt.HoldDuration = 0.15
    prompt.KeyboardKeyCode = Enum.KeyCode.F
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 10
    prompt.Parent = parent

    return prompt
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
Lighting.Ambient = Color3.fromRGB(55, 65, 82)
Lighting.OutdoorAmbient = Color3.fromRGB(35, 45, 62)
Lighting.Brightness = 2.4
Lighting.ClockTime = 14

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
base.Transparency = 0.08

local consoleDeck = createPart(
    prototype,
    "ConsoleDeck",
    Vector3.new(64, 1, 64),
    worldOrigin * CFrame.new(0, -0.8, 0),
    Color3.fromRGB(20, 28, 42),
    Enum.Material.Metal
)
consoleDeck.Transparency = 0.05

local floorRing = createMeshPart(
    prototype,
    "TunerFloorRingMesh",
    TunerConfig.Meshes.FloorRing,
    Vector3.new(56, 1, 56),
    worldOrigin * CFrame.new(0, -1.45, 0),
    Color3.fromRGB(32, 48, 66),
    Enum.Material.Metal
)
floorRing.CanCollide = false

local platformCollider = createPart(
    prototype,
    "PlatformCollider",
    Vector3.new(64, 1.2, 64),
    worldOrigin * CFrame.new(0, -0.65, 0),
    Color3.fromRGB(255, 255, 255),
    Enum.Material.SmoothPlastic
)
platformCollider.Shape = Enum.PartType.Cylinder
platformCollider.Transparency = 1
platformCollider.CanCollide = true

local memoryCore = createPart(
    prototype,
    "MemoryCore",
    Vector3.new(4, 4, 4),
    worldOrigin * CFrame.new(0, 2, 0),
    TunerConfig.Visuals.stableAccentColor,
    Enum.Material.Neon
)
memoryCore.Shape = Enum.PartType.Ball
memoryCore.Transparency = 0

local memoryCoreMesh = createMeshPart(
    prototype,
    "MemoryCoreCrystalMesh",
    TunerConfig.Meshes.MemoryCoreCrystal,
    Vector3.new(4.2, 4.2, 4.2),
    memoryCore.CFrame,
    TunerConfig.Visuals.stableAccentColor,
    Enum.Material.Neon
)
memoryCoreMesh.CanCollide = false

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

local operatorStation = Instance.new("Model")
operatorStation.Name = "OperatorStation"
operatorStation.Parent = prototype

local stationPosition = worldOrigin.Position + Vector3.new(0, 6.1, 40)
local approachSpawnCFrame = CFrame.lookAt(
    stationPosition + Vector3.new(0, 0.1, 1.7),
    worldOrigin.Position + Vector3.new(0, 3, 0)
)
local spawnLocation = Instance.new("SpawnLocation")
spawnLocation.Name = "OperatorApproachSpawn"
spawnLocation.Size = Vector3.new(7.5, 0.45, 4.5)
spawnLocation.CFrame = approachSpawnCFrame
spawnLocation.Anchored = true
spawnLocation.Neutral = true
spawnLocation.AllowTeamChangeOnTouch = false
spawnLocation.Duration = 0
spawnLocation.Color = Color3.fromRGB(20, 32, 46)
spawnLocation.Material = Enum.Material.Metal
spawnLocation.Parent = prototype

local function placeCharacterAtOperatorSpawn(character)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 6)
    if not humanoidRootPart then
        return
    end

    character:PivotTo(approachSpawnCFrame * CFrame.new(0, 3.4, 0))
end

local function bindOperatorSpawn(player)
    if player.Character then
        task.defer(placeCharacterAtOperatorSpawn, player.Character)
    end

    player.CharacterAdded:Connect(function(character)
        placeCharacterAtOperatorSpawn(character)
    end)
end

for _, player in Players:GetPlayers() do
    bindOperatorSpawn(player)
end

Players.PlayerAdded:Connect(bindOperatorSpawn)

local standPart = createPart(
    operatorStation,
    "OperatorStand",
    Vector3.new(7.2, 0.35, 4.8),
    CFrame.new(stationPosition),
    Color3.fromRGB(18, 28, 42),
    Enum.Material.Metal
)
standPart:SetAttribute("TunerOperatorStand", true)

local standGlow = createPart(
    operatorStation,
    "OperatorStandGlow",
    Vector3.new(6.5, 0.08, 4.1),
    standPart.CFrame * CFrame.new(0, 0.22, 0),
    TunerConfig.Visuals.stableColor,
    Enum.Material.Neon
)
standGlow.Transparency = 0.55
standGlow.CanCollide = false

local lockPoint = createPart(
    operatorStation,
    "OperatorLockPoint",
    Vector3.new(1, 0.2, 1),
    CFrame.lookAt(stationPosition + Vector3.new(0, 2.2, 0), worldOrigin.Position + Vector3.new(0, 3.2, 0)),
    Color3.fromRGB(255, 255, 255),
    Enum.Material.SmoothPlastic
)
lockPoint.Transparency = 1
lockPoint.CanCollide = false
lockPoint:SetAttribute("TunerOperatorLockPoint", true)

local consoleBase = createPart(
    operatorStation,
    "OperatorConsole",
    Vector3.new(6.8, 2.1, 1.8),
    CFrame.lookAt(stationPosition + Vector3.new(0, 1.05, -2.45), worldOrigin.Position + Vector3.new(0, 2.5, 0)),
    Color3.fromRGB(16, 24, 36),
    Enum.Material.Metal
)
consoleBase.Transparency = 0.08

local consoleMesh = createMeshPart(
    operatorStation,
    "OperatorConsoleMesh",
    TunerConfig.Meshes.TunerConsole,
    Vector3.new(7.4, 3.2, 3.6),
    consoleBase.CFrame,
    Color3.fromRGB(20, 31, 44),
    Enum.Material.Metal
)
consoleMesh.CanCollide = false

local consoleFace = createPart(
    operatorStation,
    "OperatorConsoleFace",
    Vector3.new(6, 0.12, 1.25),
    consoleBase.CFrame * CFrame.new(0, 0.55, -0.82) * CFrame.Angles(math.rad(-18), 0, 0),
    Color3.fromRGB(8, 18, 28),
    Enum.Material.Glass
)
consoleFace.CanCollide = false

local consoleLight = createPart(
    operatorStation,
    "OperatorConsoleLight",
    Vector3.new(5.2, 0.08, 0.16),
    consoleFace.CFrame * CFrame.new(0, 0.1, -0.42),
    TunerConfig.Visuals.stableAccentColor,
    Enum.Material.Neon
)
consoleLight.CanCollide = false
createPointLight(consoleLight, TunerConfig.Visuals.stableAccentColor, 0.85, 10)
createPrompt(consoleBase, "Tune", "Memory Tuner")

for index = 1, TunerConfig.Challenge.threadCount do
    local angle = ((index - 1) / TunerConfig.Challenge.threadCount) * math.pi * 2 - math.pi / 2
        + TunerConfig.World.threadAngleOffset
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
    anchorPart.Transparency = 0.12

    local anchorMesh = createMeshPart(
        threadModel,
        "AnchorPylonMesh",
        TunerConfig.Meshes.ThreadAnchorPylon,
        Vector3.new(3.2, 5.6, 3.2),
        anchorPart.CFrame,
        Color3.fromRGB(32, 45, 62),
        Enum.Material.Metal
    )
    anchorMesh.CanCollide = false

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

    local focusReticle = createMeshPart(
        threadModel,
        "FocusReticleMesh",
        TunerConfig.Meshes.FocusReticle,
        Vector3.new(4.7, 4.7, 0.18),
        nodeOrb.CFrame,
        TunerConfig.Visuals.stableColor,
        Enum.Material.Neon
    )
    focusReticle.Transparency = 1
    focusReticle.CanCollide = false
    focusReticle.CastShadow = false

    local markedGlyph = createMeshPart(
        threadModel,
        "MarkedGlyphMesh",
        TunerConfig.Meshes.FocusReticle,
        Vector3.new(4.15, 4.15, 0.18),
        nodeOrb.CFrame,
        TunerConfig.Visuals.stableAccentColor,
        Enum.Material.Neon
    )
    markedGlyph.Transparency = 1
    markedGlyph.CanCollide = false
    markedGlyph.CastShadow = false

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
