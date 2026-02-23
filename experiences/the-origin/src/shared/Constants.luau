--!strict

local Constants = {
	GAME_VERSION = "0.1.0",
	GAME_NAME = "The Origin",

	-- Player
	MAX_PLAYERS = 4,
	MAX_HEALTH = 4,
	INVENTORY_SLOTS = 4,
	SPRINT_DURATION = 6, -- seconds
	STAMINA_RECOVERY_STANDING = 1.5, -- multiplier
	STAMINA_RECOVERY_CROUCHING = 0.8, -- multiplier
	FLASHLIGHT_BATTERY_LIFE = 180, -- seconds

	-- Movement speeds (studs/s)
	SPEED_CROUCH = 4,
	SPEED_WALK = 12,
	SPEED_SPRINT = 24,
	SPEED_LIMP_MODIFIER = 0.85, -- at 2 health pips

	-- Sound radii (studs) -- how far the entity can hear
	SOUND_SPRINT = 40,
	SOUND_WALK = 12,
	SOUND_CROUCH = 3, -- effectively ignored
	SOUND_DOOR = 25,
	SOUND_OBJECT_KNOCK = 35,
	SOUND_FLASHLIGHT_CLICK = 15,
	SOUND_PLAYER_DAMAGE = 50,
	SOUND_FLARE_THROW = 45,
	SOUND_GENERATOR_PULL = 60,

	-- Entity
	ENTITY_ACTIVATION_DELAY_SOLO = 90,
	ENTITY_ACTIVATION_DELAY_DUO = 60,
	ENTITY_ACTIVATION_DELAY_SQUAD = 45,
	ENTITY_VISION_CONE = 60, -- degrees
	ENTITY_VISION_LIT = 30, -- studs
	ENTITY_VISION_DARK = 8, -- studs
	ENTITY_FLASHLIGHT_DETECT = 50, -- studs
	ENTITY_DETECTION_RAMP = 1.0, -- seconds (awareness buildup)
	ENTITY_CHASE_TIMEOUT = 8, -- seconds to lose sight before dropping to search
	ENTITY_SEARCH_DURATION = 25, -- seconds

	-- Proximity Fear thresholds (studs)
	FEAR_SAFE = 80,
	FEAR_UNEASE = 50,
	FEAR_DREAD = 25,
	FEAR_PANIC = 10,
	FEAR_PROXIMITY = 0,
	FEAR_COOLDOWN = 6, -- seconds to fade effects after escaping

	-- Items
	FLARE_DISTRACT_DURATION = 8, -- seconds
	BANDAGE_HEAL = 1, -- health pips
	MEDKIT_HEAL = 4, -- full heal
	BLEED_TRAIL_DURATION = 60, -- seconds before trail fades

	-- Objectives (Level 1)
	GENERATOR_FILL_TIME = 5, -- seconds
	GENERATOR_PULL_COUNT = 4, -- minimum pulls
	GENERATOR_BOOT_TIME = 30, -- seconds to power up
	EXTRACTION_BEACON_SOLO = 60, -- seconds
	EXTRACTION_BEACON_DUO = 75,
	EXTRACTION_BEACON_SQUAD = 90,

	-- Lives System
	MAX_HEARTS = 3,
	DEATH_ANIMATION_DURATION_1 = 5, -- seconds, first death
	DEATH_ANIMATION_DURATION_2 = 6, -- seconds, second death
	DEATH_ANIMATION_DURATION_3 = 10, -- seconds, third/final death
	RESPAWN_GRACE_PERIOD = 5, -- seconds of proximity fear immunity after respawn
	POST_DEATH2_DESATURATION = 0.05, -- baseline desaturation after 2nd death
	HEART_FRAGMENT_COUNT = 14, -- fragments per heart shatter (12-16 range)

	-- Checkpoint positions (Level 1 — St. Maren's Hospital)
	CHECKPOINTS_LEVEL_1 = {
		{ name = "Ambulance Bay", position = Vector3.new(0, 5, 0) },
		{ name = "Ground Floor Corridor", position = Vector3.new(60, 5, 30) },
		{ name = "Upper Floor Hallway", position = Vector3.new(60, 20, 60) },
		{ name = "Basement Corridor", position = Vector3.new(30, -10, 45) },
	},

	-- Multiplayer
	DOWNED_REVIVE_WINDOW = 30, -- seconds
	DOWNED_REVIVE_HEALTH = 1, -- pips after revive

	-- Jumpscare System
	SCARE_GLOBAL_COOLDOWN = 90, -- seconds between any scare
	SCARE_MAX_PER_10MIN = 2,
	SCARE_CATEGORY_C_RESPAWN_IMMUNITY = 30, -- seconds after respawn
	SCARE_CATEGORY_D_FINAL_LIFE_MULTIPLIER = 2,
	SCARE_ENTITY_NEARBY_RANGE = 40, -- studs; Category B triggers within this range

	-- Entity Damage
	ENTITY_DAMAGE_AMOUNT = 2, -- health pips per hit
	ENTITY_DAMAGE_COOLDOWN = 1.5, -- seconds between hits on same player
	ENTITY_CATCH_STUN_DURATION = 0.5, -- seconds player is stunned
	ENTITY_HIDING_SPOT_REVEAL_TIME = 2, -- seconds before entity drags player out
	ENTITY_DAMAGE_RANGE = 3, -- studs
	ENTITY_DOOR_DETECT_RANGE = 5, -- studs

	-- Doors
	DOOR_OPEN_DURATION = 0.3, -- seconds for door open tween
	DOOR_ENTITY_BREAK_DURATION = 0.15, -- faster for entity
	DOOR_ENTITY_PATROL_OPEN_DURATION = 1.0, -- slower when not chasing
	DOOR_OPEN_ANGLE = 90, -- degrees

	-- Spectator / CCTV
	CCTV_STATIC_INTENSITY = 0.15,
	CCTV_DESATURATION = -0.5,
	NOTIFICATION_DISPLAY_TIME = 3, -- seconds
	NOTIFICATION_FADE_IN = 0.3,
	NOTIFICATION_FADE_OUT = 0.5,
	MAX_VISIBLE_NOTIFICATIONS = 3,

	-- Revive
	REVIVE_HOLD_DURATION = 5, -- seconds to hold prompt
	REVIVE_PROMPT_DISTANCE = 8, -- studs

	-- Levels
	LEVELS = {
		"st-marens-hospital",
		"line-13-subway",
		"blackpoint-station",
		"ashwood-forest",
		"the-origin",
	},
}

return Constants
