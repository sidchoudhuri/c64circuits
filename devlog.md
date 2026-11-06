# C64 Circuits — Devlog

A circuit-building puzzle for the Commodore 64, written in BASIC V2. This is the story of how it went from a one-board proof of concept to a disk with a loader, music and a self-playing demo.

| Version | What it was |
|---|---|
| v01 | C64Pipes proof of concept: one board, cell-by-cell check |
| v02 | Renamed C64 Circuits. Connectivity check, W/A/S/D, X and `.`, mute, reveal |
| v03 | Chained boards, 32 levels, two-digit clues, final screen |
| v04 | The disk: loader and menu, SID music, SID detection and volume, demo |

---

## v01: C64Pipes, a proof of concept

The first program was called C64Pipes. A hidden path runs from an edge pad to another edge pad. The game shows how many path pieces are in each row and column, and you build the path with PETSCII straight and corner pieces. It had a blocked-cell marker, boards that grew with each level, and the board was always centred on the screen.

It was then renamed **C64 Circuits**: pieces became wires and the endpoints became pads. Same build, new name.

## v02: A game that lets you be right

The first version generated a hidden path and checked your board against it cell by cell. That sounds fair until you hit a board where two different circuits satisfy every clue. You'd build a perfectly valid one, the game would shout **COUNTS MATCH, PATH WRONG**, and you'd have no idea why.

That message is gone. The check now walks your wire from the entry pad, step by step. It wins when the wire reaches the exit pad and every piece you placed is part of that one connected path. Row and column counts still have to match. Any valid solution is accepted.

Other changes in this round:

- **W/A/S/D** work as well as the cursor keys.
- **X** and **.** place and clear cells directly.
- **M** mutes the sound. The SID voices are now switched off after every effect, which kills the faint whine the 6581 chip leaked.
- **R** reveals the hidden circuit if you're stuck.
- The screen text is light green on a green board.

## v03: Boards that connect

Until now, solving a level just threw you at a bigger, separate board. That's gone.

Now every solved board stays on screen, recoloured light blue with grey clues, and the next board of the same size starts where the last one ended. They chain together in a snake: left to right across the first row, down, then right to left. When the screen is full of boards, the size steps up and you start a new chain.

Under the hood, the path generator had to change. It used to restart from scratch whenever it painted itself into a corner. It now backtracks and tries another route, which is faster and lets each board begin exactly where the last one ended.

Clues of 10 or more now use two digits, with the tens digit on the row above (for columns) or the column to the left (for rows). That's what makes the big boards possible.

There are 32 levels: ten 5x5 boards, eight 6x6, eight 7x7, three 9x9, then single boards of 12x20, 15x28 and 17x36, which almost fills the screen. Finish the last one and the grid comes online: `MAIN GRID: ONLINE`, `CORE FREQUENCY: 50HZ STABLE`, `GRID SYNCHRONIZED.`

## v07: Chips and a boot screen

The final stages became a C64 motherboard to debug: the wire has to be routed around real chips.

- **Chips.** Stage 5 (12x20): 4164 RAM and a 6526 CIA at the bottom left. Stage 6 (15x28): KERNAL, BASIC and the PLA. Stage 7 (17x36): the 6510 CPU in the middle, CHARGEN and both CIAs. Positions follow where the parts roughly sit on a breadbin board.
- **How they work.** A chip is a 3-row block of cells the wire cannot use. The generator treats them as walls (and re-applies them every time it restarts), the board draw and the reveal skip them, and the cursor jumps over them. Clues count wire cells only, so the rules and the check are unchanged. A Python copy of the generator found a route every time in 300 runs per stage, in a median of 32 to 64 steps.
- **Sprites.** The chip bodies are hardware sprites (X-expanded, dark pins top and bottom, a notch at the left end) built from three shapes stored in the cassette buffer at $0340. A 12-cell chip is two sprites side by side. Sprites sit behind the characters, so the part numbers are plain text on top. They are switched off for the help screen and when leaving for the menu, and on again after a redraw.
- **Ending.** The old "MAIN GRID: ONLINE" text became a C64 boot screen: blue screen, light-blue border, the BASIC V2 banner, 38911 bytes free, `READY.` and a blinking cursor. Any key returns to the menu.
- **Not yet.** The special tiles for stages 1 to 3 (power in, RF modulator, VIC-II can) and the two-SID stage 4 are planned for v08 and v09, so the level count is still 37.
- **Version.** Disk ID and on-screen text are 07. The game is 9,668 bytes; roughly 4 KB of BASIC memory stays free. Nothing has been run on a real C64 or emulator, including the sprite positions.

