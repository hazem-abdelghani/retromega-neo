# Changes


## Neo - Nov 27th
Changes since the Sep 1st release.

### Major changes

- **Swipe Paging** - new `Swipe Paging` setting (on by default) that makes touch and mouse swipes page one step at a time, like paging through photos, instead of coasting past several. Turning it off restores normal flick scrolling. Grid and Gallery are not affected: they keep free scrolling, where a longer swipe scrolls further
    - **Collection Screen** - the carousel follows your finger by at most one collection, and a short swipe moves to the next or previous one
    - **Game List** (List and Sidebar) - a swipe up or down selects the next or previous game
    - **Settings screen** - a swipe up or down selects the next or previous setting (section headings are skipped)
    - swiping past the first or last item now gives a short bounce instead of nothing (Collection Screen, Game List and Settings)
    - the Collection Screen's page dots are now tappable, to jump straight to a collection
    - all of it is handled by one new component, `components/swipe/SwipePager.qml`
- **Touch**
    - **Long-press menu** - pressing and holding a game now opens a menu with Launch, Favorite and Details (a pad can use it too). Before, a long press went straight to Details
    - **Larger Tap Targets** - new `Larger Tap Targets` setting (off by default): the footer buttons and the header clock and settings icon get bigger, with wider hit areas
- **Looks and layout**
    - **Accent Color** - new `Accent Color` setting: Default, Blue, Green, Orange, Red, Purple, Pink or Yellow, applied to every accent in the theme (the light theme uses deeper tones)
    - **Overscan Margin** - new `Overscan Margin` setting: Off, 2%, 4%, 6% or 8% of the screen left empty on every side, for TVs that crop the picture. Everything now sits inside a `safeArea` item in `theme.qml`, and components size themselves from it instead of from the root
    - **PlayStation controller layout** - `Controller Layout` gains PlayStation, which prints the colored Cross, Circle, Square and Triangle (drawn in QML, so they don't depend on a font) and L1/R1/L2/R2. It shares the Xbox layout's button positions
- **More themes** - `Theme` now has ten choices: Light and Dark, plus eight new ones - **Black** (a pure `#000000` background for OLED screens), **Sapphire** (blue), **Ruby** (red), **Emerald** (green), **Amethyst** (purple), **Amber** (yellow), **Aquamarine** (cyan) and **Diamond** (silver). The six colored ones are the Dark theme tinted from a single hue (`components/themes/GemTheme.qml`); Diamond is the Light theme in cool silver. Themes now say whether they are dark (`isDark`) and what text reads on their background (`readableTextColor`), instead of screens guessing. Emerald and Aquamarine use a softer accent than the others (`#47c680` and `#40c9c0`), because fully saturated green and cyan glowed on the dark panels
- **Mouse and keyboard friendliness**
    - the mouse wheel works on the lists that Swipe Paging makes non-interactive (they ignore it on their own): it scrolls the game list and the Settings list and leaves the selection alone, like a wheel anywhere else, and steps one collection per notch on the Collection Screen. Touchpad scrolling is supported too (`components/swipe/WheelScroller.qml`, `WheelStepper.qml`). It scrolls the game list in Sidebar mode even while the console sidebar has focus (it was dead there), and in Gallery - which scrolls sideways and ignores a plain wheel - it moves one game per notch
    - Settings: the wheel scrolling the list never moves the highlight, even though the rows slide under a mouse that is standing still (hover selection waits a moment after the wheel)
    - Settings: the selection follows the mouse without scrolling the list (a row at the edge of the screen is selected where it is, instead of jumping into view; the keys scroll to the selection as before), and a choice row has arrows (‹ ›) either side of its value, to step it back or forward by mouse - right-click is Back everywhere, so a click could only ever go forward
    - the pointer turns into a hand over buttons, rows, cards and the page dots
    - the long-press menu is readable on the Light and Diamond themes (it used the white text meant for selected rows)
- **Startup with a large library** - the game list, Grid, Gallery, console sidebar, Settings list and Platforms panel could build a row for every game while the screen was still being laid out, and the Game List was a negative height at that moment, which left every row with no height too. A list whose rows have no height never runs out of room, so it created a delegate for every game before the layout settled. In a test with stand-in data (the original theme behaves the same way) 1,250 games took 1.7 seconds to load, 2,500 took 10 and 5,000 took 49, and 25,000 did not finish in ten minutes. Rows and cells now have a minimum size of one pixel, so only the rows that fit are built: 25,000 games load in under a second in every display mode. Real Pegasus timings will differ, but the shape of the problem is the same
- **Sharper artwork, one device set** - the `Compact Device Art` setting and the `assets/images/devicesCompact/` set are gone. Instead the single `devices` set is shown sharply at any size
    - every image the theme loads at a size it controls - device art, collection logos, game box art, game and collection logos in every Display Mode, the screenshot preview, the sidebar icons and the background stripe - is decoded at its final on-screen pixel size (scaled by the screen's device pixel ratio), so it is only ever scaled down. The ones the scene scales down further (logos, thumbnails, the preview) also use mipmapping
    - `assets/images/devices/` and `assets/images/collections/` were pre-shrunk once from the originals with Lanczos-3 (premultiplied alpha, colour clamped to alpha so edges don't ring) and then run through `oxipng`. Logos fit within 1440x540
    - device art fits within 1920x1400, about 2x the largest size it is drawn at, so it is only ever scaled down
    - `assets/images/stripe.png` was a 136x480 image drawn about screen-high, so it was always scaled up. It is redrawn at 544x1920 (4x) from its measured shape, scaled down from a larger master with Lanczos-3 and run through `oxipng` (8 KB, down from 21 KB)
    - the unused `devices/mastersystem_old.png` was removed
    - images that are already small enough are untouched. To redo any of this, start from the full-size originals, never from the shrunk files

### Minor changes

- Gallery swipes: a short or slow swipe now carries less far and a long or fast one carries further (measured with simulated swipes: a slow 400px swipe went 2 cards instead of 4, a fast 700px swipe 9 instead of 7, a hard fling 22 instead of 8), so how far you swipe matches how far it scrolls
- memory: the Grid decodes its box art at the card's drawn size (the cell minus its margin) rather than the whole cell
- startup: the collection screen's device art decodes about 1.6x faster (about 27ms per pad instead of 44ms, measured over all 38) because the files are now Lanczos-shrunk to 1920x1400 instead of up to 2570x2208
- version bumped to 1.1.0
- Settings: the value column is wider and shrinks a choice to fit instead of cutting it off, so long choices such as "Aquamarine" and "PlayStation" show in full, also in a narrow window
- tidy-up: removed four unused `QtGraphicalEffects` imports, a commented-out shadow block and some debug scaffolding comments, and made three loose `==` comparisons strict; [CONTROLS.md](CONTROLS.md) now says a long press opens the game menu (it still said it opened the details screen)
- cleanup pass: every bundled device, icon and collection image is reachable from `CollectionData.qml`, every setting is read somewhere and no QML file is unused, so nothing else needed to go
- [SETTINGS.md](SETTINGS.md) now starts with a table of every setting at a glance, in the order they appear on the Settings screen, with its choices, default and what it does (all 30 settings), and how to use the screen with a gamepad, touch or a mouse, followed by the full explanation of each one
- docs updated: [SETTINGS.md](SETTINGS.md) (`Swipe Paging`, `Compact Device Art` removed), [CONTROLS.md](CONTROLS.md) (swipes), [DEVICES.md](DEVICES.md) (three artwork sets) and the README


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
    - more natural generated DropShadow layer instead of an image file
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
