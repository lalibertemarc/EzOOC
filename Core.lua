-- EzOOC: say a line out of character, in (( )), from /ooc or the key binding's box, and answer someone's OOC line
-- with a click on its [Reply].
local _, ns = ...

BINDING_HEADER_EZOOC = "EzOOC"
BINDING_NAME_EZOOC_BOX = "Open the OOC box"

local Trim = ns.Trim

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff8fd3ffEzOOC|r: " .. msg)
end
ns.Print = Print

local function issecret(v)
    return issecretvalue and issecretvalue(v)
end
ns.issecret = issecret

---------------------------------------------------------------------------
-- Chat. Only ever called from a slash command or a key press in the box, which give the send its hardware event;
-- never from a timer or an event (Forever blocks those).
---------------------------------------------------------------------------
local function Send(msg, chatType, target)
    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        C_ChatInfo.SendChatMessage(msg, chatType, nil, target)
    else
        SendChatMessage(msg, chatType, nil, target)
    end
end

-- Encounters and similar lock addon chat (C_ChatInfo.InChatMessagingLockdown). A real game block:
-- SendChatMessage then raises ADDON_ACTION_BLOCKED.
local function ChatLocked()
    return C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()
end

-- A line past 255 bytes goes out in pieces, but Forever lets a key press say only one message in a public channel
-- (ns.ONE_PER_PRESS): a second SendChatMessage in the same press is blocked. So the first piece goes now and the
-- rest wait here, one per press: Enter in the box (it opens for them) or /ooc more. Escape in the box, or a new
-- line, drops them.
local waiting  -- { chatType, target, pieces = { ... } }, nil when nothing waits

local function Waiting()
    return waiting and #waiting.pieces or 0
end
ns.Waiting = Waiting

