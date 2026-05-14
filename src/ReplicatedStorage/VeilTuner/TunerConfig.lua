local TunerConfig = {}

TunerConfig.Actions = {
    Cleanse = {
        id = "Cleanse",
        displayName = "Cleanse",
        shortName = "CLEANSE",
        glyph = "+",
        tagline = "Purify",
        keyCode = Enum.KeyCode.Q,
        color = Color3.fromRGB(255, 214, 120),
    },
    Anchor = {
        id = "Anchor",
        displayName = "Anchor",
        shortName = "ANCHOR",
        glyph = "A",
        tagline = "Secure",
        keyCode = Enum.KeyCode.W,
        color = Color3.fromRGB(95, 225, 255),
    },
    Harmonize = {
        id = "Harmonize",
        displayName = "Harmonize",
        shortName = "HARMONIZE",
        glyph = "H",
        tagline = "Balance",
        keyCode = Enum.KeyCode.E,
        color = Color3.fromRGB(190, 116, 255),
    },
    Vent = {
        id = "Vent",
        displayName = "Vent",
        shortName = "VENT",
        glyph = "V",
        tagline = "Release",
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
    memoryColor = Color3.fromRGB(178, 102, 255),
    warningColor = Color3.fromRGB(255, 92, 74),
    textColor = Color3.fromRGB(244, 238, 222),
    mutedTextColor = Color3.fromRGB(178, 198, 214),
    focusGlyph = "(O)",
    markGlyph = "<>",
    defaultStatusGlyph = ".",
    successColor = Color3.fromRGB(118, 255, 176),
    errorColor = Color3.fromRGB(255, 92, 74),
    panelBackground = Color3.fromRGB(5, 10, 18),
    panelAccent = Color3.fromRGB(224, 171, 76),
    panelAccentDim = Color3.fromRGB(96, 68, 34),
    worldBackground = Color3.fromRGB(5, 8, 15),
    feedbackDuration = 1.15,
}

TunerConfig.World = {
    origin = CFrame.new(0, 6, 0),
    threadRadius = 18,
    nodeHeight = 7,
    consoleSize = Vector3.new(30, 2, 30),
}

return TunerConfig
