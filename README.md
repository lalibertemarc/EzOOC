# EzOOC

Say a line out of character, in `(( ))`, and answer someone else's OOC line with one click. A WoW Forever and Classic Era addon for roleplayers.

> /ooc brb, getting coffee
>
> **You say:** (( brb, getting coffee ))

## Commands

| Command | Does |
|---|---|
| `/ooc <text>` | Say `(( <text> ))` (`/ezooc` works too) |
| `/ooc y\|p\|g\|o\|r\|e <text>` | Yell, party, guild, officer, raid or emote it; `/ooc s <text>` says a line that starts with a command word |
| `/ooc w <name> <text>` | Whisper it: `"First Surname"`, `%t`, or just the first name of your target, someone who spoke OOC lately, someone you whispered with or someone in your group (their surname is filled in) |
| `/ooc reply [text]` | Answer the last one who spoke out of character (`/oocr` works too); without text it opens the box on them |
| `/ooc answer same\|whisper` | Answer where they said it (say for say, party for party), or always in a whisper |
| `/ooc link [on\|off]` | A `[Reply]` link after other people's OOC lines (on by default) |
| `/ooc follow [on\|off]` | The box opens on an OOC line still waiting for your answer (on by default) |
| `/ooc spaces [on\|off]` | `(( like this ))` or `((like this))` |
| `/ooc box` | The edit box |
| `/ooc config` | The options page (Options > AddOns > EzOOC) |

**Answering.** Anyone's line with `((` in it, or starting with `OOC:`, or with `[OOC]`, gets a `[Reply]` link in your chat. Click it: the box opens on their channel (say, party, raid, guild, officer, or a whisper to them; emotes are answered in say), and the box's title says whom you're answering. If someone spoke OOC in the last two minutes and you haven't said anything OOC since, the box opens on them by itself. Clicking the channel in the box lists the last five people who spoke OOC to answer them too.

**The box.** Bind a key under Options > Keybindings > EzOOC (or `/ooc box`). Type, press Enter: the line goes out in `(( ))` (brackets you type yourself aren't doubled). The channel shows at the start of the line, as in chat (`Say:`, `Tell Jaina Proudmoore:`), and the box stays on it. To switch, start a line the way chat does: `/y`, `/p`, `/g`, `/o`, `/r`, `/e` or `/w name` and a space. Tab whispers the next person the box knows, Up/Down bring back earlier lines with their channel, Escape closes it. Click anywhere else and it lets go of the keyboard so you can walk, but stays open. Drag it to move it. A line too long for one message goes out in pieces, each in its own brackets.

Only ever sends from your key press or slash command, never by itself.