local function DropWaiting(quiet)
    if waiting and not quiet then Print(("Dropped the rest of your line (%d more)."):format(#waiting.pieces)) end
    waiting = nil
end
ns.DropWaiting = DropWaiting

local function WaitingNote()
    local n = Waiting()
    if n == 0 then return end
    Print(("%d more to say: press Enter in the box (or /ooc more) for each, Escape drops %s."):format(n,
        n == 1 and "it" or "them"))
end

local function SendPieces(pieces, chatType, target)
    DropWaiting()
    if not ns.ONE_PER_PRESS[chatType] then
        for _, msg in ipairs(pieces) do Send(msg, chatType, target) end
        return
    end
    Send(pieces[1], chatType, target)
    if #pieces < 2 then return end
    waiting = { chatType = chatType, target = target, pieces = { select(2, unpack(pieces)) } }
    WaitingNote()
    ns.OpenBox()
end

-- The next waiting piece (a key press or slash only). False when nothing waits.
local function SendNext()
    if not waiting then return false end
    if ChatLocked() then
        Print("The game blocks addon chat right now.")
        return true
    end
    Send(table.remove(waiting.pieces, 1), waiting.chatType, waiting.target)
    if #waiting.pieces == 0 then waiting = nil end
    return true
end
ns.SendNext = SendNext

---------------------------------------------------------------------------
-- People. Forever names have surnames and whispers need "First Surname", so a typed first name is looked up among
-- the people you'd likely whisper: your target, who spoke out of character lately, those you whispered with
-- (EzOOCCharDB.whispers, newest first) and your group.
---------------------------------------------------------------------------
local function UnitFullName(unit)
    local exists, isPlayer = UnitExists(unit), UnitIsPlayer(unit)
    if issecret(exists) or issecret(isPlayer) or not (exists and isPlayer) then return end
    local first, surname = UnitName(unit)
    if not first or issecret(first) then return end
    if surname and not issecret(surname) and surname ~= "" then
        return first .. (ns.ERA and "-" or " ") .. surname
    end
    return first
end

local function NameKey(name)
    return (name:match("^[^%s%-]+") or name):lower()
end
ns.NameKey = NameKey

-- Is a chat author you?
function ns.IsMe(author)
    if type(author) ~= "string" or issecret(author) then return false end
    local me = UnitName("player")
    return me ~= nil and not issecret(me) and NameKey(author) == me:lower()
end

local function GroupUnits()
    local units, n = {}, GetNumGroupMembers() or 0
    if IsInRaid() then
        for i = 1, n do units[#units + 1] = "raid" .. i end
    else
        for i = 1, n - 1 do units[#units + 1] = "party" .. i end
    end
    return units
end

-- Who spoke out of character lately, newest first (this session): { author, kind, name, first, t }.
local speakers = {}
ns.speakers = speakers
local answeredAt = -math.huge  -- GetTime() of your last OOC line

function ns.Heard(kind, author)
    local name = ns.WhisperName(author, ns.ERA)
    local key = NameKey(name)
    for i = #speakers, 1, -1 do
        if NameKey(speakers[i].name) == key then table.remove(speakers, i) end
    end
    table.insert(speakers, 1, { author = author, kind = kind, name = name, first = ns.FirstName(name), t = GetTime() })
    for i = #speakers, ns.SPEAKERS_MAX + 1, -1 do speakers[i] = nil end
end

-- The channel (and whom it whispers) an answer to speaker goes to.
function ns.ReplyTarget(s)
    local chatType = ns.ReplyChannel(s.kind, EzOOCDB.answer)
    return chatType, chatType == "WHISPER" and s.name or nil
end

-- The newest OOC line still waiting for your answer, when the box should open on it (EzOOCDB.follow).
function ns.Pending()
    local s = speakers[1]
    if EzOOCDB.follow and s and s.t > answeredAt and GetTime() - s.t <= ns.REPLY_WINDOW then return s end
end

-- "Bob (party)"
function ns.SpeakerLabel(s)
    return s.first .. " (" .. (ns.KIND_LABEL[s.kind] or s.kind:lower()) .. ")"
end

-- { { name, why }, ... }: each person once, never you.
local function WhisperNames()
    local list, seen = {}, {}
    local me = UnitName("player")
    if me and not issecret(me) then seen[NameKey(me)] = true end
    local function add(name, why)
        if name and not seen[NameKey(name)] then
            seen[NameKey(name)] = true
            list[#list + 1] = { name = name, why = why }
        end
    end
    add(UnitFullName("target"), "target")
    for _, s in ipairs(speakers) do add(s.name, "ooc") end
    for _, name in ipairs(EzOOCCharDB and EzOOCCharDB.whispers or {}) do add(name, "whispered") end
    for _, unit in ipairs(GroupUnits()) do add(UnitFullName(unit), "group") end
    return list
end
ns.WhisperNames = WhisperNames

-- The name to whisper for one typed: %t is your target, a lone first name someone above has gets their surname,
-- anything else goes out as typed. nil: nobody (%t without a target).
local function ResolveName(name)
    name = Trim(name)
    if name == "%t" then return UnitFullName("target") end
    if name == "" then return end
    if name:find("%s") then return name end
    for _, p in ipairs(WhisperNames()) do
        if NameKey(p.name) == NameKey(name) then return p.name end
    end
    return name
end
ns.ResolveName = ResolveName

-- A whisper's author, kept for the box's names: "First-Surname" in Forever, made "First Surname".
local function Remember(author)
    if not EzOOCCharDB or type(author) ~= "string" or issecret(author) or author == "" then return end
    local name = ns.WhisperName(author, ns.ERA)
    local list = EzOOCCharDB.whispers
    for i = #list, 1, -1 do
        if NameKey(list[i]) == NameKey(name) then table.remove(list, i) end
    end
    table.insert(list, 1, name)
    for i = #list, ns.RECENT_MAX + 1, -1 do list[i] = nil end
end

---------------------------------------------------------------------------
-- Saying it
---------------------------------------------------------------------------
-- A whisper's name and the text after it: "First Surname" in quotes, or a name as ResolveName takes it (a surname
-- typed after a first name it filled in is skipped).
local function WhisperTarget(rest)
    local quoted, text = rest:match('^"([^"]+)"%s+(.+)$')
    if quoted then return quoted, text end
    local name
    name, text = rest:match("^(%S+)%s+(.+)$")
    if not name then return end
    local full = ResolveName(name)
    if not full then return end
    local surname = full ~= name and full:match("^[^%s%-]+[%s%-](.+)$")
    local typed, after = text:match("^(%S+)%s+(.+)$")
    if surname and typed and typed:lower() == surname:lower() then text = after end
    return full, text
end

local function Say(text, chatType, target)
    local lines = ns.Lines(text, EzOOCDB.spaced)
    if #lines == 0 then return Print("Nothing to say.") end
    if chatType == "WHISPER" and not target then return Print("Whisper whom? /ooc w <name> <text>") end
    if ChatLocked() then return Print("The game blocks addon chat right now.") end
    answeredAt = GetTime()
    SendPieces(lines, chatType, target)
end
ns.Say = Say

-- An OOC line of yours went out some other way (EzLines): the newest speaker counts as answered.
function ns.Answered()
    answeredAt = GetTime()
end

-- rest of a /ooc <letter> or box /<channel> line
local function SayTo(chatType, rest)
    if chatType == "WHISPER" then
        local target, text = WhisperTarget(Trim(rest))
        if not target then return Print("Whisper whom? /ooc w <name> <text> (or %t for your target)") end
        return Say(text, chatType, target)
    end
    Say(rest, chatType)
end
ns.SayTo = SayTo

-- /ooc reply <text>: answers the last one who spoke out of character, however long ago.
local function Reply(text)
    local s = speakers[1]
    if not s then return Print("Nobody has spoken out of character yet.") end
    if Trim(text) == "" then return ns.OpenReply(s) end
    local chatType, to = ns.ReplyTarget(s)
    Say(text, chatType, to)
end

---------------------------------------------------------------------------
-- Options (EzOOCDB): spaced, follow, link, answer
---------------------------------------------------------------------------
local function Preview()
    Print("Your lines go out like this:")
    for _, msg in ipairs(ns.Lines(ns.SAMPLE, EzOOCDB.spaced)) do DEFAULT_CHAT_FRAME:AddMessage("  " .. msg) end
end
ns.Preview = Preview

local function Switch(key, arg, cmd, onText, offText)
    arg = Trim(arg):lower()
    if arg == "on" then
        EzOOCDB[key] = true
    elseif arg == "off" then
        EzOOCDB[key] = false
    elseif arg == "" then
        EzOOCDB[key] = not EzOOCDB[key]
    else
        return Print("Use /ooc " .. cmd .. " on, or /ooc " .. cmd .. " off.")
    end
    Print(EzOOCDB[key] and onText or offText)
end

local function SetAnswer(arg)
    arg = Trim(arg):lower()
    if arg == "same" or arg == "whisper" then EzOOCDB.answer = arg
    elseif arg ~= "" then return Print("Use /ooc answer same, or /ooc answer whisper.") end
    Print(EzOOCDB.answer == "whisper" and "You answer OOC lines in a whisper."
        or "You answer OOC lines where they were said (say for say, party for party...).")
end

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------
local function OpenSettings()
    if InCombatLockdown() then return Print("Options can't open in combat.") end
    if ns.settingsCategory then Settings.OpenToCategory(ns.settingsCategory:GetID()) end
end

local HELP = {
    "/ooc <text> - say (( <text> ))",
    "/ooc y|p|g|o|r|e <text> - yell, party, guild, officer, raid or emote it (/ooc s <text> to say a line that starts with a command word)",
    "/ooc w <name> <text> - whisper it (\"First Surname\", %t, or the first name of your target, someone who spoke OOC, whispered with you or is in your group)",
    "/ooc more - say the next piece of a line too long for one message (the box's Enter does too)",
    "/ooc reply [text] - answer the last one who spoke out of character (also /oocr), or open the box on them",
    "/ooc answer same|whisper - answer where they said it, or always in a whisper",
    "/ooc link [on|off] - a [Reply] link after other people's OOC lines",
    "/ooc follow [on|off] - the box opens on the last OOC line waiting for your answer",
    "/ooc spaces [on|off] - (( like this )) or ((like this))",
    "/ooc box - the edit box (also a key binding: Options > Keybindings > EzOOC)",
    "/ooc config - the options page (Options > AddOns > EzOOC)",
}

local function Help()
    Print("Out of character lines, in (( )).")
    for _, line in ipairs(HELP) do DEFAULT_CHAT_FRAME:AddMessage("  " .. line) end
end

-- Command words are lowercase only, so a sentence starting "Reply" or "Box" is said.
local COMMANDS = {
    help = Help,
    reply = Reply,
    more = function()
        if not SendNext() then return Print("Nothing waits to be said.") end
        WaitingNote()
    end,
    answer = SetAnswer,
    link = function(arg) Switch("link", arg, "link", "OOC lines get a [Reply] link.", "No more [Reply] links.") end,
    follow = function(arg)
        Switch("follow", arg, "follow", "The box opens on the last OOC line waiting for your answer.",
            "The box stays on its own channel; [Reply] or /ooc reply still answer.")
    end,
    spaces = function(arg)
        Switch("spaced", arg, "spaces", "Lines go out (( like this )).", "Lines go out ((like this)).")
    end,
    preview = Preview,
    box = function() ns.FocusBox() end,
    config = OpenSettings,
}

SLASH_EZOOC1 = "/ooc"
SLASH_EZOOC2 = "/ezooc"
SlashCmdList.EZOOC = function(msg)
    msg = Trim(msg)
    if msg == "" then return Help() end
    local cmd, rest = msg:match("^(%S+)%s*(.*)$")
    if COMMANDS[cmd] then return COMMANDS[cmd](rest) end
    local chatType = ns.SHORT_CHANNELS[cmd]
    if chatType then return SayTo(chatType, rest) end
    Say(msg, "SAY")
end

SLASH_EZOOCREPLY1 = "/oocr"
SlashCmdList.EZOOCREPLY = Reply

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("CHAT_MSG_WHISPER")
ev:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
ev:SetScript("OnEvent", function(_, event, ...)
    if event ~= "PLAYER_LOGIN" then return Remember((select(2, ...))) end
    EzOOCDB = EzOOCDB or {}
    local defaults = { spaced = true, follow = true, link = true, answer = "same" }
    for k, v in pairs(defaults) do
        if EzOOCDB[k] == nil then EzOOCDB[k] = v end
    end
    EzOOCCharDB = EzOOCCharDB or {}
    if type(EzOOCCharDB.whispers) ~= "table" then EzOOCCharDB.whispers = {} end
    ns.BuildSettings()
end)
