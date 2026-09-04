# Customization and Manual Edits

## Adding New Systems
- see [DEVICES.md](DEVICES.md)

---

## Adding Background Music
- add `.mp3` files into `/assets/music/`
- register each one in the `Playlist` block near the top of
  `/components/resources/Music.qml`, by adding a line alongside the ones
  already there:

    ```qml
    PlaylistItem { source: '../../assets/music/your track.mp3'; }
    ```

- turn on `Background Music` in the settings screen
- the playlist is shuffled and looped; deleting every `PlaylistItem` line just
  leaves it empty, and the setting then has nothing to play

---

## Hiding the All Games, Last Played and Favorites Collections
- no longer a manual edit - each of the three has its own toggle on the settings screen

---

## Customizing Details Screen
- you can remove certain items from the game metadata section
- `/components/gameDetails/GameMetadata.qml` has a `metadataText` property near
  the top holding a `texts` array - remove or reorder any entries in it that you
  don't care to see

---

## Customizing Theme & Button Guides

- the files in `components/themes/` can be updated to change colors of elements
  for themes, or button labels if you use some other format of buttons on your
  controller
- `SwitchButtons.qml` and `XboxButtons.qml` are keyed by *action*, not by
  position - `details` is whichever button fires `api.keys.isDetails()`, and so
  on. That's why `details`/`filters` hold the opposite letters in the two files:
  X and Y sit in opposite positions on the two pad styles. Every footer in the
  theme reads its letters from here, so changing them in one place is enough.
