-- EzOOC smoke test, plain Lua 5.1 with the WoW API stubbed. From the EzOOC folder: lua tests/smoke.lua
-- Checks what counts as OOC, bracketing and cutting long lines, where answers go, the [Reply] link, and the slash
-- commands, chat filter and box end to end.
local failures, checks = 0, 0
local function check(ok, msg)
    checks = checks + 1
    if not ok then
        failures = failures + 1
        print("FAIL: " .. msg)
    end
end
local function eq(got, want, msg)
    check(got == want, msg .. ": got " .. tostring(got) .. ", want " .. tostring(want))
end

---------------------------------------------------------------------------
-- WoW stubs
---------------------------------------------------------------------------
local printed, sent, filters, events, callbacks = {}, {}, {}, {}, {}
local named = {}
local now = 1000
local locked = false
local player = { name = "Grukk", surname = "Stonefist" }
local target
local group = {}  -- party1, party2 ...: { name, surname }

local function Stub(name)
    local f = { scripts = {}, name = name, shown = false, text = "" }
    if name then named[name] = f end
    return setmetatable(f, { __index = function(_, k)
        if k == "SetScript" then return function(self, s, fn) self.scripts[s] = fn end end
        if k == "Show" then return function(self) self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end end
        if k == "Hide" then return function(self) self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end end
        if k == "IsShown" then return function(self) return self.shown end end
        if k == "SetText" then return function(self, t) self.text = t end end
        if k == "GetText" then return function(self) return self.text end end
        if k == "RegisterEvent" then return function(self, e) events[e] = events[e] or {}; table.insert(events[e], self) end end
        if k == "CreateFontString" or k == "CreateTexture" then return function() return Stub() end end
        if k == "HasFocus" then return function(self) return self.focus end end
        if k == "SetFocus" then return function(self) self.focus = true end end
        if k == "ClearFocus" then return function(self) self.focus = false end end
        if k == "GetPoint" then return function() return "BOTTOM", nil, "BOTTOM", 0, 240 end end
        return function() end
    end })
end

