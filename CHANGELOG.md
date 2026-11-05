# EzOOC

## Unreleased

- **Out of character, in brackets.** `/ooc <text>` says `(( <text> ))`; `/ooc p`, `y`, `g`, `o`, `r`, `e` and `w <name>` put it in party, yell, guild, officer, raid, an emote or a whisper. Brackets you type yourself aren't doubled, and `/ooc spaces off` writes `((like this))`.
- **A box of your own.** A key binding (Options > Keybindings > EzOOC) or `/ooc box` opens a small chat-style box: Enter says the line in `(( ))`, the channel shows at the start of the line, `/p ` or `/w bob ` switches it (surnames filled in for people it knows), Tab whispers the next person it knows, and Up brings back earlier lines.
- **Answer in one click.** Other people's OOC lines (`((...))`, `OOC:`, `OOC -` or `[OOC]`) get a `[Reply]` link: click it and the box opens on their channel, or a whisper to them. A line from the last two minutes you haven't answered opens the box on them by itself, and `/oocr <text>` answers the last one straight away. `/ooc answer whisper` always answers in a whisper. Nobody else needs the addon.
- **Long lines, piece by piece.** A line too long for one message is cut between words, each piece in its own brackets. In say, yell and emotes the game lets an addon send one message per key press, so the first piece goes out and the box waits with the rest: press Enter for each (or `/ooc more`), Escape drops them. Party, raid, guild, officer and whispers get every piece at once.
