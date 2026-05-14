local TunerConfig = {}

TunerConfig.Actions = {
    Cleanse = {
        id = "Cleanse",
        displayName = "Cleanse",
        keyCode = Enum.KeyCode.Q,
        color = Color3.fromRGB(120, 220, 255),
    },
    Anchor = {
        id = "Anchor",
        displayName = "Anchor",
        keyCode = Enum.KeyCode.W,
        color = Color3.fromRGB(255, 210, 105),
    },
    Harmonize = {
        id = "Harmonize",
        displayName = "Harmonize",
        keyCode = Enum.KeyCode.E,
        color = Color3.fromRGB(185, 120, 255),
    },
    Vent = {
        id = "Vent",
        displayName = "Vent",
        keyCode = Enum.KeyCode.R,
        color = Color3.fromRGB(255, 90, 100),
    },
}

TunerConfig.ActionOrder = {
    "Cleanse",
    "Anchor",
    "Harmonize",
    "Vent",
}

TunerConfig.Problems = {
    Static = {
        id = "Static",
        displayName = "Static",
        correctAction = "Cleanse",
        color = Color3.fromRGB(220, 220, 255),
        duration = 7,
        glyph = "~",
    },
    Drift = {
        id = "Drift",
        displayName = "Drift",
        correctAction = "Anchor",
        color = Color3.fromRGB(90, 200, 255),
        duration = 7,
        glyph = "=",
    },
    Dissonance = {
        id = "Dissonance",
        displayName = "Dissonance",
        correctAction = "Harmonize",
        color = Color3.fromRGB(190, 100, 255),
        duration = 7,
        glyph = "*",
    },
    Overload = {
        id = "Overload",
        displayName = "Overload",
        correctAction = "Vent",
        color = Color3.fromRGB(255, 70, 90),
        duration = 6,
        glyph = "!",
    },
}

TunerConfig.ProblemOrder = {
    "Static",
    "Drift",
    "Dissonance",
    "Overload",
}

TunerConfig.Challenge = {
    threadCount = 4,
    startingStability = 100,
    targetMemoryProgress = 100,
    correctProgressGain = 8,
    correctStabilityGain = 1,
    wrongStabilityPenalty = 5,
    emptyTargetPenalty = 1,
    expiredProblemPenalty = 8,
    problemSpawnInterval = 3.5,
    maxSimultaneousProblems = 1,
    pulseDuration = 0.4,
}

TunerConfig.Visuals = {
    stableColor = Color3.fromRGB(102, 196, 255),
    stableAccentColor = Color3.fromRGB(255, 214, 120),
    focusGlyph = "(O)",
    markGlyph = "<>",
    defaultStatusGlyph = ".",
    successColor = Color3.fromRGB(120, 255, 170),
    errorColor = Color3.fromRGB(255, 110, 110),
    panelBackground = Color3.fromRGB(10, 16, 26),
    panelAccent = Color3.fromRGB(48, 102, 125),
    worldBackground = Color3.fromRGB(8, 11, 18),
}

TunerConfig.World = {
    origin = CFrame.new(0, 6, 0),
    threadRadius = 18,
    nodeHeight = 7,
    consoleSize = Vector3.new(30, 2, 30),
}

return TunerConfig
