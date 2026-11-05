-- Options page: Esc > Options > AddOns > EzOOC. Built at login, once the saved variables exist.
local _, ns = ...

function ns.BuildSettings()
    local category, layout = Settings.RegisterVerticalLayoutCategory("EzOOC")
    ns.settingsCategory = category

    local function Header(text)
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
    end

    local function Button(name, text, onClick, tooltip)
        layout:AddInitializer(CreateSettingsButtonInitializer(name, text, onClick, tooltip, false))
    end

    local function Checkbox(variable, key, label, default, tooltip)
        local setting = Settings.RegisterAddOnSetting(category, variable, key, EzOOCDB, Settings.VarType.Boolean,
            label, default)
        Settings.CreateCheckbox(category, setting, tooltip)
    end

    Header("Your lines")
    Checkbox("EZOOC_SPACED", "spaced", "Spaces inside the brackets", true,
        "On: (( like this )). Off: ((like this)).")
    Button("Sample line", "Preview", function() ns.Preview() end, "Prints a sample line as it would go out. Only you see it.")

    Header("Answering")
    Checkbox("EZOOC_LINK", "link", "[Reply] after OOC lines", true,
        "Other people's lines in (( )), or starting with OOC:, get a [Reply] link in your chat. Click it to answer them in the box.")
    Checkbox("EZOOC_FOLLOW", "follow", "Open the box on a line waiting for my answer", true,
        "When someone spoke out of character in the last two minutes and you haven't said anything OOC since, the box opens on their channel.")
    local answer = Settings.RegisterAddOnSetting(category, "EZOOC_ANSWER", "answer", EzOOCDB,
        Settings.VarType.String, "Answer them", "same")
    Settings.CreateDropdown(category, answer, function()
        local container = Settings.CreateControlTextContainer()
        for _, a in ipairs(ns.ANSWERS) do container:Add(a.key, a.label, a.desc) end
        return container:GetData()
    end, "Where an answer goes: the channel they spoke in, or always a whisper to them.")

    Header("The box")
    Button("OOC box", "Open", function() ns.OpenBox() end,
        "A small edit box of its own: Enter says the line in (( )), a leading /y, /p, /w name... picks the channel, Escape closes it. Drag it to move it.")
    Button("Box position", "Reset", function() ns.ResetBox() end, "Puts the box back above your action bars.")
    -- No inline binding rows or search tags: they taint the options search in Forever.
    Button("Key binding", "Key Bindings",
        function() Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID, "EzOOC") end,
        "Bind a key to open the box in the EzOOC section of the Key Bindings page.")

    Settings.RegisterAddOnCategory(category)
end
