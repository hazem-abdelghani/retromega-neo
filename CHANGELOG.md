# Changes



## 1.0.1

Fixes and performance work on top of the first Neo release. No behaviour
changes beyond the ones listed here.

### Changed

- `Cycle Art Types` now defaults to `Common` (box front, poster, screenshot)
  instead of `All Art`. Only affects installs with no stored value for it -
  anyone who has already run the theme keeps whatever they have, since the
  setting is written to `api.memory` on every exit

### Fixes

- **Missing device art on the collection screen** - platforms with no bundled
  image (Atari 2600, C64, MSX, DOS, ScummVM, Ports and 20 others) drew a blank
  card instead of falling back to the generic console. The sidebar and the
  game list's device panel already had this fallback; the carousel didn't
- **Play/Favorite buttons overflowed the details screen** - the two buttons
  took a flat half of the row each plus the gap, so Favorite hung off the
  right edge into the screenshot panel
- **Attract mode ignored key auto-repeat** - holding a direction tore down and
  reloaded the video once per repeat. Attract mode also no longer spins
  through the whole library when the scraped video paths are broken (an
  unmounted drive, say); it stops after a run of failures and says so
- **Collection background colour could go stale** - it was assigned
  imperatively on startup, which destroyed its binding, so a change of
  collection that didn't also change the carousel index kept the old colour
- **Settings list could throw during a rebuild** - a row divider read one past
  the end of the model while the Reorder section was appearing or disappearing
- **Collections named after a JavaScript built-in crashed the colour lookup** -
  the platform alias table answered for keys inherited from Object.prototype
- `theme.cfg` listed screenshots under `.meta/` that aren't in the release
  archive, so the theme picker showed an empty preview
- the full description's scroll-down clamp measured the window rather than the
  flickable, and could push a short description off the top
- **Three unguarded `assets` reads.** The game list's and grid's logo checks
  reached into a model role without checking it was there, which a delegate
  being recycled or a model being swapped can briefly make false; and the art
  panel's fallback path indexed into `assets` after only checking the game
  existed. Attract mode also assigned the player a source immediately before
  launching a game, which did nothing and dereferenced `assets` on the way

### Performance

- **Attract mode's game filter no longer runs at startup.** It read
  `assets.video` for every game in the library when the theme loaded and then
  stayed subscribed, whether or not attract mode was ever opened. It's now
  mapped only while that screen is showing
- **The collection carousel no longer builds a filter proxy per card.**
  Unfiltered, each card asked a full proxy model - one of them over All Games -
  for a number the collection already knew. The proxy is now built only while
  a search is actually running
- **Removed the dead sort/filter state.** `onlyFavorites`, `onlyMultiplayer`,
  `sortKey` and `sortDir` were pinned at their defaults on every startup once
  the sorting screen was removed, but were still carried by two disabled
  filters on each of four proxy models, two sorters, four Connections handlers
  and a footer binding
- **The settings list builds one row item instead of three.** Every row
  created a header, a setting and a link item and hid two of them - and each
  hidden setting row still registered a settings callback
- **Grid and Gallery cards no longer morph on reuse.** A recycled card arrived
  at the previous game's dimensions and animated its way to the new aspect
  ratio in full view while scrolling

### Internal

- a settings row now unregisters its callback under the key it registered
  with, rather than whatever the key happens to be at teardown
- absent `screenshot` assets are coalesced to `''` like every other asset read
- the collection list's fallback array is copied before it's mutated

## Neo - Sep 1st
First release of **Retro Mega Neo**, a fork of plaidman's Retro Mega Next. Everything below is new relative to `retromega-next` main (Dec 2023).

### Major changes

- **Display Modes** - new `Display Mode` setting switching the whole layout between four options, live and without a restart
    - **List** - the original layout (collection carousel + single-column game list with a large art preview), and still the default
    - **Sidebar** - the standalone collection screen is replaced by a console sidebar built into the game list; left/right moves focus between the sidebar and the games column
    - **Grid** - keeps the collection carousel, but shows the game list as a multi-column grid of box art
    - **Gallery** - keeps the collection carousel, but shows the game list as a horizontal coverflow strip with the current game enlarged in the middle
    - see [CONTROLS.md](CONTROLS.md) for the per-mode control tables
