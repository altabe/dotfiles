require("hs.ipc") -- enables the `hs` CLI (e.g. `hs -c "hs.reload()"`)
hs.autoLaunch(true)
hs.window.animationDuration = 0

-- Alt-Tab window switcher: windows (not apps) on the current space, listed as rows.
-- While Alt is held: Tab / Shift-Tab step, tapping Shift steps back, Esc cancels.
-- Releasing Alt focuses the selected window.
-- Globals so Hammerspoon doesn't garbage-collect them.

local ROW_H, PAD, WIDTH, ICON = 32, 8, 640, 20
local FONT = { name = hs.styledtext.defaultFonts.system.name, size = 13 }
local colors = { -- Catppuccin Mocha
  bg = { hex = "#1e1e2e", alpha = 0.95 },
  sel = { hex = "#45475a" },
  text = { hex = "#cdd6f4" },
  dim = { hex = "#a6adc8" },
}

switcherFilter = hs.window.filter.new():setCurrentSpace(true)
-- An active subscription makes the filter track focus order for sortByFocusedLast
switcherFilter:subscribe(hs.window.filter.windowFocused, function() end)

local windows, index, canvas, shiftDown = nil, 1, nil, false

local function highlightFrame()
  return { x = PAD, y = PAD + (index - 1) * ROW_H, w = WIDTH - 2 * PAD, h = ROW_H }
end

local function label(win)
  local app = win:application()
  local function styled(s, color)
    return hs.styledtext.new(s, { font = FONT, color = color, paragraphStyle = { lineBreak = "truncateTail" } })
  end
  return styled((app and app:name() or "") .. "   ", colors.dim) .. styled(win:title() or "", colors.text)
end

local function render()
  local screen = hs.screen.mainScreen():frame()
  local h = #windows * ROW_H + 2 * PAD
  canvas = hs.canvas.new({ x = screen.x + (screen.w - WIDTH) / 2, y = screen.y + (screen.h - h) / 2, w = WIDTH, h = h })
  canvas:level(hs.canvas.windowLevels.popUpMenu)
  canvas[1] = { type = "rectangle", fillColor = colors.bg, roundedRectRadii = { xRadius = 10, yRadius = 10 } }
  canvas[2] = { type = "rectangle", fillColor = colors.sel, roundedRectRadii = { xRadius = 6, yRadius = 6 }, frame = highlightFrame() }
  for i, win in ipairs(windows) do
    local y = PAD + (i - 1) * ROW_H
    local app = win:application()
    local icon = app and app:bundleID() and hs.image.imageFromAppBundle(app:bundleID())
    if icon then
      canvas:appendElements({ type = "image", image = icon, frame = { x = 2 * PAD, y = y + (ROW_H - ICON) / 2, w = ICON, h = ICON } })
    end
    canvas:appendElements({ type = "text", text = label(win), frame = { x = 3 * PAD + ICON, y = y + 7, w = WIDTH - 5 * PAD - ICON, h = ROW_H - 7 } })
  end
  canvas:show()
end

local function step(delta)
  index = (index - 1 + delta) % #windows + 1
  canvas[2].frame = highlightFrame()
end

local function start(backward)
  windows = switcherFilter:getWindows(hs.window.filter.sortByFocusedLast)
  if #windows == 0 then
    windows = nil
    return
  end
  index = 1
  render()
  switcherEsc:enable()
  step(backward and -1 or 1)
end

local function close(focus)
  switcherEsc:disable()
  if canvas then canvas:delete() end
  if focus then windows[index]:focus() end
  windows, canvas = nil, nil
end
switcherEsc = hs.hotkey.new("alt", "escape", function() close(false) end)

-- Tab and Esc go through hotkeys, not the event tap: while Secure Input is on, macOS hides
-- key-downs from event taps but still delivers hotkeys and modifier changes. loginwindow
-- often leaves it stuck on after unlocking; `secureinput` (zsh) shows who holds it.
local function forward()
  if windows then step(1) else start(false) end
end
local function backward()
  if windows then step(-1) else start(true) end
end
hs.hotkey.bind("alt", "tab", forward, nil, forward)
hs.hotkey.bind("alt-shift", "tab", backward, nil, backward)

-- Modifier changes: releasing Alt commits, tapping Shift steps back
switcherTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(e)
  local flags = e:getFlags()
  local shiftPressed = flags.shift and not shiftDown
  shiftDown = flags.shift or false
  if windows then
    if not flags.alt then
      close(true)
    elseif shiftPressed then
      step(-1)
    end
  end
  return false
end)
switcherTap:start()

-- macOS disables event taps that are slow to respond, or that started before Accessibility was granted
switcherWatchdog = hs.timer.doEvery(5, function()
  if not switcherTap:isEnabled() then switcherTap:start() end
end)
