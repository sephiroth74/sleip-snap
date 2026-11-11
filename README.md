# snap

A plugin of [Lokyr](https://lokyr.dev): an image of a terminal's text, in a
frame as a macOS window's, of its three buttons and the pane's title, with
rounded corners, a shadow and room around it, to copy or to save, as
code-snippet tools make of code.

## Use

- **Snap the Selection** (`snap.selection`) and **Snap the Screen**
  (`snap.screen`), from the command palette (⇧⌘P) or keys of your own:
  the image of the text, in your theme's colors and your terminal's font,
  is copied, saved through the save panel, or both, as `action` says.
- The window's parts, its background and its size are the config's.

## Install

```sh
sleip add sephiroth74/snap
```

## Config

In Lokyr's `config.toml`, under `[plugins.snap]`:

| Key | Values | Default | What it does |
|---|---|---|---|
| `background` | `#rrggbb` | the theme's background, darker | The color around the window |
| `transparent-background` | `true`, `false` | `false` | No background around the window |
| `shadow` | `true`, `false` | `true` | A shadow under the window |
| `padding` | points, 0 to 256 | `32` | The room around the window |
| `rounded-corners` | `true`, `false` | `true` | The window's corners rounded, or square |
| `window-controls` | `true`, `false` | `true` | The window's three buttons |
| `title` | `true`, `false` | `true` | The pane's title in the window's bar, as its tab shows it |
| `title-text` | a text | none | The title where the pane gives none |
| `target` | `container`, `window` | `container` | The window with what is around it, or the window alone |
| `min-columns` | 1 to 1000 | the selection's | The least columns of a selection's window |
| `min-rows` | 1 to 1000 | the selection's | The least rows of a selection's window |
| `action` | `copy`, `save`, `both` | `copy` | What the shutter does |
| `scale` | `1`, `2`, `3` | the display's | The pixels of a point |

## Capabilities

- `terminal-read`, for the cells of the selection and of the screen.
- `process-read`, for the pane's title as its tab shows it, of its folder
  and its program; refused, the title is the program's own, or
  `title-text`.
- `clipboard-write`, to copy the image.

A save goes through the save panel, where you choose the file: it needs no
capability.

## Develop

`sleip check` checks the plugin, `sleip test` runs its tests, and
`sleip dev` links it into Lokyr, which reloads it at each save.

## License

MIT, see [LICENSE](LICENSE).
