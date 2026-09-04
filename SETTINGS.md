# Settings

The Settings screen is a single scrolling list. Up/Down move between rows, skipping the section headings; Accept toggles a setting or cycles a multi-choice one, and Left/Right step a multi-choice one to the previous/next option directly; Back always leaves the screen onto the Collection Screen, whichever screen you opened Settings from (in Sidebar mode, onto the Game List's console sidebar, since that mode has no separate Collection Screen). Platform reordering is the last section of the list rather than a separate tab.

# Appearance

## Display Mode
Choice between List, Sidebar, Grid and Gallery layouts (press/tap the row to cycle). This is the first item in the Settings menu, and defaults to List. List is the original Collection Screen carousel with a single-column game list. Sidebar replaces the Collection Screen with a console sidebar built into the Game List (All Games, Last Played, Favorites, then every console - similar to Flat Ozone's main screen), using this theme's own icon set. Grid keeps the same Collection Screen carousel, but shows each collection's Game List as a multi-column grid of box art instead of the single-column list with a large art preview (a layout adapted from Beacon Lite's grid view). In Grid mode, Left/Right move within the current row and Up/Down move a full row at a time, while L1/R1 skip to the previous/next letter, same as List. Gallery also keeps the same Collection Screen carousel, but shows the Game List as a horizontal coverflow strip of box art with the current game enlarged in the center (a layout adapted from Beacon Lite's Gallery view). In Gallery mode, Left/Right move to the previous/next game, Up/Down page between collections, and L1/R1 skip to the previous/next letter, same as List and Grid. Gallery also respects "Replace Game Names with Logos": when enabled and the current game has a logo, it's shown below the carousel instead of the title text.

---

## Cards Size
Cycles between Small, Medium, and Large (press/tap the row to advance to the next option). Only affects Grid and Gallery mode: in Grid, it changes how many columns fit on screen (Small fits more, smaller cards per row; Large fits fewer, larger ones), and in Gallery it changes how much of the screen the featured card takes up. In both modes, each card's shape still follows its own box art's aspect ratio - this setting only scales the cards up or down, it doesn't change their proportions.

---

## Font Size
Cycles between Large, Medium, and Small font sizes for most elements (press/tap the row to advance to the next option). Medium and Small are helpful if you're playing on a TV or other large screen.

---

## Theme
Choice between Light and Dark (press/tap the row to cycle).

---

## Compact Device Art
Uses the smaller `devicesCompact` device art images instead of the full-size `devices` set on the Collection Screen and Game List highlight. Off by default; turning it on can look crisper on small screens (e.g. handhelds around 4.5in), since the art isn't being scaled down as far from its source resolution.

---

## Replace Collection Names with Logos
When turned on, a collection's name is replaced with its platform logo from the
bundled `assets/images/collections/` set - both on the Collection Screen and in
the header. Off by default. Platforms without a bundled logo keep their text
name, so turning this on never leaves a blank where a name used to be.

---

## Replace Game Names with Logos
When turned on, each game's name is replaced with its wheel/logo artwork (the `logo` asset). Any game without a logo image still shows its text name as normal. Off by default. In List/Sidebar it replaces the row's text; in Grid it replaces the title shown on the highlighted card; in Gallery it's shown below the carousel instead of the title text.

---

## Artwork Drop Shadow
The soft shadow behind the box art, the preview video, and any game or collection logos. It can cause visual or performance issues on some devices; this is where you can turn it off.

---

## Rounded Card Corners
Only applies to the Grid and Gallery display modes, and is grayed out in the others. On by default. Rounding a card's corners means masking its artwork, which costs an offscreen texture and an extra drawing pass per card - so a screenful of cards is a screenful of both. Turning this off draws the art with square corners instead, which is the cheaper way to render those two layouts on a slower device.

---

# Sound

## Background Music
Toggle music playing in the background. See [CUSTOMIZATION.md](CUSTOMIZATION.md) for instructions on how to set up your own background music files.

---

## Navigation Sounds
Plays or silences sound effects when you press buttons.

---

# Controls

## Controller Layout
Choice between Switch and Xbox (press/tap the row to cycle). This only changes the letters printed in the footer's button legend - the action each entry triggers is the same either way, since X and Y sit in opposite positions on the two pad styles.

---

# Date & Time

## Use 24-Hour Format
Toggle between 24-hour (e.g. 15:45) and 12-hour (e.g. 3:45 PM) clock format. Defaults to off (12-hour); turn it on for 24-hour. You can also tap the clock in the header to flip between the two.

---

# Media & Artwork

## Cycle Art Types
Which art types the `Cycle Art` button steps through. Defaults to `Common` -
box front, poster and screenshot - because stepping through eighteen types to
reach one you actually scraped gets tedious. `Box Art` covers box front, back,
spine and full; `Screens` covers screenshot, title screen and background.
`All Art` is every type the theme knows about - box front, poster, screenshot,
box back, logo, title screen, marquee, steam, banner, tile, cartridge, box
spine, box full, bezel, panel, both cabinet sides and background - which is
how the button behaved before this setting existed. Whichever you pick, the type the game would normally show is
always in the cycle too, so there's always a way back to box art, and types
the current game doesn't have are skipped as before. Only applies to the List
and Sidebar display modes - Grid and Gallery pick art per card and have no
Cycle Art button - so the row is grayed out in the other two.

---

## Prefer Box to Poster
Which artwork a game starts on. When on (the default), the `boxFront` asset is
preferred and `poster` is the fallback; turn it off to flip that around. Either
way, a game with neither falls back to the first art type it does have, and the
`Cycle Art` button still steps through the types chosen in `Cycle Art Types`
above without changing this setting. A cycled type is kept when you launch a game and
quit back out of it, but is dropped when you exit the launcher, so the next
cold start opens on box art again.

---

## Cards Screenshot Preview
In Grid and Gallery mode, stop moving for half a second and a preview of the
current game's screenshot slides in from the right edge over the
bottom-right corner of the screen, sized to match that screenshot's own
aspect ratio rather than a fixed box - a 4:3 or portrait screenshot doesn't
get letterboxed. Moving to a different game dismisses it and restarts the
wait. On by default. Only
appears for games with a screenshot actually scraped, and only the game
you're currently on ever has its screenshot decoded, so scrolling past
everything else costs nothing extra. Does nothing in List or Sidebar mode,
which already show a large art panel, so the row is grayed out there.

---

## Video On Game List
Replaces the title image on the Game List with a video after a short delay.

---

## Video On Game Details
Same as above but for the Game Details screen.

---

## Silent Videos
Mute video sounds while they are playing.

---

## Shorter Video Delay
Switch between half second and two second delay for videos to play.

---

## Game Title On Attract Mode
This can enable or disable the title showing at the top of the screen during attract mode.

---

## Delayed Images
Adds a small delay when loading screenshot images on the game list. This can improve performance, especially for very large collections.

---

# Collections

## Favorites On Top
Favorites are listed first on the game list, ahead of everything else.

---

## Show All Games/Last Played/Favorites
Optionally show/hide these meta-collections.

---

## Start on All Games
When Pegasus starts, open the Collection Screen with **All Games** selected, instead of returning to the collection and game you were on when it last closed. On by default. It stops on the Collection Screen - it doesn't open the game list.

In Sidebar mode there's no standalone Collection Screen, so the equivalent applies: the Game List opens with the console sidebar focused and All Games selected.

This applies only to a genuine start of Pegasus. Launching a game and quitting back out still returns you to exactly where you left off - same collection, same game, same screen - because the theme can tell the two apart: Pegasus shuts the theme down while a game runs and builds it again afterwards, and a flag written just before the launch marks that round trip.

Greyed out when `Show All Games Collection` is off, since there's then no All Games entry to start on.

---

# Reorder

A single **Platforms** row at the end of the list. Selecting it slides a panel in from the right holding your platform collections (Nintendo Entertainment System, Super Nintendo, etc - not the All Games/Last Played/Favorites collections), so you can put them in whatever order you'd like them to appear in on the Collection Screen and in Sidebar mode.

Inside the panel:

- **Accept** grabs the highlighted platform; **Up/Down** move it; **Accept** again (now labelled "Drop") releases it and saves. Tapping a row does the same: first tap highlights, second grabs or drops.
- The ▲/▼ arrows on each row move it one place and save immediately, without needing to grab first.
- **Back** drops a grabbed platform if there is one, otherwise closes the panel. Tapping outside the panel closes it too.

The saved order takes effect right away, without needing a restart.