- **Platform reordering** - a `Reorder` → `Platforms` panel slides in from the right of the settings screen, letting you put your consoles in whatever order you like on the collection screen and in the sidebar
    - grab/drop with Accept, or use the ▲/▼ arrows on each row to move one place and save immediately
    - the order is saved as collection *shortnames* rather than list positions, so adding or removing a platform no longer shifts everything after it; the order takes effect immediately, no restart
- **Settings screen rebuilt** - the Preferences/Platforms tab sidebar is gone. Settings are now one continuous scrolling list broken up by section headings (Appearance, Sound, Controls, Date & Time, Media & Artwork, Collections, Reorder)
    - multi-choice settings (Display Mode, Cards Size, Font Size, Theme, Controller Layout) cycle through named options instead of being on/off toggles
    - settings that don't apply in the current Display Mode are grayed out in place rather than hidden, so the list never reshuffles under the selection
    - leaving settings always lands on the collection screen, so changing Display Mode and backing out can't drop you into a layout you just left
- **Sorting screen removed; R2/ZR is now Search** - R2/ZR opens the name filter box directly, shown as a `Search` button in the footer beside Attract or Details
    - sorting by title/rating/release/favorite and the `Only Favorites` / `Only Multiplayer` toggles are no longer available
    - the sort button has been removed from the header
- **Logo artwork** - two new options to show artwork in place of text
    - `Replace Game Names with Logos` uses each game's scraped `wheel`/`logo` asset in the game list, grid, gallery and details
    - `Replace Collection Names with Logos` uses a new bundled logo set for the collection name in the header and on the collection screen; platforms without a logo fall back to text
- **New and expanded artwork sets**
    - `assets/images/collections/` - 42 platform logos (new)
    - `assets/images/icons/` - 38 sidebar icons (new)
    - `assets/images/devicesCompact/` - 38 smaller device images (new), used by the `Compact Device Art` setting
    - `assets/images/devices/` - redrawn and expanded to 38: adds Famicom, Super Famicom, Mega Drive, TurboGrafx-16, Wii U and Xbox, and renames `psx` to `ps1`
- **Crash and stability fixes around empty collections** - an empty list now reports an index of `-1` instead of `0`, which callers were dereferencing as a real selection; this was the root cause of the "no games" crashes. Null guards were added throughout the game list, details, metadata, description and attract screens, and attract mode no longer dies when nothing in the library has a video
- **Selection stays in sync when filtering** - searching, favoriting and sorting used to leave the index pointing past the end of the shortened list and `currentGame` pointing at a game that had just been filtered out, so the footer count, the art panel and the Play button disagreed with what was on screen. The selection is now re-anchored after every change
- **Performance work**
    - L1/R1 letter-skip caches the sort letters instead of doing one model lookup per game per keypress
    - only the active Display Mode's layout keeps a model, so hidden layouts no longer build delegates and decode box art in the background
    - the Last Played cutoff is computed once (and refreshed hourly) instead of rebuilding a `Date` for every game on every re-filter
    - logos are decoded at display size rather than full size
    - new `Rounded Card Corners` setting - turning it off skips the per-card mask and extra drawing pass in Grid and Gallery
- **Existing settings are migrated, not reset** - `darkMode` → `Theme`, `buttonGuide` → `Controller Layout`, `smallFont` → `Font Size`, `twelveHour` → `Use 24-Hour Format`, and the old index-based platform order → shortnames. Stored values that are no longer valid options fall back to the default instead of rendering as raw text

### Minor changes

