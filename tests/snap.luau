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

function test.the_commands_register_and_the_selection_s_applies_while_one_shows(host: TestHost)
    host.activate()
    local names = host.commands()
    assert(table.find(names, "snap.selection") ~= nil and table.find(names, "snap.screen") ~= nil)
    assert(not host.applies("snap.selection"), "no selection, no snap of it")
    assert(host.applies("snap.screen"))
    host.set_selection({ row("ls") })
    assert(host.applies("snap.selection"))
end

function test.the_screen_s_snap_copies_its_image_of_the_default_action(host: TestHost)
    host.activate()
    host.set_screen({ row("ls -la"), row("total 0"), row("") })
    host.command("snap.screen")
    local png = assert(host.clipboard_image())
    assert(string.sub(png, 2, 4) == "PNG")
    assert(#host.saves() == 0, "a copy saves nothing")
    assert(#host.panels() == 0 and #host.kept_images() == 0, "no preview")
end

function test.the_selection_s_snap_takes_its_cells(host: TestHost)
    host.activate()
    host.command("snap.selection")
    assert(host.clipboard_image() == nil, "nothing of no selection")
    host.set_selection({ row("cargo test") })
    host.command("snap.selection")
    assert(host.clipboard_image() ~= nil)
end

function test.a_snap_saves_through_the_save_panel_as_the_config_asks(host: TestHost)
    host.set_config({ action = "save" })
    host.activate()
    host.set_screen({ row("x") })
    host.command("snap.screen")
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
    assert(host.clipboard_image() ~= nil and #host.saves() == 1)
end

function test.the_image_follows_the_config(host: TestHost)
    local spec = look.spec({ padding = 24, background = "#102030" }, { row("a") }, "~/lokyr — zsh", false)
    assert(spec.title == "~/lokyr — zsh" and spec.padding == 24 and spec.buttons == true)
    assert(spec.rounded == true and spec.shadow == true and spec.keep == nil)
    local background = spec.background :: any
    assert(background.rgb[1] == 16 and background.rgb[2] == 32 and background.rgb[3] == 48)
    -- A transparent background, whatever the color.
    local clear = look.spec({ background = "#102030", ["transparent-background"] = true }, { row("a") }, nil, false)
    assert(clear.background == "clear")
    -- The window alone: no room, nothing around it, no shadow.
    local alone = look.spec({ target = "window", padding = 32 }, { row("a") }, nil, false)
    assert(alone.padding == 0 and alone.background == "clear" and alone.shadow == false)
    -- A color of another text, the theme's; parts turned off.
    local plain = look.spec({
        background = "red",
        shadow = false,
        ["window-controls"] = false,
        ["rounded-corners"] = false,
    }, { row("a") }, nil, false)
    assert(plain.background == "theme" and plain.padding == 32)
    assert(plain.shadow == false and plain.buttons == false and plain.rounded == false)
end

function test.the_title_is_the_config_s_text_or_else_the_pane_s(host: TestHost)
    assert(look.title({}, "~/lokyr — zsh") == "~/lokyr — zsh")
    assert(look.title({ ["title-text"] = "Snap Window" }, "~/lokyr — zsh") == "Snap Window")
    assert(look.title({ ["title-text"] = "Lokyr" }, nil) == "Lokyr")
    assert(look.title({ ["title-text"] = "" }, "zsh") == "zsh", "an empty text, the pane's")
    assert(look.title({}, nil) == nil)
    assert(look.title({ title = false, ["title-text"] = "Lokyr" }, "zsh") == nil)
end

function test.a_selection_takes_the_least_size_and_the_screen_its_own(host: TestHost)
    local config = { ["min-columns"] = 80, ["min-rows"] = 10 }
    local selected = look.spec(config, { row("ls") }, nil, true)
    assert(selected.min_columns == 80 and selected.min_rows == 10)
    local screen = look.spec(config, { row("ls") }, nil, false)
    assert(screen.min_columns == nil and screen.min_rows == nil)
    local own = look.spec({}, { row("ls") }, nil, true)
    assert(own.min_columns == nil and own.min_rows == nil, "the selection's own size")
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

return test
