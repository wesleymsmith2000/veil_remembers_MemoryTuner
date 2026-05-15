local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local TunerConfig = require(ReplicatedStorage:WaitForChild("VeilTuner"):WaitForChild("TunerConfig"))

local prototypeName = "TunerPrototype"

local function createFolder(parent, name)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent

    return folder
end

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

local function createRod(parent, name, startPosition, endPosition, thickness, color, material)
    local delta = endPosition - startPosition
    local rod = createPart(
        parent,
        name,
        Vector3.new(thickness, thickness, delta.Magnitude),
        CFrame.lookAt((startPosition + endPosition) / 2, endPosition),
        color,
        material
    )
    rod.CanCollide = false

    return rod
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
local activeLaneIds = { 1, 3, 5, 7 }
local chamberRotationOffset = math.rad(22.5)
local roofCrownHeight = 57
local roofRingHeight = 53
local domeRibBaseHeight = 39
local pylonSupportTopHeight = 27
local roofAnchorRadius = 26
local oculusVerticalOffset = -8
local roofAnchorVerticalOffset = -3
local pylonRadius = 50
local activeLaneOrder = {}

for order, laneId in ipairs(activeLaneIds) do
    activeLaneOrder[laneId] = order
end

local chamber = createFolder(prototype, "Chamber")
local domeRibs = createFolder(chamber, "DomeRibs")
local boundaryWalls = createFolder(chamber, "BoundaryWalls")
local outerPylons = createFolder(chamber, "OuterPylons")
local centralTuner = createFolder(prototype, "CentralTuner")
local tunerAttachments = createFolder(centralTuner, "TunerAttachments")
local memoryLanes = createFolder(prototype, "MemoryLanes")

local base = createPart(
    chamber,
    "ConsoleBase",
    TunerConfig.World.consoleSize,
    worldOrigin * CFrame.new(0, -2.5, 0),
    TunerConfig.Visuals.worldBackground,
    Enum.Material.Slate
)
base.Transparency = 0.08

local consoleDeck = createMeshPart(
    centralTuner,
    "TunerPlatform",
    TunerConfig.Meshes.PhaseACentralTunerPlatform,
    Vector3.new(1, 1, 1),
    worldOrigin * CFrame.new(0, -0.8, 0),
    Color3.fromRGB(20, 28, 42),
    Enum.Material.Metal
)
consoleDeck.Transparency = 0.05
consoleDeck.CanCollide = false

local floorRing = createMeshPart(
    chamber,
    "FloorRing",
    TunerConfig.Meshes.PhaseAChamberFloorRing,
    Vector3.new(1, 1, 1),
    worldOrigin * CFrame.new(0, -1.45, 0),
    Color3.fromRGB(32, 48, 66),
    Enum.Material.Metal
)
floorRing.CanCollide = false

local platformCollider = createPart(
    chamber,
    "PlatformCollider",
    Vector3.new(72, 1.2, 72),
    worldOrigin * CFrame.new(0, -0.65, 0),
    Color3.fromRGB(255, 255, 255),
    Enum.Material.SmoothPlastic
)
platformCollider.Shape = Enum.PartType.Cylinder
platformCollider.Transparency = 1
platformCollider.CanCollide = true

local domeShell = createPart(
    chamber,
    "DomeShell",
    Vector3.new(92, 1.4, 92),
    worldOrigin * CFrame.new(0, 39, 0),
    Color3.fromRGB(12, 20, 33),
    Enum.Material.Glass
)
domeShell.Shape = Enum.PartType.Ball
domeShell.Transparency = 1
domeShell.CanCollide = false
createPointLight(domeShell, Color3.fromRGB(80, 120, 155), 0.5, 75)

local roofOculus = createMeshPart(
    chamber,
    "RoofOculus",
    TunerConfig.Meshes.PhaseARoofOculus,
    Vector3.new(3.45, 1, 3.45),
    worldOrigin * CFrame.new(0, roofCrownHeight + oculusVerticalOffset, 0),
    TunerConfig.Visuals.memoryColor,
    Enum.Material.Neon
)
roofOculus.Transparency = 0.28
roofOculus.CanCollide = false
createPointLight(roofOculus, TunerConfig.Visuals.memoryColor, 1.8, 42)

