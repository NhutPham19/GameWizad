class_name ElementTypes
extends RefCounted

# ==============================================================================
# ELEMENT TYPES & METADATA - GAMEWIZAD
# ==============================================================================

const FIRE = "fire"
const WIND = "wind"
const LIGHTNING = "lightning"
const EARTH = "earth"
const WATER = "water"

const ALL_ELEMENTS = [FIRE, WIND, LIGHTNING, EARTH, WATER]

const COLORS := {
	FIRE: Color(1.0, 0.32, 0.05),
	WIND: Color(0.25, 0.95, 0.7),
	LIGHTNING: Color(0.85, 0.35, 1.0),
	EARTH: Color(0.85, 0.65, 0.25),
	WATER: Color(0.2, 0.65, 1.0)
}

const VI_NAMES := {
	FIRE: "Hỏa (Fire)",
	WIND: "Phong (Wind)",
	LIGHTNING: "Lôi (Lightning)",
	EARTH: "Thổ (Earth)",
	WATER: "Thủy (Water)"
}
