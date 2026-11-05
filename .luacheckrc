std = "lua51"
max_line_length = false
self = false
exclude_files = { "tests/" }

globals = {
    "EzOOCDB",
    "EzOOCCharDB",
    "EzOOC_ToggleBox",
    "SLASH_EZOOC1",
    "SLASH_EZOOC2",
    "SLASH_EZOOCREPLY1",
    "SlashCmdList",
    "BINDING_HEADER_EZOOC",
    "BINDING_NAME_EZOOC_BOX",
}

read_globals = {
    -- Frames & UI
    "CreateFrame", "UIParent", "DEFAULT_CHAT_FRAME", "ChatFontNormal", "EventRegistry",
    -- Settings panel
    "Settings", "CreateSettingsListSectionHeaderInitializer", "CreateSettingsButtonInitializer",
    -- Chat filters (ChatFrameUtil on newer clients)
    "ChatFrameUtil", "ChatFrame_AddMessageEventFilter",
    -- Namespaced APIs
    "C_ChatInfo", "issecretvalue",
    -- Global APIs
    "GetBuildInfo", "GetTime", "UnitName", "UnitExists", "UnitIsPlayer", "SendChatMessage", "InCombatLockdown",
    "IsInGroup", "IsInRaid", "IsInGuild", "GetNumGroupMembers", "ChatTypeInfo",
}