local oculusSupportRing = createPart(
    chamber,
    "OculusSupportRing",
    Vector3.new(58, 0.35, 58),
    worldOrigin * CFrame.new(0, roofRingHeight + oculusVerticalOffset, 0),
    Color3.fromRGB(70, 92, 118),
    Enum.Material.Neon
)
oculusSupportRing.Shape = Enum.PartType.Cylinder
oculusSupportRing.Transparency = 0.42
oculusSupportRing.CanCollide = false

local oculusGlowRing = createPart(
    chamber,
    "OculusGlowRing",
    Vector3.new(42, 0.18, 42),
    worldOrigin * CFrame.new(0, roofRingHeight + 0.85 + oculusVerticalOffset, 0),
    TunerConfig.Visuals.stableColor,
    Enum.Material.Neon
)
oculusGlowRing.Shape = Enum.PartType.Cylinder
oculusGlowRing.Transparency = 0.28
oculusGlowRing.CanCollide = false

local oculusIntakeLens = createPart(
    chamber,
    "OculusIntakeLens",
    Vector3.new(8.5, 0.22, 8.5),
    worldOrigin * CFrame.new(0, roofCrownHeight + 0.35 + oculusVerticalOffset, 0),
    TunerConfig.Visuals.memoryColor,
    Enum.Material.Glass
)
oculusIntakeLens.Shape = Enum.PartType.Cylinder
oculusIntakeLens.Transparency = 0.18
oculusIntakeLens.CanCollide = false

for laneId = 1, 8 do
    local angle = ((laneId - 1) / 8) * math.pi * 2 - math.pi / 2 + chamberRotationOffset
    local rib = createMeshPart(
        domeRibs,
        string.format("DomeRib_%02d", laneId),
        TunerConfig.Meshes.PhaseADomeRib,
        Vector3.new(2.05, 1.15, 2.05),
        worldOrigin * CFrame.new(0, domeRibBaseHeight, 0) * CFrame.Angles(0, angle, 0),
        Color3.fromRGB(42, 60, 82),
        Enum.Material.Metal
    )
    rib.Transparency = 0.08
end

for wallIndex = 1, 8 do
    local angleA = ((wallIndex - 1) / 8) * math.pi * 2 - math.pi / 2 + chamberRotationOffset
    local angleB = (wallIndex / 8) * math.pi * 2 - math.pi / 2 + chamberRotationOffset
    local positionA = worldOrigin.Position + Vector3.new(math.cos(angleA) * 50.5, 0.9, math.sin(angleA) * 50.5)
    local positionB = worldOrigin.Position + Vector3.new(math.cos(angleB) * 50.5, 0.9, math.sin(angleB) * 50.5)
    local midpoint = (positionA + positionB) / 2
    local length = (positionB - positionA).Magnitude * 0.72
    local wall = createPart(
        boundaryWalls,
        string.format("BoundaryWall_%02d", wallIndex),
        Vector3.new(length, 3.2, 0.8),
        CFrame.lookAt(midpoint, worldOrigin.Position + Vector3.new(0, 0.9, 0)) * CFrame.Angles(0, math.rad(90), 0),
        Color3.fromRGB(18, 23, 32),
        Enum.Material.Metal
    )
    wall.Transparency = 0.22
    wall.CanCollide = false

    local trim = createPart(
        boundaryWalls,
        string.format("BoundaryWallTrim_%02d", wallIndex),
        Vector3.new(length, 0.16, 0.92),
        wall.CFrame * CFrame.new(0, 1.68, 0),
        TunerConfig.Visuals.panelAccentDim,
        Enum.Material.Neon
    )
    trim.Transparency = 0.34
    trim.CanCollide = false
end

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
    centralTuner,
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

local function createThreadBeam(parent, name, attachment0, attachment1, width0, width1, color, transparency)
    local beam = Instance.new("Beam")
    beam.Name = name
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.Width0 = width0
    beam.Width1 = width1
    beam.Color = ColorSequence.new(color)
    beam.Transparency = NumberSequence.new(transparency or 0)
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.FaceCamera = true
    beam.TextureSpeed = 0.25
    beam.Parent = parent

    return beam
end

local function catmullRom(p0, p1, p2, p3, t)
    local t2 = t * t
    local t3 = t2 * t

    return (p1 * 2 + (p2 - p0) * t + (p0 * 2 - p1 * 5 + p2 * 4 - p3) * t2
        + (-p0 + p1 * 3 - p2 * 3 + p3) * t3) * 0.5
end