## v06: The trailer

The demo became a trailer: the same fifteen fixed boards looping until Q, with one scroller on the top row. It replaces `CIRCUITSDEMO` on the disk, so the menu entry and Q-to-menu behaviour are unchanged.

- **Scroller.** A new 1065-byte machine-code file, `CIRCUITSSCROLL`, loaded next to the music at $9700 (source in `src/circuitsscroll.asm`). A raster interrupt sets the horizontal fine scroll just before row 0 and resets it right after, so the text moves one pixel per frame in 38-column mode. Once per 8 pixels the row shifts one character and a new one comes in. The text colours ripple and cycle slowly. BASIC does not touch row 0.
- **Music.** The scroller's interrupt calls the music's play routine once per frame at a fixed raster line, so the music cannot delay the scroll split. It stops cleanly: Q stops the scroller, then the music.
- **Trailer changes.** No header or status messages (row 0 is the scroller, row 1 is blank), no fake "creating" pause, a little faster solving, and the screen is cleared from row 1 down so the scroller survives each loop. Volume keys still show a short bar on row 1, which clears itself.
- **Loader.** It now loads the scroller file after the music, using the same "already loaded" check.
- **Checks.** The scroller was run in a 6502 simulation: the text stream matched the looped text, the fine-scroll values cycled 0 to 7, nothing was written outside screen row 0, colour RAM row 0 and the VIC registers, and stop restored the interrupt vector. It has not been run on a real C64 or emulator.
- **Menu keys.** The title wire used to freeze the menu for about a second each cycle while it erased and rebuilt itself in one go, so key presses waited. It now erases the old wire two cells at a time and builds the next one a column at a time, checking the keyboard between every step.
- **Version.** Disk ID and on-screen text are 06. File sizes: loader 5,458 bytes, game 7,599, demo 5,326, music 1,729, scroller 1065.

## v05: A compact header and fifteen boards

Feedback on the v04 demo: stage 1 stopped at ten boards instead of a snake of three rows (left to right, right to left, left to right) for fifteen, the three-line header ate the screen, and the level counter read `10` instead of a stage and board.

- **Fifteen 5x5 boards.** Stage 1 now fills rows 3 to 24 with a 3-row snake. The ladder is 37 levels.
- **Level numbering.** `LVL 1-10`, then `LVL 2-1`, with the grid size next to it (`GRID 5X5`, `GRID 12X20`).
- **Two header rows plus a gap.** Row 0 is title, level and grid. Row 1 is a hint on the left and a short status on the right (15 characters at most). Row 2 is blank, boards start on row 3.
- **Contextual hints.** The hint follows the cell under the cursor, then rotates through movement, check and help, and quit and volume keys while idle.
- **Shorter messages.** `NEW BOARD...`, `PAD TO PAD`, `COUNTS OFF: n`, `NOT CONNECTED`, `CIRCUIT DONE!`, `REVEALING...`.
- **Demo.** Same layout, header `V:VOLUME Q:QUIT TO MENU` with `DEMO: CREATING / SOLVING / CHECKING / SOLVED`, and fifteen stored boards.
- **Layout detail.** The first board row drops its unused top pad row so the gap fits; a script checked all seven stages for overlaps and off-screen cells.
- **Version.** Disk ID and on-screen text are 05.

Not run on a real C64 or emulator; hint-printing speed in the idle loop and the memory estimate (roughly 8 KB free) are unchecked. File sizes: loader 5,405 bytes, game 7,599, demo 5,602.

## v04: From one program to a disk

v03 was a single BASIC program. v04 is a disk of four programs that work together, set up the same way as PETSCII Pit and PETSCII Panic.

### The disk

