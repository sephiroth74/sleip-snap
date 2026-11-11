--!strict
-- The plugin's tests, which `sleip test` runs on a host of the tests: each
-- function of the table a test, of a host of its own, which fails at its
-- first error, as `assert` raises it.

local look = require("../src/look")

local test = {}

-- A row of `text`, of no style.
local function row(text: string): CellRow
    return { text = text, runs = {} }
end

-- The preview's panel, as its events name it.
local PANEL: ViewId = { panel = "snap" }

function test.the_commands_register_and_the_selection_s_applies_while_one_shows(host: TestHost)
    host.activate()
    local names = host.commands()
    assert(table.find(names, "snap.selection") ~= nil and table.find(names, "snap.screen") ~= nil)
    assert(not host.applies("snap.selection"), "no selection, no snap of it")
    assert(host.applies("snap.screen"))
    host.set_selection({ row("ls") })
    assert(host.applies("snap.selection"))
end

function test.the_screen_s_snap_previews_its_image_and_the_shutter_copies_it(host: TestHost)
    host.activate()
    host.set_screen({ row("ls -la"), row("total 0"), row("") })
    host.command("snap.screen")
    assert(host.panels()[1] == "snap", "the preview shows")
    local kept = host.kept_images()
    assert(#kept == 1, "the image is kept for the preview")
    local panel = assert(host.render(PANEL))
    local children = assert(panel.children)
    assert(children[1].kind == "image" and children[1].image == kept[1])
    -- A part turned off: an image of its own, the one before let go.
    host.ui_event({ view = PANEL, key = "shadow", kind = "toggle", on = false })
    local now = host.kept_images()
    assert(#now == 1 and now[1] ~= kept[1])
    local toggled = assert(assert(host.render(PANEL)).children)
    local parts = assert(toggled[2].children)
    assert(parts[3].key == "shadow" and parts[3].on == false)
    -- The shutter copies, of the default action, and closes the preview,
    -- whose image goes.
    host.ui_event({ view = PANEL, key = "shutter", kind = "click" })
    local png = assert(host.clipboard_image())
    assert(string.sub(png, 2, 4) == "PNG")
    assert(#host.panels() == 0)
    host.advance(0)
    assert(#host.kept_images() == 0)
end

function test.the_selection_s_snap_takes_its_cells(host: TestHost)
    host.activate()
    host.command("snap.selection")
    assert(#host.panels() == 0, "nothing of no selection")
    host.set_selection({ row("cargo test") })
    host.command("snap.selection")
    assert(host.panels()[1] == "snap")
end

function test.the_shutter_saves_through_the_save_panel_as_the_config_asks(host: TestHost)
    host.set_config({ action = "save" })
    host.activate()
    host.set_screen({ row("x") })
    host.command("snap.screen")
    host.ui_event({ view = PANEL, key = "shutter", kind = "click" })
    local saves = host.saves()
    assert(#saves == 1 and saves[1].name == "Snap.png")
    host.answer_save(saves[1].id, "/Users/me/Desktop/Snap.png")
    assert(host.saved_file("/Users/me/Desktop/Snap.png") ~= nil)
    assert(host.clipboard_image() == nil, "a save copies nothing")
end

function test.both_copies_and_saves(host: TestHost)
    host.set_config({ action = "both" })
    host.activate()
    host.set_screen({ row("x") })
    host.command("snap.screen")
    host.ui_event({ view = PANEL, key = "shutter", kind = "click" })
    assert(host.clipboard_image() ~= nil and #host.saves() == 1)
end

function test.cancel_closes_the_preview_and_its_image_goes(host: TestHost)
    host.activate()
    host.set_screen({ row("x") })
    host.command("snap.screen")
    host.ui_event({ view = PANEL, key = "cancel", kind = "click" })
    assert(#host.panels() == 0)
    host.advance(0)
    assert(#host.kept_images() == 0 and host.clipboard_image() == nil)
end

function test.the_image_follows_the_config_and_the_parts(host: TestHost)
    local config = { padding = 24, background = "#102030" }
    local parts = look.parts(config)
    assert(parts.buttons and parts.title and parts.shadow and parts.rounded and not parts.transparent)
    local spec = look.spec(config, parts, { row("a") }, "zsh")
    assert(spec.title == "zsh" and spec.padding == 24 and spec.keep == true and spec.buttons == true)
    local background = spec.background :: any
    assert(background.rgb[1] == 16 and background.rgb[2] == 32 and background.rgb[3] == 48)
    -- A transparent background, whatever the color.
    parts.transparent = true
    assert(look.spec(config, parts, { row("a") }, nil).background == "clear")
    -- The window alone: no room, nothing around it, no shadow.
    local alone = look.spec({ target = "window", padding = 32 }, look.parts({}), { row("a") }, nil)
    assert(alone.padding == 0 and alone.background == "clear" and alone.shadow == false)
    -- A color of another text, the theme's; the title turned off.
    local plain = look.spec({ background = "red", title = false }, look.parts({ title = false }), { row("a") }, "zsh")
    assert(plain.background == "theme" and plain.title == nil and plain.padding == 32)
    assert(look.parts({ ["transparent-background"] = true }).transparent)
end

function test.the_empty_rows_at_the_screen_s_end_are_left_out(host: TestHost)
    assert(#look.trimmed({ row("a"), row(""), row("") }) == 1)
    assert(#look.trimmed({ row("") }) == 1, "one row at least")
    local bar: CellRow = {
        text = "",
        runs = {
            {
                first = 0,
                last = 9,
                style = {
                    background = { palette = 4 },
                    bold = false,
                    faint = false,
                    italic = false,
                    blink = false,
                    inverse = false,
                    invisible = false,
                    strikethrough = false,
                    overline = false,
                },
            },
        },
    }
    assert(#look.trimmed({ row("a"), bar }) == 2, "a row of a background shows")
end

function test.the_preview_fits_its_room_and_grows_no_larger(host: TestHost)
    local wide: Image = { png = "", width = 2000, height = 500, scale = 2 }
    local width, height = look.fit(wide, 640, 400)
    assert(width == 640 and height == 160)
    local small: Image = { png = "", width = 200, height = 100, scale = 2 }
    local small_width, small_height = look.fit(small, 640, 400)
    assert(small_width == 100 and small_height == 50)
end

return test