local function sampleCatmullRomPath(points, samplesPerSpan)
    local sampledPoints = {}

    for spanIndex = 1, #points - 1 do
        local p0 = points[math.max(spanIndex - 1, 1)]
        local p1 = points[spanIndex]
        local p2 = points[spanIndex + 1]
        local p3 = points[math.min(spanIndex + 2, #points)]

        for sampleIndex = 0, samplesPerSpan - 1 do
            table.insert(sampledPoints, catmullRom(p0, p1, p2, p3, sampleIndex / samplesPerSpan))
        end
    end

    table.insert(sampledPoints, points[#points])

    return sampledPoints
end

for laneId = 1, 8 do
    local activeOrder = activeLaneOrder[laneId]
    local isActive = activeOrder ~= nil
    local laneName = string.format("Lane_%02d", laneId)
    local threadId = isActive and string.format("Thread_%02d", activeOrder) or nil
    local angle = ((laneId - 1) / 8) * math.pi * 2 - math.pi / 2 + chamberRotationOffset
    local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
    local laneColor = isActive and TunerConfig.Visuals.stableColor or Color3.fromRGB(42, 62, 82)
    local laneAccent = isActive and TunerConfig.Visuals.stableAccentColor or Color3.fromRGB(82, 68, 42)
    local laneModel = Instance.new("Model")
    laneModel.Name = laneName
    laneModel:SetAttribute("LaneId", laneId)
    laneModel:SetAttribute("IsActive", isActive)
    laneModel:SetAttribute("State", isActive and "ActiveStable" or "Dormant")

    if threadId then
        laneModel:SetAttribute("ThreadId", threadId)
    end

    laneModel.Parent = memoryLanes

    local controlNodes = createFolder(laneModel, "ControlNodes")
    local threadVisuals = createFolder(laneModel, "ThreadVisuals")
    createFolder(laneModel, "PulseContainer")
    local interaction = createFolder(laneModel, "Interaction")

    local crystalPosition = worldOrigin.Position + direction * 27 + Vector3.new(0, 2.2, 0)
    local pylonPosition = worldOrigin.Position + direction * pylonRadius + Vector3.new(0, 4.1, 0)
    local roofPosition = worldOrigin.Position + direction * roofAnchorRadius + Vector3.new(0, roofRingHeight + roofAnchorVerticalOffset, 0)
    local tunerPosition = memoryCore.Position + direction * 1.45

    local roofAnchor = createMeshPart(
        laneModel,
        string.format("RoofAnchor_%02d", laneId),
        isActive and TunerConfig.Meshes.PhaseARoofAnchorActive or TunerConfig.Meshes.PhaseARoofAnchorDormant,
        Vector3.new(1.2, 1.2, 1.2),
        CFrame.new(roofPosition),
        laneColor,
        Enum.Material.Neon
    )
    roofAnchor.Transparency = isActive and 0.18 or 0.72
    roofAnchor.CanCollide = false
    local roofAttachment = createAttachment(roofAnchor, string.format("RoofAttachment_%02d", laneId), Vector3.new())

    local roofAnchorMarker = createPart(
        laneModel,
        string.format("RoofAnchorMarker_%02d", laneId),
        Vector3.new(1.25, 1.25, 1.25),
        CFrame.new(roofPosition),
        laneColor,
        Enum.Material.Neon
    )
    roofAnchorMarker.Shape = Enum.PartType.Ball
    roofAnchorMarker.Transparency = isActive and 0.25 or 0.75
    roofAnchorMarker.CanCollide = false

    local pylonModel = Instance.new("Model")
    pylonModel.Name = string.format("Pylon_%02d", laneId)
    pylonModel.Parent = outerPylons

    local anchorPart = createPart(
        laneModel,
        "AnchorPart",
        Vector3.new(2.5, 6, 2.5),
        CFrame.new(pylonPosition),
        Color3.fromRGB(24, 33, 48),
        Enum.Material.Metal
    )
    anchorPart.Transparency = isActive and 0.12 or 0.42

    local pylonShell = createMeshPart(
        pylonModel,
        string.format("PylonMesh_%02d", laneId),
        isActive and TunerConfig.Meshes.PhaseAPerimeterPylonActive or TunerConfig.Meshes.PhaseAPerimeterPylonDormant,
        Vector3.new(1.75, 2.35, 1.75),
        anchorPart.CFrame,
        Color3.fromRGB(32, 45, 62),
        Enum.Material.Metal
    )
    pylonShell.Transparency = isActive and 0.04 or 0.58

    local pylonLink = Instance.new("ObjectValue")
    pylonLink.Name = string.format("PylonLink_%02d", laneId)
    pylonLink.Value = pylonShell
    pylonLink.Parent = laneModel

    local anchorTop = createPart(
        laneModel,
        "AnchorCap",
        Vector3.new(5.6, 0.65, 5.6),
        anchorPart.CFrame * CFrame.new(0, 8.4, 0),
        laneAccent,
        Enum.Material.Neon
    )
    anchorTop.Transparency = isActive and 0.08 or 0.68
    anchorTop.CanCollide = false

    local pylonSupport = createRod(
        laneModel,
        string.format("PylonDomeSupport_%02d", laneId),
        pylonPosition + Vector3.new(0, 8.6, 0),
        worldOrigin.Position + direction * pylonRadius + Vector3.new(0, pylonSupportTopHeight, 0),
        0.52,
        Color3.fromRGB(46, 66, 90),
        Enum.Material.Metal
    )
    pylonSupport.Transparency = isActive and 0.12 or 0.52

    local ribPylonConnector = createRod(
        laneModel,
        string.format("RibPylonConnector_%02d", laneId),
        worldOrigin.Position + direction * pylonRadius + Vector3.new(0, pylonSupportTopHeight, 0),
        worldOrigin.Position + direction * roofAnchorRadius + Vector3.new(0, roofRingHeight + roofAnchorVerticalOffset, 0),
        0.18,
        laneColor,
        Enum.Material.Neon
    )
    ribPylonConnector.Transparency = isActive and 0.34 or 0.9

    local pedestal = createMeshPart(
        laneModel,
        string.format("CrystalPedestal_%02d", laneId),
        isActive and TunerConfig.Meshes.PhaseACrystalPedestalActive or TunerConfig.Meshes.PhaseACrystalPedestalDormant,
        Vector3.new(1, 1, 1),
        CFrame.new(crystalPosition - Vector3.new(0, 1.25, 0)),
        isActive and Color3.fromRGB(32, 38, 50) or Color3.fromRGB(22, 26, 34),
        Enum.Material.Metal
    )
    pedestal.Transparency = isActive and 0.02 or 0.5
    pedestal.CanCollide = false

    local pedestalTrim = createPart(
        laneModel,
        string.format("PedestalTrim_%02d", laneId),
        Vector3.new(5.2, 0.16, 5.2),
        pedestal.CFrame * CFrame.new(0, 1.18, 0),
        laneAccent,
        Enum.Material.Neon
    )
    pedestalTrim.Shape = Enum.PartType.Cylinder
    pedestalTrim.Transparency = isActive and 0.06 or 0.86
    pedestalTrim.CanCollide = false

    local crystal = createMeshPart(
        laneModel,
        string.format("MemoryCrystal_%02d", laneId),
        isActive and TunerConfig.Meshes.PhaseAMemoryCrystalActive or TunerConfig.Meshes.PhaseAMemoryCrystalDormant,
        Vector3.new(1.5, 1.5, 1.5),
        CFrame.new(crystalPosition),
        laneColor,
        Enum.Material.Neon
    )
    crystal.Transparency = isActive and 0.02 or 0.82
    crystal.CanCollide = false
    local crystalAttachment = createAttachment(crystal, string.format("CrystalAttachment_%02d", laneId), Vector3.new())

    if isActive then
        createPointLight(crystal, laneColor, 1.8, 22)
    else
        createPointLight(crystal, Color3.fromRGB(45, 70, 95), 0.25, 8)
    end

    local nodePositions = {
        { name = "RoofAnchorNode", position = roofPosition },
        { name = "UpperTwistNode", position = worldOrigin.Position + direction * 22 + Vector3.new(0, 46, 0) },
        { name = "MiddleTwistNode", position = worldOrigin.Position + direction * 24 + Vector3.new(0, 31, 0) },
        { name = "LowerTwistNode", position = worldOrigin.Position + direction * 25 + Vector3.new(0, 14, 0) },
        { name = "CrystalAnchorNode", position = crystalPosition },
    }

    for _, nodeInfo in ipairs(nodePositions) do
        local node = createPart(
            controlNodes,
            string.format("%s_%02d", nodeInfo.name, laneId),
            Vector3.new(0.55, 0.55, 0.55),
            CFrame.new(nodeInfo.position),
            laneColor,
            Enum.Material.Neon
        )
        node.Shape = Enum.PartType.Ball
        node.Transparency = isActive and 0.62 or 0.9
        node.CanCollide = false

        local pathAttachment = createAttachment(
            node,
            string.format("%sAttachment_%02d", nodeInfo.name, laneId),
            Vector3.new()
        )
    end

    local tunerAnchor = createPart(
        tunerAttachments,
        string.format("TunerAttachment_%02d", laneId),
        Vector3.new(0.45, 0.45, 0.45),
        CFrame.new(tunerPosition),
        laneColor,
        Enum.Material.Neon
    )
    tunerAnchor.Shape = Enum.PartType.Ball
    tunerAnchor.Transparency = 1
    tunerAnchor.CanCollide = false
    local tunerAttachment = createAttachment(tunerAnchor, string.format("TunerAttachment_%02d", laneId), Vector3.new())

    local descentSamples = createFolder(threadVisuals, "DescentThreadSamples")
    local descentSegments = createFolder(threadVisuals, "DescentThreadSegments")
    local descentControlPoints = {}

    for _, nodeInfo in ipairs(nodePositions) do
        table.insert(descentControlPoints, nodeInfo.position)
    end

    local sampledDescentPoints = sampleCatmullRomPath(descentControlPoints, isActive and 4 or 2)
    local descentPathAttachments = {}

    for sampleIndex, samplePosition in ipairs(sampledDescentPoints) do
        local samplePart = createPart(
            descentSamples,
            string.format("DescentSample_%02d", sampleIndex),
            Vector3.new(0.18, 0.18, 0.18),
            CFrame.new(samplePosition),
            laneColor,
            Enum.Material.Neon
        )
        samplePart.Shape = Enum.PartType.Ball
        samplePart.Transparency = isActive and 0.82 or 0.96
        samplePart.CanCollide = false
        samplePart:SetAttribute("LaneId", laneId)
        samplePart:SetAttribute("SampleIndex", sampleIndex)

        local sampleAttachment = createAttachment(
            samplePart,
            string.format("DescentSampleAttachment_%02d", sampleIndex),
            Vector3.new()
        )
        table.insert(descentPathAttachments, sampleAttachment)
    end

    for segmentIndex = 1, #descentPathAttachments - 1 do
        local segment = createThreadBeam(
            descentSegments,
            string.format("Beam_Main_%02d", segmentIndex),
            descentPathAttachments[segmentIndex],
            descentPathAttachments[segmentIndex + 1],
            isActive and 0.32 or 0.04,
            isActive and 0.26 or 0.035,
            laneColor,
            isActive and 0.02 or 1
        )
        segment.Enabled = isActive
        segment:SetAttribute("LaneId", laneId)
        segment:SetAttribute("SegmentIndex", segmentIndex)

        local glowSegment = createThreadBeam(
            descentSegments,
            string.format("Beam_Glow_%02d", segmentIndex),
            descentPathAttachments[segmentIndex],
            descentPathAttachments[segmentIndex + 1],
            isActive and 0.88 or 0.08,
            isActive and 0.7 or 0.06,
            laneAccent,
            isActive and 0.62 or 1
        )
        glowSegment.Enabled = isActive
        glowSegment:SetAttribute("LaneId", laneId)
        glowSegment:SetAttribute("SegmentIndex", segmentIndex)
    end

    local descentThread = createThreadBeam(
        threadVisuals,
        "DescentThread",
        roofAttachment,
        crystalAttachment,
        isActive and 0.02 or 0.04,
        isActive and 0.02 or 0.03,
        laneColor,
        isActive and 0.96 or 1
    )
    descentThread.Enabled = false

    local convergenceThread = createThreadBeam(
        threadVisuals,
            "ConvergenceThread",
        crystalAttachment,
        tunerAttachment,
        isActive and 0.18 or 0.05,
        isActive and 0.14 or 0.04,
        laneColor,
        isActive and 0.38 or 1
    )
    convergenceThread.Enabled = isActive

    local dormantPreview = createThreadBeam(
        threadVisuals,
        "DormantThreadPreview",
        roofAttachment,
        tunerAttachment,
        0.035,
        0.025,
        Color3.fromRGB(30, 48, 70),
        0.975
    )
    dormantPreview.Enabled = not isActive

    local nodePosition = crystalPosition + direction * -2 + Vector3.new(0, 2.8, 0)

    local nodeOrb = createPart(
        laneModel,
        "NodeOrb",
        isActive and Vector3.new(2.15, 2.15, 2.15) or Vector3.new(1.2, 1.2, 1.2),
        CFrame.new(nodePosition),
        laneColor,
        Enum.Material.Neon
    )
    nodeOrb.Shape = Enum.PartType.Ball
    nodeOrb.Transparency = isActive and 0.08 or 0.9
    nodeOrb.CanCollide = false

    if threadId then
        nodeOrb:SetAttribute("ThreadId", threadId)
        createPointLight(nodeOrb, TunerConfig.Visuals.stableColor, 2.1, 18)
    end

    local focusReticle = createMeshPart(
        laneModel,
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
        laneModel,
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
        interaction,
        string.format("NodePart_%02d", laneId),
        isActive and Vector3.new(7.2, 7.2, 7.2) or Vector3.new(4.6, 4.6, 4.6),
        nodeOrb.CFrame,
        Color3.new(1, 1, 1),
        Enum.Material.SmoothPlastic
    )
    nodePart.Transparency = 1
    nodePart.CanCollide = false
    nodePart.CanTouch = false

    if threadId then
        nodePart:SetAttribute("ThreadId", threadId)
    end

    local coreAttachment

    if isActive then
        coreAttachment = createAttachment(memoryCore, string.format("CoreAttachment_%02d", activeOrder), Vector3.new(
            direction.X * 1.4,
            math.sin(activeOrder) * 0.35,
            direction.Z * 1.4
        ))
        convergenceThread.Attachment1 = coreAttachment
    end

    local beam = createThreadBeam(
        threadVisuals,
        "ThreadBeam",
        crystalAttachment,
        coreAttachment or tunerAttachment,
        isActive and 0.18 or 0.05,
        isActive and 0.14 or 0.04,
        laneColor,
        isActive and 0.42 or 1
    )
    beam.Enabled = isActive

    local auraBeam = createThreadBeam(
        threadVisuals,
        "AuraBeam",
        crystalAttachment,
        coreAttachment or tunerAttachment,
        isActive and 0.42 or 0.1,
        isActive and 0.34 or 0.08,
        laneAccent,
        isActive and 0.82 or 1
    )
    auraBeam.Enabled = isActive

    local labelGui = Instance.new("BillboardGui")
    labelGui.Name = "ThreadBillboard"
    labelGui.Adornee = crystal
    labelGui.AlwaysOnTop = true
    labelGui.Enabled = isActive
    labelGui.Size = UDim2.fromOffset(64, 28)
    labelGui.StudsOffset = Vector3.new(0, 3.1, 0)
    labelGui.Parent = nodeOrb

    local nameLabel = createLabel(
        labelGui,
        "NameLabel",
        UDim2.fromScale(1, 1),
        UDim2.fromScale(0, 0),
        threadId and string.format("T%02d", laneId) or "",
        14,
        laneAccent
    )
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center

    local statusLabel = createLabel(
        labelGui,
        "StatusLabel",
        UDim2.fromScale(1, 0),
        UDim2.fromScale(0, 1),
        "",
        1,
        laneColor
    )
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.TextTransparency = 1
    statusLabel.TextStrokeTransparency = 1

    local selectionLabel = createLabel(
        labelGui,
        "SelectionLabel",
        UDim2.fromScale(1, 0),
        UDim2.fromScale(0, 1),
        "",
        1,
        Color3.fromRGB(255, 255, 255)
    )
    selectionLabel.TextXAlignment = Enum.TextXAlignment.Center
    selectionLabel.TextTransparency = 1
    selectionLabel.TextStrokeTransparency = 1

    local problemEmitter = Instance.new("ParticleEmitter")
    problemEmitter.Name = "ProblemEmitter"
    problemEmitter.Color = ColorSequence.new(TunerConfig.Visuals.stableColor)
    problemEmitter.LightEmission = 1
    problemEmitter.Lifetime = NumberRange.new(0.25, 0.45)
    problemEmitter.Rate = 0
    problemEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.16),
        NumberSequenceKeypoint.new(0.5, 0.42),
        NumberSequenceKeypoint.new(1, 0),
    })
    problemEmitter.Speed = NumberRange.new(1.1, 2.4)
    problemEmitter.SpreadAngle = Vector2.new(70, 70)
    problemEmitter.Parent = nodeOrb
end

prototype.PrimaryPart = consoleDeck
