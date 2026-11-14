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
        cx.notify(cx.message("snap-copied-to-clipboard") or "Snap copied to clipboard", "success")
    end
    if action == "save" or action == "both" then
        assert(cx.save_file(nil, cx.message("snap-file-name") or "Snap.png", image.png))
    end
end

function Plugin.on_event(cx: Cx, events: { Event })
    for _, event in events do
        if event.kind == "saved" then
            -- The save panel closed: the file written, a failure, or
            -- cancelled, of nothing to tell.
            local failure: string? = event.error
            if event.path ~= nil then
                cx.notify(cx.message("snap-saved-to-file") or "Snap saved to file", "success")
            elseif failure ~= nil then
                local args: { [string]: Data } = { error = failure }
                local text = cx.message("snap-not-saved", args)
                cx.notify(text or `The snap was not saved: {failure}`, "error")
            end
        end
    end
end

return Plugin
