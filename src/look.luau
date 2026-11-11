--!strict
-- What an image of cells looks like, of the plugin's config and of the
-- preview's toggles: the frame's parts, the room and what fills it, the
-- rows without the empty ones at their end, and the preview's size.

local look = {}

-- The parts of the frame that the preview's toggles turn on and off.
export type Parts = {
    buttons: boolean,
    title: boolean,
    shadow: boolean,
    rounded: boolean,
    transparent: boolean,
}

-- The plugin's config, a table of its keys, its schema's defaults given.
export type Config = { [string]: any }

-- The parts as the config gives them.
function look.parts(config: Config): Parts
    return {
        buttons = config["window-controls"] ~= false,
        title = config.title ~= false,
        shadow = config.shadow ~= false,
        rounded = config["rounded-corners"] ~= false,
        transparent = config["transparent-background"] == true,
    }
end

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

-- The image of `rows` that `config` and `parts` ask for, titled `title`
-- where its part shows, which the host keeps for the preview.
function look.spec(config: Config, parts: Parts, rows: { CellRow }, title: string?): ImageSpec
    local alone = config.target == "window"
    local background: ImageBackground = "theme"
    if parts.transparent or alone then
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
        title = if parts.title then title else nil,
        buttons = parts.buttons,
        rounded = parts.rounded,
        shadow = parts.shadow and not alone,
        padding = padding,
        background = background,
        scale = config.scale,
        keep = true,
    }
end

-- The size, in points, that shows `image` whole within `width` and
-- `height`, of its own proportions, never larger than its own.
function look.fit(image: Image, width: number, height: number): (number, number)
    local own_width = image.width / image.scale
    local own_height = image.height / image.scale
    local shrink = math.min(1, width / own_width, height / own_height)
    return math.floor(own_width * shrink), math.floor(own_height * shrink)
end

return look