function GetBuildInfo() return "1.60.1", "70707", "", 16001 end
function GetTime() return now end
function CreateFrame(_, name) return Stub(name) end
UIParent = Stub("UIParent")
ChatFontNormal = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) printed[#printed + 1] = m end }
ChatFrameUtil = { AddMessageEventFilter = function(event, fn) filters[event] = fn end }
EventRegistry = { RegisterCallback = function(_, event, fn) callbacks[event] = fn end }
C_ChatInfo = {
    SendChatMessage = function(msg, chatType, _, to) sent[#sent + 1] = { msg = msg, chatType = chatType, to = to } end,
    InChatMessagingLockdown = function() return locked end,
}
function issecretvalue() return false end
local function UnitOf(unit)
    if unit == "player" then return player end
    if unit == "target" then return target end
    local i = unit:match("^party(%d)$")
    return i and group[tonumber(i)]
end
function UnitExists(unit) return UnitOf(unit) ~= nil end
function UnitIsPlayer(unit) return UnitOf(unit) ~= nil end
function UnitName(unit)
    local u = UnitOf(unit)
    if u then return u.name, u.surname end
end
function IsInGroup() return #group > 0 end
function IsInRaid() return false end
function IsInGuild() return true end
function GetNumGroupMembers() return #group > 0 and #group + 1 or 0 end
function InCombatLockdown() return false end
SlashCmdList = {}
Settings = {}
ChatTypeInfo = {}

local ns = {}
for _, file in ipairs({ "Data.lua", "Ooc.lua", "Core.lua", "Listen.lua", "Box.lua" }) do
    local chunk = assert(loadfile(file))
    chunk("EzOOC", ns)
end
ns.BuildSettings = function() end
for _, f in ipairs(events.PLAYER_LOGIN) do f.scripts.OnEvent(f, "PLAYER_LOGIN") end

local function Slash(msg) SlashCmdList.EZOOC(msg) end
local function Last() return sent[#sent] end
local function Fire(event, msg, author)
    for _, f in ipairs(events[event] or {}) do f.scripts.OnEvent(f, event, msg, author) end
end

---------------------------------------------------------------------------
-- What counts as OOC
---------------------------------------------------------------------------
for _, msg in ipairs({ "((brb))", "(( brb ))", "sure ((afk a sec))", "OOC: brb", "ooc - brb", "[OOC] dinner",
                       "((no end" }) do
    check(ns.IsOOC(msg), "OOC: " .. msg)
end
for _, msg in ipairs({ "Hello there.", "I (sort of) agree", "Tycoon: hi", "the oocyte", "(smiles)" }) do
    check(not ns.IsOOC(msg), "not OOC: " .. msg)
end

---------------------------------------------------------------------------
-- Bracketing and cutting
---------------------------------------------------------------------------
local function only(t) eq(#t, 1, "one line"); return t[1] end
eq(only(ns.Lines("brb", true)), "(( brb ))", "spaced")
eq(only(ns.Lines("brb", false)), "((brb))", "unspaced")
eq(only(ns.Lines("((brb))", true)), "(( brb ))", "typed brackets kept once")
eq(only(ns.Lines("  ((  brb  ))  ", false)), "((brb))", "typed spaced brackets")
eq(only(ns.Lines("((brb", true)), "(( brb ))", "typed opening only")
eq(#ns.Lines("   ", true), 0, "nothing")
eq(#ns.Lines("(( ))", true), 0, "empty brackets")

local words = {}
for i = 1, 120 do words[i] = "word" .. i end
local long = table.concat(words, " ")
local lines = ns.Lines(long, true)
check(#lines >= 3, "a long line goes out in pieces")
local back = {}
for _, l in ipairs(lines) do
    check(#l <= 255, "piece within 255 bytes: " .. #l)
    local inner = l:match("^%(%( (.+) %)%)$")
    check(inner ~= nil, "piece bracketed: " .. l)
    back[#back + 1] = inner
end
eq(table.concat(back, " "), long, "pieces join back")

local link = "|cff1eff00|Hitem:6948::::::::|h[Hearthstone of the Long Road]|h|r"
local withLink = string.rep("x", 230) .. " " .. link .. " after"
for _, l in ipairs(ns.Lines(withLink, true)) do
    check(not l:find("|H") or l:find(link, 1, true), "link kept whole: " .. l)
end

local accented = string.rep("é", 300)  -- 600 bytes, no spaces
local cut = ns.Lines(accented, false)
local joined = ""
for _, l in ipairs(cut) do
    check(#l <= 255, "cut word within 255 bytes")
    local inner = l:sub(3, -3)
    check(not inner:byte(1) or inner:byte(1) < 0x80 or inner:byte(1) >= 0xC0, "cut between letters")
    joined = joined .. inner
end
eq(joined, accented, "cut word joins back")

---------------------------------------------------------------------------
-- Where answers go, the link
---------------------------------------------------------------------------
eq(ns.ReplyChannel("SAY", "same"), "SAY", "say -> say")
eq(ns.ReplyChannel("EMOTE", "same"), "SAY", "emote -> say")
eq(ns.ReplyChannel("PARTY_LEADER", "same"), "PARTY", "party leader -> party")
eq(ns.ReplyChannel("RAID_WARNING", "same"), "RAID", "raid warning -> raid")
eq(ns.ReplyChannel("GUILD", "whisper"), "WHISPER", "whisper answer")
eq(ns.ReplyChannel("CHANNEL", "same"), nil, "no answer in channels")
eq(ns.WhisperName("Alice-Jones", false), "Alice Jones", "Forever whisper name")
eq(ns.WhisperName("Alice-Stormrage", true), "Alice-Stormrage", "Era whisper name")
local kind, author = ns.ParseLink((ns.ReplyLink("PARTY", "Alice-Jones"):match("|H(.-)|h")))
eq(kind, "PARTY", "link kind")
eq(author, "Alice-Jones", "link author")
eq(ns.ParseLink("addon:EzChronicle:3"), nil, "another addon's link")
eq(ns.ParseLink("addon:EzOOC:CHANNEL:Bob"), nil, "unknown kind")

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
Slash("brb")
eq(Last().msg, "(( brb ))", "/ooc says")
eq(Last().chatType, "SAY", "/ooc channel")
Slash("p pulling in 5")
eq(Last().chatType, "PARTY", "/ooc p")
eq(Last().msg, "(( pulling in 5 ))", "/ooc p text")
target = { name = "Bob", surname = "Smith" }
Slash("w bob smith you there?")
eq(Last().chatType, "WHISPER", "/ooc w")
eq(Last().to, "Bob Smith", "/ooc w fills the surname")
eq(Last().msg, "(( you there? ))", "/ooc w skips the typed surname")
Slash("Reply hazy, try again")
eq(Last().msg, "(( Reply hazy, try again ))", "capitalized command word is said")
local count = #sent
locked = true
Slash("blocked")
eq(#sent, count, "chat lockdown sends nothing")
locked = false

---------------------------------------------------------------------------
-- Hearing OOC lines
---------------------------------------------------------------------------
Fire("CHAT_MSG_SAY", "Hello there.", "Alice-Jones")
eq(#ns.speakers, 0, "an IC line isn't kept")
Fire("CHAT_MSG_SAY", "((is this the RP event?))", "Alice-Jones")
eq(ns.speakers[1] and ns.speakers[1].name, "Alice Jones", "OOC speaker kept")
Fire("CHAT_MSG_SAY", "((yes))", "Grukk-Stonefist")
eq(ns.speakers[1].name, "Alice Jones", "your own line isn't kept")

local ok, msg = filters.CHAT_MSG_SAY(nil, "CHAT_MSG_SAY", "((is this the RP event?))", "Alice-Jones")
check(ok == false and msg:find("|Haddon:EzOOC:SAY:Alice-Jones|h", 1, true), "filter adds [Reply]")
local r1, r2 = filters.CHAT_MSG_SAY(nil, "CHAT_MSG_SAY", "Hello there.", "Alice-Jones")
check(r1 == false and r2 == nil, "filter leaves IC lines alone")
r1, r2 = filters.CHAT_MSG_SAY(nil, "CHAT_MSG_SAY", "((yes))", "Grukk-Stonefist")
check(r1 == false and r2 == nil, "no [Reply] on your own line")
EzOOCDB.link = false
r1, r2 = filters.CHAT_MSG_SAY(nil, "CHAT_MSG_SAY", "((hi))", "Alice-Jones")
check(r1 == false and r2 == nil, "links off")
EzOOCDB.link = true

SlashCmdList.EZOOCREPLY("yes, at the inn")
eq(Last().chatType, "SAY", "/oocr answers in say")
eq(Last().msg, "(( yes, at the inn ))", "/oocr text")
EzOOCDB.answer = "whisper"
SlashCmdList.EZOOCREPLY("or whisper")
eq(Last().chatType, "WHISPER", "/oocr in a whisper")
eq(Last().to, "Alice Jones", "/oocr whispers them")
EzOOCDB.answer = "same"

---------------------------------------------------------------------------
-- The box
---------------------------------------------------------------------------
local box, edit = function() return named.EzOOCBox end, function() return named.EzOOCBoxEdit end
local function Type(text)
    edit().text = text
    edit().scripts.OnEnterPressed(edit())
end

group = { { name = "Carl", surname = "Reed" } }
now = now + 10
Fire("CHAT_MSG_PARTY", "((one sec, door))", "Carl-Reed")
EzOOC_ToggleBox("down")
check(not box(), "the key's press does nothing")
EzOOC_ToggleBox("up")
check(box() and box().shown, "the key's release opens the box")
check(edit().focus, "the box has the keyboard")
Type("np")
eq(Last().chatType, "PARTY", "box opens on the waiting line's channel")
eq(Last().msg, "(( np ))", "box brackets")
check(not box().shown, "Enter closes the box")

EzOOC_ToggleBox("up")
Type("/s anyone up for a duel?")
eq(Last().chatType, "SAY", "box /s line")
eq(Last().msg, "(( anyone up for a duel? ))", "box /s text")

now = now + 10
callbacks.SetItemRef(nil, "addon:EzOOC:WHISPER:Dan-Brown")
check(box().shown, "[Reply] opens the box")
eq(ns.speakers[1].name, "Dan Brown", "[Reply] makes them the newest speaker")
Type("sure")
eq(Last().chatType, "WHISPER", "[Reply] to a whisper whispers")
eq(Last().to, "Dan Brown", "[Reply] whispers them")

now = now + 10
Fire("CHAT_MSG_GUILD", "OOC: anyone online?", "Eve-Hart")
now = now + ns.REPLY_WINDOW + 1
EzOOC_ToggleBox("up")
Type("me")
eq(Last().chatType, "WHISPER", "an old line doesn't move the box")
EzOOCDB.follow = false
now = now + 1
Fire("CHAT_MSG_GUILD", "OOC: anyone?", "Eve-Hart")
EzOOC_ToggleBox("up")
Type("still me")
eq(Last().chatType, "WHISPER", "follow off keeps the box's channel")
EzOOCDB.follow = true

print(("%d checks, %d failures"):format(checks, failures))
if failures > 0 then os.exit(1) end
