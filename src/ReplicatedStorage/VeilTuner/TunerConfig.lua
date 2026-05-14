local TunerConfig = {}

TunerConfig.SpriteSheets = {
    CoreActionIcons = "rbxassetid://126042074039272",
    StatusAndTargetingIcons = "rbxassetid://134906789981907",
    UIKit = "rbxassetid://131908294208637",
}

TunerConfig.ActionIconRects = {
    Cleanse = { offset = Vector2.new(163, 559), size = Vector2.new(121, 127) },
    Anchor = { offset = Vector2.new(353, 559), size = Vector2.new(122, 127) },
    Harmonize = { offset = Vector2.new(548, 538), size = Vector2.new(122, 148) },
    Vent = { offset = Vector2.new(739, 559), size = Vector2.new(122, 127) },
}

TunerConfig.StatusIconRects = {
    Static = { offset = Vector2.new(106, 283), size = Vector2.new(112, 116) },
    Drift = { offset = Vector2.new(336, 283), size = Vector2.new(120, 116) },
    Dissonance = { offset = Vector2.new(573, 283), size = Vector2.new(120, 116) },
    Overload = { offset = Vector2.new(805, 283), size = Vector2.new(120, 104) },
    Stable = { offset = Vector2.new(106, 580), size = Vector2.new(104, 112) },
    Focused = { offset = Vector2.new(339, 580), size = Vector2.new(113, 113) },
    Marked = { offset = Vector2.new(574, 580), size = Vector2.new(106, 113) },
    Warning = { offset = Vector2.new(805, 580), size = Vector2.new(118, 112) },
}

TunerConfig.StatusFeedbackIconRects = {
    Static = { offset = Vector2.new(78, 129), size = Vector2.new(167, 148) },
    Drift = { offset = Vector2.new(307, 129), size = Vector2.new(167, 148) },
    Dissonance = { offset = Vector2.new(544, 129), size = Vector2.new(167, 148) },
    Overload = { offset = Vector2.new(776, 129), size = Vector2.new(167, 148) },
    Stable = { offset = Vector2.new(78, 426), size = Vector2.new(167, 148) },
    Focused = { offset = Vector2.new(307, 426), size = Vector2.new(167, 148) },
    Marked = { offset = Vector2.new(544, 426), size = Vector2.new(167, 148) },
    Warning = { offset = Vector2.new(776, 426), size = Vector2.new(167, 148) },
}

TunerConfig.StatusFeedbackLabelRects = {
    Static = { offset = Vector2.new(89, 274), size = Vector2.new(145, 44) },
    Drift = { offset = Vector2.new(319, 274), size = Vector2.new(145, 44) },
    Dissonance = { offset = Vector2.new(555, 274), size = Vector2.new(145, 44) },
    Overload = { offset = Vector2.new(788, 274), size = Vector2.new(145, 44) },
    Stable = { offset = Vector2.new(89, 571), size = Vector2.new(145, 44) },
    Focused = { offset = Vector2.new(319, 571), size = Vector2.new(145, 44) },
    Marked = { offset = Vector2.new(555, 571), size = Vector2.new(145, 44) },
    Warning = { offset = Vector2.new(788, 571), size = Vector2.new(145, 44) },
}

TunerConfig.Actions = {
    Cleanse = {
        id = "Cleanse",
        displayName = "Cleanse",
        shortName = "CLEANSE",
        glyph = "+",
        tagline = "Purify",
        iconRect = TunerConfig.ActionIconRects.Cleanse,
        keyCode = Enum.KeyCode.Q,
        color = Color3.fromRGB(255, 214, 120),
    },
    Anchor = {
        id = "Anchor",
        displayName = "Anchor",
        shortName = "ANCHOR",
        glyph = "A",
        tagline = "Secure",
        iconRect = TunerConfig.ActionIconRects.Anchor,
        keyCode = Enum.KeyCode.W,
        color = Color3.fromRGB(95, 225, 255),
    },
    Harmonize = {
        id = "Harmonize",
        displayName = "Harmonize",
        shortName = "HARMONIZE",
        glyph = "H",
        tagline = "Balance",
        iconRect = TunerConfig.ActionIconRects.Harmonize,
        keyCode = Enum.KeyCode.E,
        color = Color3.fromRGB(190, 116, 255),
    },
    Vent = {
        id = "Vent",
        displayName = "Vent",
        shortName = "VENT",
        glyph = "V",
        tagline = "Release",
        iconRect = TunerConfig.ActionIconRects.Vent,
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
        iconKey = "Static",
    },
    Drift = {
        id = "Drift",
        displayName = "Drift",
        correctAction = "Anchor",
        color = Color3.fromRGB(90, 200, 255),
        duration = 7,
        glyph = "=",
        iconKey = "Drift",
    },
    Dissonance = {
        id = "Dissonance",
        displayName = "Dissonance",
        correctAction = "Harmonize",
        color = Color3.fromRGB(190, 100, 255),
        duration = 7,
        glyph = "*",
        iconKey = "Dissonance",
    },
    Overload = {
        id = "Overload",
        displayName = "Overload",
        correctAction = "Vent",
        color = Color3.fromRGB(255, 70, 90),
        duration = 6,
        glyph = "!",
        iconKey = "Overload",
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
