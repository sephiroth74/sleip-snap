--!strict
-- Snap: an image of a terminal's text, as a code snippet's image, of the
-- selection or of the screen, in a frame as a macOS window's, as the
-- plugin's config draws it, which its commands copy, save through the save
-- panel, or both.

local look = require("./look")

local Plugin: Plugin = {}

-- The plugin's config.
local function config(cx: Cx): look.Config
    local read = cx.config()
    if type(read) == "table" then
        return read :: any
    end
    return {}
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
    if pane == nil then
        return
    end
    local selection = name == "snap.selection"
    local rows: { CellRow }
    if selection then
        local selected = cx.selection_cells(pane)
        if selected == nil or #selected == 0 then
            return
        end
        rows = selected
    else
        local screen = assert(cx.screen_cells(pane))
        rows = look.trimmed(screen)
    end
    local settings = config(cx)
    local image = assert(cx.render_image(look.spec(settings, rows, cx.pane_title(pane), selection)))
    local action = settings.action or "copy"
    if action == "copy" or action == "both" then
        assert(cx.set_clipboard_image(image.png))
    end
    if action == "save" or action == "both" then
        assert(cx.save_file(nil, cx.message("snap-file-name") or "Snap.png", image.png))
    end
end

return Plugin
