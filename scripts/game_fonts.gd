class_name GameFonts
extends RefCounted
## The game's type: an elegant high-contrast serif for titles, a clean condensed sans for menus
## and small caps, and a plain sans for reading (captions). Uses fonts installed on the system,
## with fallbacks down to the engine default, so it always renders.

const FROST := Color(0.88, 0.93, 1.0)
const FROST_DIM := Color(0.62, 0.68, 0.78)


## Big headings: Didot (falls back to other classic serifs).
static func title(spacing := 6) -> Font:
	return _font(["Didot", "Bodoni 72", "Big Caslon", "Baskerville", "Georgia", "Times New Roman", "serif"], 400, false, spacing)


## Italic serif for quieter lines ("dedicated to").
static func title_italic() -> Font:
	return _font(["Didot", "Bodoni 72", "Baskerville", "Georgia", "serif"], 400, true, 1)


## Buttons and small spaced capitals.
static func label(spacing := 5) -> Font:
	return _font(["Avenir Next Condensed", "Futura", "Helvetica Neue", "Arial Narrow", "sans-serif"], 500, false, spacing)


## Readable text, like captions.
static func body() -> Font:
	return _font(["Avenir Next", "Avenir", "Helvetica Neue", "Segoe UI", "Arial", "sans-serif"], 500, false, 0)


static func _font(names: Array, weight: int, italic: bool, spacing: int) -> Font:
	var system := SystemFont.new()
	system.font_names = PackedStringArray(names)
	system.font_weight = weight
	system.font_italic = italic
	system.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	if spacing == 0:
		return system
	var spaced := FontVariation.new()
	spaced.base_font = system
	spaced.spacing_glyph = spacing
	return spaced
