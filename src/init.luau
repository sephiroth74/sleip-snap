--!strict
-- Snap: an image of a terminal's text, as a code snippet's image, of the
-- selection or of the screen, in a frame as a macOS window's, which a
-- panel previews, the frame's parts of toggles, before its shutter copies
-- the image or saves it through the save panel.

local look = require("./look")

local Plugin: Plugin = {}

-- The preview's panel.
local PANEL = "snap"

-- The largest preview, in points.
local PREVIEW_WIDTH = 640
local PREVIEW_HEIGHT = 400

-- What the preview shows: the cells, the pane's title, the frame's parts,
-- and the image that the host keeps of them.
type Shot = {
    rows: { CellRow },
    title: string?,
    parts: look.Parts,
    image: Image?,
}

local shot: Shot? = nil

-- The plugin's config, its schema's defaults given.
local function config(cx: Cx): look.Config
    local read = cx.config()
    if type(read) == "table" then
        return read :: any
    end
    return {}
end

-- Renders the shot's image anew, of the config and its parts, letting the
-- one before go.
local function refresh(cx: Cx)
    local current = shot
    if current == nil then
        return
    end
    local before = current.image
    if before ~= nil and before.id ~= nil then
        cx.drop_image(before.id)
    end
    local spec = look.spec(config(cx), current.parts, current.rows, current.title)
    current.image = assert(cx.render_image(spec))
end

-- The text of the plugin's message `id`, of its catalogs.
local function text(cx: Cx, id: string): string
    return cx.message(id) or id
end

-- What the shutter does: copies the image, saves it, or both; the panel
-- closes first, so that the save panel shows on the window.
local function shutter(cx: Cx)
    local current = shot
    if current == nil or current.image == nil then
        return
    end
    local png = (current.image :: Image).png
    local action = config(cx).action or "copy"
    if action == "copy" or action == "both" then
        assert(cx.set_clipboard_image(png))
    end
    cx.close_panel(PANEL)
    if action == "save" or action == "both" then
        assert(cx.save_file(nil, text(cx, "snap-file-name"), png))
    end
end

function Plugin.activate(cx: Cx)
    assert(cx.register_command({ name = "snap.selection", title = "Snap the Selection", category = "edit" }))
    assert(cx.register_command({ name = "snap.screen", title = "Snap the Screen", category = "edit" }))
end

function Plugin.applies(cx: Cx, name: string, args: Args): boolean
    if name ~= "snap.selection" then
        return true
    end
    local pane = cx.focused_pane()
    return pane ~= nil and cx.selection_text(pane) ~= nil
end

function Plugin.on_command(cx: Cx, name: string, args: Args)
    local pane = cx.focused_pane()
    local window = cx.focused_window()
    if pane == nil or window == nil then
        return
    end
    local rows: { CellRow }
    if name == "snap.selection" then
        local selected = cx.selection_cells(pane)
        if selected == nil or #selected == 0 then
            return
        end
        rows = selected
    else
        local screen = assert(cx.screen_cells(pane))
        rows = look.trimmed(screen)
    end
    local before = shot
    if before ~= nil and before.image ~= nil and before.image.id ~= nil then
        cx.drop_image(before.image.id)
    end
    shot = {
        rows = rows,
        title = cx.pane_title(pane),
        parts = look.parts(config(cx)),
        image = nil,
    }
    refresh(cx)
    assert(cx.open_panel(PANEL, {
        anchor = { window_corner = { window = window, corner = "top" } },
        role = "dialog",
        close_outside = true,
        close_escape = true,
    }))
end

function Plugin.on_event(cx: Cx, events: { Event })
    for _, event in events do
        if event.kind == "panel-closed" and event.id == PANEL then
            local current = shot
            if current ~= nil and current.image ~= nil and current.image.id ~= nil then
                cx.drop_image(current.image.id)
            end
            shot = nil
        end
    end
end

function Plugin.on_ui_event(cx: Cx, event: UiEvent)
    local current = shot
    if current == nil then
        return
    end
    if event.kind == "toggle" then
        local parts = current.parts :: any
        if parts[event.key] ~= nil then
            parts[event.key] = event.on
            refresh(cx)
            cx.request_render({ panel = PANEL })
        end
    elseif event.kind == "click" and event.key == "shutter" then
        shutter(cx)
    elseif event.kind == "click" and event.key == "cancel" then
        cx.close_panel(PANEL)
    end
end

-- A toggle of a part of the frame.
local function part(cx: Cx, key: string, on: boolean): Node
    return { kind = "toggle", key = key, text = text(cx, "snap-" .. key), on = on }
end

function Plugin.render(cx: Cx, view: ViewId): Node?
    local current = shot
    if (view :: any).panel ~= PANEL or current == nil or current.image == nil then
        return nil
    end
    local image = current.image :: Image
    local width, height = look.fit(image, PREVIEW_WIDTH, PREVIEW_HEIGHT)
    local action = config(cx).action or "copy"
    local parts = current.parts
    local preview: Node = {
        kind = "image",
        key = "preview",
        image = image.id,
        label = text(cx, "snap-preview"),
        layout = { width = { points = width }, height = { points = height } },
    }
    local toggles: { Node } = {
        part(cx, "buttons", parts.buttons),
        part(cx, "title", parts.title),
        part(cx, "shadow", parts.shadow),
        part(cx, "rounded", parts.rounded),
        part(cx, "transparent", parts.transparent),
    }
    local toolbar: Node = {
        kind = "container",
        key = "parts",
        role = "toolbar",
        label = text(cx, "snap-parts"),
        layout = { direction = "row", gap = 6 },
        children = toggles,
    }
    local spacer: Node = { kind = "spacer" }
    local cancel: Node = { kind = "button", key = "cancel", text = text(cx, "snap-cancel") }
    local press: Node = {
        kind = "button",
        key = "shutter",
        text = text(cx, "snap-shutter-" .. action),
        focusable = true,
    }
    local actions: Node = {
        kind = "container",
        key = "actions",
        layout = { direction = "row", gap = 8 },
        children = { spacer, cancel, press },
    }
    return {
        kind = "container",
        key = "snap",
        layout = {
            direction = "column",
            gap = 12,
            padding = { top = 16, right = 16, bottom = 16, left = 16 },
        },
        style = {
            background = "panel.bg",
            border = { width = 1, color = "panel.border" },
            radius = 12,
            shadow = { color = "shadow", y = 8, blur = 24 },
        },
        children = { preview, toolbar, actions },
    }
end

return Plugin
