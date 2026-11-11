--!strict
-- What an image of cells looks like, of the plugin's config: the frame's
-- parts, its title, the room and what fills it, a selection's least size,
-- and the rows without the empty ones at their end.

local look = {}

-- The plugin's config, a table of its keys.
export type Config = { [string]: any }

-- The color of `text`, as `#rrggbb`, its red, green and blue; none of any
-- other text.
function look.color(text: any): { number }?
    if type(text) ~= "string" or #text ~= 7 or string.sub(text, 1, 1) ~= "#" then
        return nil
    end
    local red = tonumber(string.sub(text, 2, 3), 16)
    local green = tonumber(string.sub(text, 4, 5), 16)
    local blue = tonumber(string.sub(text, 6, 7), 16)
    if red == nil or green == nil or blue == nil then
        return nil
    end
    return { red, green, blue }
end

-- Whether a row's cells show something past their text, as a background.
local function shows(row: CellRow): boolean
    local runs: { StyleRun } = row.runs or {}
    for _, run in runs do
        local style = run.style
        if style.background ~= nil or style.inverse or style.underline ~= nil then
            return true
        end
    end
    return false
end

-- `rows` without the empty rows at their end, one at least, as a screen
-- of a few lines of output shows below them.
function look.trimmed(rows: { CellRow }): { CellRow }
    local kept = table.clone(rows)
    while #kept > 1 and kept[#kept].text == "" and not shows(kept[#kept]) do
        table.remove(kept)
    end
    return kept
end

-- The window's title, where `config` shows one: the config's
-- `title-text`, if it gives one, or else the pane's, `title`; none of an
-- empty one.
function look.title(config: Config, title: string?): string?
    if config.title == false then
        return nil
    end
    local given = config["title-text"]
    if type(given) == "string" and given ~= "" then
        return given
    end
    if title == nil or title == "" then
        return nil
    end
    return title
end

-- The image of `rows` that `config` asks for, titled `title` where it
-- shows one; of a selection's, `selection`, of its least columns and rows.
function look.spec(config: Config, rows: { CellRow }, title: string?, selection: boolean): ImageSpec
    local alone = config.target == "window"
    local background: ImageBackground = "theme"
    if config["transparent-background"] == true or alone then
        background = "clear"
    else
        local rgb = look.color(config.background)
        if rgb ~= nil then
            background = { rgb = rgb }
        end
    end
    local padding: number = if alone then 0 else (config.padding or 32)
    return {
        rows = rows,
        title = look.title(config, title),
        buttons = config["window-controls"] ~= false,
        rounded = config["rounded-corners"] ~= false,
        shadow = config.shadow ~= false and not alone,
        padding = padding,
        background = background,
        scale = config.scale,
        min_columns = if selection then config["min-columns"] else nil,
        min_rows = if selection then config["min-rows"] else nil,
    }
end

return look