- Y button on the game list cycles the preview art through every available asset type (box front, poster, screenshot, logo, cartridge, marquee and more), falling back per-game when a type is missing
- game list art panel no longer stalls scrolling on low-memory devices: the box art is decoded at the size it's drawn rather than the scraper's full resolution, its second copy is loaded off the GUI thread and shares the first one's cache entry instead of decoding the same file again, and its drop shadow is cached rather than re-blurred every frame
- bundled artwork is decoded at display size too - device art (up to 2570x2208), collection logos (up to 1920px wide) and sidebar icons
- new `Cycle Art Types` setting at the top of Media & Artwork, choosing what the Cycle Art button steps through: All Art (the default, every type as before), Common, Box Art or Screens. The game's normal art is always kept in the cycle so box art is always reachable; grayed out in Grid and Gallery, which have no Cycle Art button
- new `Cards Screenshot Preview` setting for Grid and Gallery mode, on by default: after half a second on the same game, a preview of its screenshot slides in from the right edge over the bottom-right of the screen, sized to that screenshot's own aspect ratio rather than a fixed box, dismissed the moment you move to another. Only the highlighted game's screenshot is ever decoded; grayed out in List and Sidebar mode
- Grid and Gallery cards now crossfade from their loading placeholder (the game's first letter) into the box art once it's decoded, instead of one instantly replacing the other
- the cycled art type survives a game launch - quitting a game drops you back on the art you had chosen, not on box front - but is deliberately dropped when the launcher itself closes, so a cold start always opens on box art
- battery widget: charging state pulses green, low battery (≤15%) shows red, the fill animates, and only the outline stays dimmed so the colors aren't washed out
- clock re-aligns itself to the minute boundary rather than free-running on a 30 second timer, so it's no longer up to half a minute stale; tapping it still flips 12/24 hour
- header clock now shows the date underneath as DD/MM/YYYY, with the time shifted up slightly to make room for it
- fixed the Xbox button guide, which had `A`/`B` and `X`/`Y` swapped
- footer button legends are ordered to match the selected controller layout
- right-click acts as B/Cancel on the game list and details screens
- L2/LT now toggles the details screen closed as well as open, and backs out of attract mode
- left/right on the collection screen moves one collection at a time instead of jumping to the first or last
- settings callbacks can be removed, and an exception in one callback no longer stops the rest from running; video players and view callbacks now unregister themselves on destruction
- background music no longer starts a player over an empty playlist
- new default values: background music off, game list video off, game details video off, controller layout Xbox, font size Large
- `Clear Name Filter on Reload` was removed as a setting - the filter is now always cleared on reload
- new `Start on All Games` setting (on by default) - starting Pegasus opens the Collection Screen with All Games selected, instead of the collection and game the last session ended on (in Sidebar mode, the sidebar with All Games selected). Launching a game and quitting back out is unaffected and still restores the exact spot, since the theme now marks the teardown that precedes a launch and can tell it apart from a cold start
- new `Compact Device Art` setting, for crisper device art on small screens
- `Artwork Drop Shadow` (renamed from `Enable Video/Image Shadow`) now also covers game and collection logos
- new accent color in both the light and dark themes
- fixed `clamp()` ignoring its own minimum argument
- collection scroll no longer warns when there is nothing at all to show
- docs rewritten: [CONTROLS.md](CONTROLS.md) covers all four Display Modes, [SETTINGS.md](SETTINGS.md) documents every new option, and [CUSTOMIZATION.md](CUSTOMIZATION.md) / [DEVICES.md](DEVICES.md) no longer point at GitHub line numbers that had drifted
- fixed the `/asssets/` typo in the background music instructions
- game and platform counts read "1 game" rather than "1 games"
- search treats what you type as literal text - it was passed straight to a regular expression filter, so "Sonic (USA)" matched "Sonic USA" but not itself, and a title containing a bare `[` or `(` returned nothing at all
- the search and full-description overlays no longer set a width alongside left/right anchors, which QML warned about on every launch
- a game with an empty scraped genre no longer puts the string "null" through the details screen's metadata list
- the clock's settings callback is unregistered on destruction, like every other component's


---

## Next - Aug 22nd
- L2 on game list to mark favorite (zenijin)
- config options to show/hide all games, last played, and favorites collections (zenijin)
- fix game count on collection list to take filtered games into consideration (zenijin)

## Next - Aug 7th
- improve performance on the collection screen when sorting large collections
    - this is a fairly complex change, please let me know if you see issues moving from the collection screen to the game screen and back.
- allow for alternate button guides
    - see [CUSTOMIZATION.md](CUSTOMIZATION.md) for more details
- support Launchbox shortnames
    - device image packs were updated, see [DEVICES.md](DEVICES.md)
- add system name to attract mode
- change the message when no games are found due to filtering rules
- hide battery on devices without a battery
- properly sort with favorites on top when the app is first loaded
- general system stability improvements to enhance the user's experience

---

## Next - Jun 8th
- adding new collection image files and collection metadata
    - see [DEVICES.md](DEVICES.md) for more details and downloads
- flash current letter when pressing L1/R1 on game list
- setting to delay game list image loading
    - this helps with performance with large collections (300+)
- show file name(s) in game long description
- general system stability improvements to enhance the user's experience

---

## Next - Jun 2nd
- setting to have favorites permanently on top
- new sorting option to sort by favorites if you don't want them permanently on top
- dynamic metadata shown on game list screen
- added a buncha new system (data only, no images)
- fixed a bug where video would continue to play in the background
- general system stability improvements to enhance the user's experience

---

## Next - May 29th
- attract mode
    - shows random videos which you can cycle through
    - start the shown game by pressing A
    - optionally show the game's title during the video
- general system stability improvements to enhance the user's experience

---

## Next - May 24th
- button to quickly scroll to the beginning and end of collection screen
- add name filter indicator in header
- setting to reset name filter when pegasus reopens
- fix for really small buttons on game detail screen
- general system stability improvements to enhance the user's experience

---

## Next - May 23rd
- new settings filters
    - filter games by title
    - filter games by multiplayer
    - recent games filter improvements
- add number of players to game details
- bug fixes
    - recent played games list showing random games
    - videos not resetting properly
- general system stability improvements to enhance the user's experience

---

## Next - Apr 28th
- game sorting screen
    - sort any collection by last played, release date, rating, title
    - toggle between ascending or descending
    - filter games by favorites
    - current sorting is displayed on collection and game list
- new data on game details page
    - added last played time and game rating
    - dynamic spacing if there are many things shown
    - hide 'more' button if there is no description
- bug fixes
    - small bug when picking a random game
    - improved navigation sounds
    - quicker changing settings with one tap
- general system stability improvements to enhance the user's experience

---

## Next - Apr 1st
- system year on collection list
- game details screen
    - show screenshot/video
    - buttons to start game and toggle favorite
    - long description view with touch scrolling
    - fixed a short-description rendering problem
- new settings
    - mute video
    - reduce the video delay
    - toggle video/image dropshadow
- bug fixes
    - loading collection images without metadata
    - made dropshadow optional for better performance and fix some display issues
    - system name in game list was cut off too short
- general system stability improvements to enhance the user's experience

---

## Next - Feb 28th
- new settings
    - small font for better experience on larger screens
    - video playback on game list
- more ways to return from the settings screen
    - X button
    - tap the settings icon
- bug fixes
    - silence navigation sound if the game selection doesn't move when pressing up or down
- general system stability improvements to enhance the user's experience

---

## Next - Feb 23rd
- improved compatibility with different shortnames for collections
    - compatible with pegasus standard
    - compatible with es standard
    - compatible with any other weird aliases I could think of

---

## Next - Feb 20th
- added support for other handhelds (e.g. Odin, RG552)
    - new scaling code to make icons look better in all resolutions
    - fonts, images, and spacing scale to screen resolution
- improve boxart rendering code
    - more natural generated DropShadow layer instad of an image file
    - more straightforward scaling logic
    - images that fail to load will fail more gracefully
    - very tall images will no longer affect other elements on the page
- new systems
    - pico-8
    - lynx
    - ports
    - atomiswave
- settings screen
    - 24/12 hour clock
    - dark mode
    - navigation sounds
    - background music
- added dark mode support to all existing screens
- general system stability improvements to enhance the user's experience

---

## Next - Jan 26th
- rewrote all views and functionality from scratch
    - break up folder structure and code to make it easier to edit
    - greatly simplified the view logic in collection list and especially game list
    - deleted unused assets and inert code
    - organized external resource files (collections and music) for easy editing
    - consolidated input code to clean up any potential double-presses
- new features
    - random game selection
    - touch support
    - background music
    - added ps2, wii collections and artwork
    - touched up wswan, arcade, android, gc, nds, vboy artwork
- bug fixes
    - fixed black screen when cancelling multi-file select or if game launch fails
    - fixed back and forward sound effects not properly playing
    - fixed title screen dropshadow overlapping 'g' and 'y' letters
    - fixed miscolored favorite icon when game is highlighted
    - fixed a layout bug when you un-favorite a game while on the favorites list
    - removed pokemini and wswancolor for now until I can find better art
- general system stability improvements to enhance the user's experience

---

## Next - Jan 15th
- updated arcade controller
- added android controller
- improved the clock widget
    - tap to toggle 24/12 hour
    - updates time correctly

---

## Next - Jan 12th
- added many new controller images
- started bg music support
