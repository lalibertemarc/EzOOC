-- EzOOC static data.
local _, ns = ...

ns.ERA = select(4, GetBuildInfo()) < 16000

-- A line is out of character when it has one of these (Lua patterns): ((like this)), OOC: or [OOC].
ns.OOC_MARKS = {
    "%(%(",
    "^%s*[Oo][Oo][Cc]%s*[:%-]",
    "%[[Oo][Oo][Cc]%]",
}

-- Chat a [Reply] can answer: the CHAT_MSG_ event's tail -> the channel the answer goes to.
-- Emotes are answered in say (an OOC line belongs in speech, not an action).
ns.REPLY = {
    SAY = "SAY", YELL = "YELL", EMOTE = "SAY",
    PARTY = "PARTY", PARTY_LEADER = "PARTY",
    RAID = "RAID", RAID_LEADER = "RAID", RAID_WARNING = "RAID",
    GUILD = "GUILD", OFFICER = "OFFICER",
    WHISPER = "WHISPER",
}

-- How each one reads in the box and the [Reply] tooltip.
ns.KIND_LABEL = {
    SAY = "say", YELL = "yell", EMOTE = "an emote", PARTY = "party", PARTY_LEADER = "party", RAID = "raid",
    RAID_LEADER = "raid", RAID_WARNING = "a raid warning", GUILD = "guild", OFFICER = "officer", WHISPER = "a whisper",
}

-- /ooc <letter> <text>: the letters that pick a channel. Lowercase only, so a line starting "E" or "I" is said.
ns.SHORT_CHANNELS = { s = "SAY", y = "YELL", p = "PARTY", g = "GUILD", o = "OFFICER", r = "RAID", e = "EMOTE",
                      w = "WHISPER" }

-- In the box, a line can start like a chat command: /p brb
ns.BOX_CHANNELS = {
    s = "SAY", say = "SAY", y = "YELL", yell = "YELL", p = "PARTY", party = "PARTY", g = "GUILD", guild = "GUILD",
    o = "OFFICER", officer = "OFFICER", r = "RAID", raid = "RAID", e = "EMOTE", em = "EMOTE", me = "EMOTE",
    emote = "EMOTE", w = "WHISPER", whisper = "WHISPER", t = "WHISPER", tell = "WHISPER",
}

-- The box's channel list (a click on the channel), in order, with the command that picks it from a line.
-- need: greyed unless you're in a group, a raid or a guild.
ns.BOX_MENU = {
    { chatType = "SAY", label = "Say", cmd = "/s" },
    { chatType = "YELL", label = "Yell", cmd = "/y" },
    { chatType = "EMOTE", label = "Emote", cmd = "/e" },
    { chatType = "PARTY", label = "Party", cmd = "/p", need = "group" },
    { chatType = "RAID", label = "Raid", cmd = "/r", need = "raid" },
    { chatType = "GUILD", label = "Guild", cmd = "/g", need = "guild" },
    { chatType = "OFFICER", label = "Officer", cmd = "/o", need = "guild" },
    { chatType = "WHISPER", label = "Whisper", cmd = "/w name" },
}

-- Where an answer goes (EzOOCDB.answer): the channel they used, or a whisper to them.
ns.ANSWERS = {
    { key = "same", label = "Where they said it", desc = "Say for say, party for party, a whisper for a whisper." },
    { key = "whisper", label = "In a whisper", desc = "Always whisper them back, wherever they said it." },
}

-- How many people you whispered with (either way) are kept for the box's names, per character.
ns.RECENT_MAX = 10
-- How many people who spoke out of character lately the box lists (this session only).
ns.SPEAKERS_MAX = 5
-- Seconds an OOC line waits for your answer: the box opens on its channel within this, unless you spoke since.
ns.REPLY_WINDOW = 120

-- The box takes this many letters (a longer line goes out in pieces, each in its own brackets).
ns.MAX_LETTERS = 500

ns.LINK_COLOR = "|cff8fd3ff"
ns.LINK_TEXT = "[Reply]"

-- The options page's Preview button prints this line as it would go out.
ns.SAMPLE = "brb, getting coffee"
