-- Hearing OOC lines: whoever says something in (( )) (or OOC:) is kept as someone to answer (ns.Heard), and their line
-- gets a [Reply] link (EzOOCDB.link). A click on it opens the box on their channel. Never sends anything.
local _, ns = ...

local issecret = ns.issecret

local function Usable(msg, author)
    return type(msg) == "string" and type(author) == "string" and not issecret(msg) and not issecret(author)
        and author ~= "" and ns.IsOOC(msg) and not ns.IsMe(author)
end

local listen = CreateFrame("Frame")
for kind in pairs(ns.REPLY) do listen:RegisterEvent("CHAT_MSG_" .. kind) end
listen:SetScript("OnEvent", function(_, event, msg, author)
    if Usable(msg, author) then ns.Heard(event:sub(10), author) end
end)

-- The link carries the kind and author, so the filter (run once per chat frame showing the line) keeps nothing.
local function Filter(_, event, msg, author, ...)
    if not (EzOOCDB and EzOOCDB.link) or not Usable(msg, author) then return false end
    return false, msg .. " " .. ns.ReplyLink(event:sub(10), author), author, ...
end

local AddFilter = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
for kind in pairs(ns.REPLY) do AddFilter("CHAT_MSG_" .. kind, Filter) end

-- A click on [Reply]: Blizzard's own handler for |Haddon:...|h links passes them on through EventRegistry
-- "SetItemRef" (Forever and Era alike), so nothing in chat is hooked.
if EventRegistry and EventRegistry.RegisterCallback then
    EventRegistry:RegisterCallback("SetItemRef", function(_, link)
        local kind, author = ns.ParseLink(link)
        if not kind then return end
        ns.Heard(kind, author)  -- an older line's author becomes the newest to answer
        ns.OpenReply(ns.speakers[1])
    end, ns)
end
