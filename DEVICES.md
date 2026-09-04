# Adding New Systems and System Images

> **Note:** this guide covers the standalone Collection Screen
> (`/components/collectionList/CollectionItem.qml`), which is used when the
> "Display Mode" setting is List (the default), Grid or Gallery. When Display
> Mode is set to Sidebar, collections are instead browsed from a sidebar built
> into the Game List, which uses the smaller icon set in
> `/assets/images/icons/<shortname>.png` rather than the device art below.

---

## The bundled artwork sets

There are four sets, all keyed off a collection's shortname:

|folder|used by|
|------|-------|
|`/assets/images/devices/`|the device art on the Collection Screen, and the preview shown beside the sidebar|
|`/assets/images/devicesCompact/`|the same, when the `Compact Device Art` setting is on|
|`/assets/images/icons/`|the per-console icons in the Sidebar display mode|
|`/assets/images/collections/`|the platform logos used by the `Replace Collection Names with Logos` setting|

`devices`, `devicesCompact` and `icons` hold the same 38 filenames, so a
shortname that resolves to a name in one resolves in all three. `collections`
holds 42 logos and covers a slightly different set - `CollectionData.qml`'s
`logoImages` array is the list of which ones exist, and a platform that isn't
in it falls back to its text name instead of showing a broken image.

---

## Create Your Own

- add image files into `/assets/images/devices/shortname.png`
    - add a matching file to `devicesCompact/` and `icons/` too - all three
      sets fall back to their own `default.png` when a file is missing, so a
      gap shows the generic console rather than an empty space
    - images should not have any padding, but can be worked around if it does
    - images may include dropshadow, or the shadow can be generated in the theme
    - images are *not required* for a collection to work
- add new metadata into `/components/resources/CollectionData.qml`
    - this metadata is *not required* for a collection to work
    - the `aliases` map
        - this defines alternate shortnames for systems
        - useful if a collection can be known by multiple shortnames, like dc/dreamcast
    - the `metadata` map
        - `color`: background color for the collection page
        - `vendor`: name of the manufacturer
        - `year`: years of production
        - `image`: alternate image from a different collection
            - useful if multiple collections share an image, like arcade/atomiswave
        - `collectionImage`: alternate logo filename under `collections/`, for
          when a platform shares its device art with another but needs its own
          logo (e.g. `megacd` uses the `segacd` device art but its own logo)
        - any of these bits of metadata *may be excluded*, and the collection
          will still work
    - if you added a logo under `collections/`, add its filename to the
      `logoImages` array in the same file, or the theme will keep showing the
      text name instead
- adjust `/components/collectionList/CollectionItem.qml` if necessary
    - the **device art** is the `device` element near the bottom of the file
        - adjust its `width` and `height` if your images have padding or
          baked-in dropshadows
        - set its `smooth` property to false for pixel-art sets, so Pegasus
          doesn't smooth out the pixelly goodness
    - the **collection logo** is the separate `collectionLogo` element above it,
      which has its own `width`, `height` and `smooth` and only shows when the
      `Replace Collection Names with Logos` setting is on
    - if your image doesn't include a dropshadow, the theme can generate one -
      that's the `Artwork Drop Shadow` setting, which drives `collectionLogo`'s
      `layer.enabled`
