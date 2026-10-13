class_name GameFonts
extends RefCounted
## The game's type, bundled so it looks the same on every computer: Playfair Display (an elegant
## high-contrast serif) for titles, Barlow Condensed for menus and small caps, Barlow for reading.
## All SIL Open Font License, in assets/ui/fonts.

const FROST := Color(0.88, 0.93, 1.0)
const FROST_DIM := Color(0.62, 0.68, 0.78)

const _SERIF := preload("res://assets/ui/fonts/PlayfairDisplay.ttf")
const _SERIF_ITALIC := preload("res://assets/ui/fonts/PlayfairDisplay-Italic.ttf")
const _CONDENSED := preload("res://assets/ui/fonts/BarlowCondensed-Medium.ttf")
const _SANS := preload("res://assets/ui/fonts/Barlow-Medium.ttf")


## Big headings.
static func title(spacing := 6) -> Font:
	return _spaced(_SERIF, spacing)


## Italic serif for quieter lines ("dedicated to").
static func title_italic() -> Font:
	return _spaced(_SERIF_ITALIC, 1)


## Buttons and small spaced capitals.
static func label(spacing := 5) -> Font:
	return _spaced(_CONDENSED, spacing)


## Readable text, like captions.
static func body() -> Font:
	return _SANS


static func _spaced(font: Font, spacing: int) -> Font:
	var spaced := FontVariation.new()
	spaced.base_font = font
	spaced.spacing_glyph = spacing
	return spaced