- `C64CIRCUITS`, the loader and menu, comes first, so `LOAD"*",8` finds it.
- Under it, five zero-block directory entries draw a pad, a wire that winds down five rows, and a second pad in PETSCII.
- Then `CIRCUITS` (the game), `CIRCUITSDEMO` and `CIRCUITSMUSIC`.
- The disk name is `C64 CIRCUITS` and the disk ID is the version.

The art uses the real PETSCII line graphics. The first build used the wrong byte for the vertical line (a right bracket instead of the line character) and it showed up as brackets in the directory. That was fixed and the disk rebuilt.

### Delivery

The programs depend on each other, so they only make sense together. From here on everything ships on the `.d64`; loose `.bas` and `.prg` files are for reading only.

### The loader and menu

The loader sets the top of BASIC memory to $9000 to make room for the music, loads the music, detects SIDs, and shows a menu: **P** play, **D** demo, **I** how to play, **C** credits, **S** SID setup, **Q** quit (with a Y/N check).

The title screen draws a wire growing from pad to pad on the same green dotted board the game uses. The route is different each time.

The SID setup screen shows the detected SIDs and the volumes as bars. Settings live in a page of memory at $9F00 that every program on the disk shares, so choices survive going from the menu to the game and back.

### Music: Pad to Pad

The brief: very simple, electronic-sounding C64 SID music for a game about building circuit boards, with the noise channel used for soldering sounds.

The first tune was rejected as too melodic. The rewrite is a small 6502 IRQ player at $9000 with three voices:

- **Voice 1:** short lead blips with a narrow pulse.
- **Voice 3:** a square-wave bass.
- **Voice 2:** the noise channel, playing soldering events: ticks, crackles, and arpeggios that are sometimes long and sometimes short.

It is eight bars in A minor over Am, Am, F, G, Am, Am, F, G. PAL and NTSC get their own frequency tables, and the player compensates so the tempo is the same on both. PAL and NTSC `.sid` files are in `sid/`.

### SID detection and volume

The loader looks for a second SID at $D420. With two SIDs the music plays on the first and the sound effects on the second. **M** and **E** set the music and effects volume in steps, and the music starts at a low setting so effects stay clear. With one SID, **V** sets both, and sound effects borrow voice 2 while they play. SID setup in the menu can force one or two SIDs instead of auto-detecting.

### The game

Mostly the v03 game with the framework around it: it reads the shared settings, starts the music, plays click, tick, buzz and fanfare effects on the effects SID, and Q asks "QUIT TO THE MENU? Y/N" before loading the loader back.

### The demo

The first demo played a single 5x5 board. That wasn't the game, so it was rebuilt: it now plays **stage 1** for real. Ten 5x5 boards fill the screen in the snake layout, a cursor walks each wire and places every piece with the game's sounds, each solved board turns light blue, and the stage starts over at the end.

The boards are pre-generated, the same ten every time, and stored as `DATA` lines in the demo itself. The "CREATING PATH..." message is still shown, with a short pause, but it's for show. An earlier version also scattered X marks over empty cells after each wire, which looked odd and is gone.

### Colour

The instructions screen got colour so keywords pop: the wire is light blue, pads are cyan, numbers, rows, columns and counts are yellow, and every key name is yellow with a green dash and light-green description. The loader's title area now uses the playfield look instead of black.

### Versioning

Versions now count every build, as above. The disk ID, the title screens, the credits and the program headers all say 04.

### Bugs of the week

