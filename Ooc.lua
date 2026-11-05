-- EzOOC's rules, no game API: what counts as out of character, how a line is bracketed and cut, where an answer goes,
-- and the [Reply] link. tests/smoke.lua runs these in plain Lua 5.1.
local _, ns = ...

local MAX = 255  -- chat message limit, in bytes

local function Trim(s)
    return (s or ""):match("^%s*(.-)%s*$")
end
ns.Trim = Trim

-- Does msg look out of character (ns.OOC_MARKS)?
function ns.IsOOC(msg)
    if type(msg) ~= "string" then return false end
    for _, mark in ipairs(ns.OOC_MARKS) do
        if msg:find(mark) then return true end
    end
    return false
end

-- Brackets you typed yourself go, so "((brb))" isn't sent as "(( ((brb)) ))".
local function Unbracket(text)
    text = Trim(text)
    local inner = text:match("^%(%((.-)%)%)$")
    if inner then return Trim(inner) end
    return Trim((text:gsub("^%(%(", ""):gsub("%)%)$", "")))
end
ns.Unbracket = Unbracket

-- Item, spell and player links (|c...|H...|h[...]|h|r) are kept whole when a line is cut (their names have spaces):
-- they're swapped for \1N\2 while it works.
local function Protect(text)
    local saved = {}
    local function keep(s)
        saved[#saved + 1] = s
        return "\1" .. #saved .. "\2"
    end
    text = text:gsub("|c%x%x%x%x%x%x%x%x|H.-|h.-|h|r", keep)
    text = text:gsub("|H.-|h.-|h", keep)
    return text, saved
end

local function Restore(text, saved)
    return (text:gsub("\1(%d+)\2", function(n) return saved[tonumber(n)] end))
end

-- A word too long for one line is cut between letters (never inside a UTF-8 letter).
local function Cut(word, max, out)
    while #word > max do
        local at = max
        while at > 1 and word:byte(at + 1) and word:byte(at + 1) >= 0x80 and word:byte(at + 1) < 0xC0 do
            at = at - 1
        end
        out[#out + 1] = word:sub(1, at)
        word = word:sub(at + 1)
    end
    return word
end

-- text in pieces of at most max bytes, cut between words.
local function Split(text, max)
    local protected, saved = Protect(text)
    local out, cur = {}, ""
    for word in protected:gmatch("%S+") do
        word = Restore(word, saved)
        if cur ~= "" and #cur + 1 + #word <= max then
            cur = cur .. " " .. word
        else
            if cur ~= "" then out[#out + 1] = cur end
            -- A link longer than a line can't be cut: it goes alone (the game will refuse it, as chat would).
            cur = word:find("|H") and word or Cut(word, max, out)
        end
    end
    if cur ~= "" then out[#out + 1] = cur end
    return out
end
ns.Split = Split

-- The messages to send for text: each piece in its own (( )) ("((text))" without spaces), none past 255 bytes.
function ns.Lines(text, spaced)
    text = Unbracket(text)
    if text == "" then return {} end
    local open, close = "((", "))"
    if spaced then open, close = "(( ", " ))" end
    local out = {}
    for _, piece in ipairs(Split(text, MAX - #open - #close)) do
        out[#out + 1] = open .. piece .. close
    end
    return out
end

-- The channel an answer to an OOC line goes to. kind: the CHAT_MSG_ event's tail ("SAY", "PARTY_LEADER" ...);
-- answer: EzOOCDB.answer ("same" or "whisper"). nil: no answer there.
function ns.ReplyChannel(kind, answer)
    local chatType = ns.REPLY[kind]
    if not chatType then return end
    if answer == "whisper" then return "WHISPER" end
    return chatType
end

-- A chat author as whispers take them: Forever gives "First-Surname" and whispers want "First Surname"; Era's
-- "Name-Realm" whispers fine as it is.
function ns.WhisperName(author, era)
    if era then return author end
    return (author:gsub("%-", " "))
end

-- "Bob" from "Bob-Smith", "Bob Smith" or "Bob".
function ns.FirstName(name)
    return name:match("^[^%s%-]+") or name
end

-- The [Reply] link after someone's OOC line: it carries the line's kind and author, so a click needs nothing kept.
function ns.ReplyLink(kind, author)
    return ns.LINK_COLOR .. "|Haddon:EzOOC:" .. kind .. ":" .. author .. "|h" .. ns.LINK_TEXT .. "|h|r"
end

-- kind, author from a clicked link ("addon:EzOOC:SAY:Bob-Smith"), or nil when it isn't one of ours.
function ns.ParseLink(link)
    if type(link) ~= "string" then return end
    local kind, author = link:match("^addon:EzOOC:([%u_]+):(.+)$")
    if kind and ns.REPLY[kind] then return kind, author end
end