- **Variables overwriting the program.** The loader is shorter than the game. After loading the game, BASIC kept the loader's end-of-program pointer, so the game's variables and arrays were allocated inside the game's own program text. Line 1440 survived and the header routine at line 1800 was overwritten, which showed up as `?UNDEF'D STATEMENT ERROR IN 1440` right after the music started. The game and demo now reset that pointer from the load address before clearing variables. Panic and Pit's loaders do the same on the way back.
- **`LOAD"*"` loads the last file, not the first.** The demo's Q key reloaded the demo instead of the menu, because the 1541 treats a bare `*` as the last file accessed. The game and demo now load the loader by name with a wildcard that matches the leading space in its file name.
- **Q only worked while the cursor moved.** The demo only looked at the keyboard during cursor moves. It now checks in every pause.
- **Two ACME labels with the same name.** The music player had local labels reused across voices. Each voice routine now has its own scope.
- **A 40-column line wrapped.** A PRINT of exactly 40 columns adds a blank line on the C64 unless it ends with a semicolon. A few lines were reworked.
- **A simulation that disagreed with BASIC.** In BASIC, true is -1, not 1. A Python model of the demo's cursor movement used 1 and stepped the wrong way until it was fixed to use BASIC's semantics.

### Under the hood

- The loader is about 150 lines, the game about 220 and the demo about 160, all BASIC V2, with lines kept to 80 characters or fewer.
- Only the first two characters of a BASIC V2 variable name count, so names were checked for clashes and for keywords hiding inside them.
- File sizes on the disk: loader 5,405 bytes, game 7,389, demo 5,390, music 1,729.
- The programs were checked with a line-order and jump-target audit, a tokenizer round trip, a disk read-back and a 6502 simulation of the music player. They have not been run on a real C64 by the person writing this log; playtesting on hardware is up to Sid.

### Next

- A trailer in the style of the PETSCII Pit and Panic trailers.
- Timing on the 17x36 board is an estimate and needs a real-hardware check.
- Tweaks to the tune.

## v08 - special tiles (stages 1 to 3)
- **Power-in, RF modulator, VIC-II.** Stage 1 tile 5 (top right), stage 2 tile 1 (top left) and stage 3 tile 8 (middle left) are now pre-solved panels: the wire is already laid, the board starts dark (`OFF`), then a fanfare lights it (`ON`, `MOD`, `6567`). They link the neighbouring boards and are not counted as playable levels.
- **Level count is now 34**: 14 + 7 + 7 + 3 + 1 + 1 + 1. Numbering skips the special tile.
- **Demo = level 1.** The trailer uses the same special-tile code, so it plays the power tile exactly as the game does.
- Stage 4 (two SIDs with a 12-column middle board) is still planned for v09.
- Disk ID and loader version bumped to 08. Untested on hardware; logic checked in cbmbasic/Python only.

## v08b - dark special tiles, live chips
- Special tiles (stages 1-3) are drawn at the start of the stage as a dark gray box with black `PWR`/`OFF` (`RF`/`OFF`, `VIC`/`OFF`), no clues. On their turn the fanfare plays and the box lights up with its wire, clues and `ON`/`MOD`/`6567` label.
- Chips (stages 5-7) start dark (dark gray, thin legs, dim label). Solving the board switches the sprites to multicolour: bright legs, light gray body, black label.

### Where things stand at v08b
- 34 levels over seven stages. Stages 1 to 3 each have a pre-solved motherboard tile (power in, RF modulator, VIC-II) that starts dark and lights up when the chain reaches it. Stages 5 to 7 have sprite chips that start dark and come alive when the board is solved.
- The trailer (disk file `CIRCUITSDEMO`) plays stage 1 including the power tile, with a fine-scrolling story along the top row from `CIRCUITSSCROLL` at $9700.
- Not done yet: stage 4 with two SIDs and a 12-column middle board (v09), and the standalone trailer package for itch.io.
- None of this has been run on real hardware or an emulator by me. Checks so far are listing audits and logic checks in Python and cbmbasic.

## v09 - the SID boards (stage 4)
- **Stage 4 is finished.** Three boards in a row: 9x9, a wider 9x12 middle board, and 9x9. A 6581 SID chip sits on each outer board, and the wire you build across all three is the jumper between the two SIDs.
- **Boards of different widths.** Each board in a stage can now have its own width. Positions, clues, the generator, the check and the redraw all follow the current board's width, and the three boards fill the 40 columns exactly (12 + 16 + 12).
- **Chips per board.** Each chip belongs to one board, so stage 4 draws a chip only once its board is reached, and a chip stays lit once its board is solved while the next board is still dark.
- Checked the generator over 500 chained runs in Python (no restarts, paths always connect across the chain) and ran the real BASIC generator in cbmbasic: each board starts where the last one ended and the chips are routed around. Not run on a real C64 or in an emulator by me.
- Disk ID and loader version 09.
