--!strict

local ZoneThemes = {}

export type ZoneTheme = {
	Name: string,
	SkyColor: Color3,
	AmbientColor: Color3,
	FogColor: Color3,
	FogDensity: number,
	GroundMaterial: Enum.Material,
	GroundColor: Color3,
	Brightness: number,
	ClockTime: number,
	WallMaterial: Enum.Material,
	WallColor: Color3,
	AccentColor: Color3,
}

ZoneThemes.Themes = {
	-- Zone 1: The Sketch Fields - bright, cheerful, hand-drawn
	[1] = {
		Name = "The Sketch Fields",
		SkyColor = Color3.fromRGB(180, 220, 255),
		AmbientColor = Color3.fromRGB(180, 180, 170),
		FogColor = Color3.fromRGB(200, 220, 240),
		FogDensity = 0.05,
		GroundMaterial = Enum.Material.Grass,
		GroundColor = Color3.fromRGB(120, 200, 80),
		Brightness = 2.5,
		ClockTime = 14,
		WallMaterial = Enum.Material.SmoothPlastic,
		WallColor = Color3.fromRGB(245, 240, 230),
		AccentColor = Color3.fromRGB(255, 200, 50),
	},
	-- Zone 2: The Paper Forest - crumpled paper trees, warm tones
	[2] = {
		Name = "The Paper Forest",
		SkyColor = Color3.fromRGB(170, 200, 160),
		AmbientColor = Color3.fromRGB(140, 150, 120),
		FogColor = Color3.fromRGB(180, 190, 160),
		FogDensity = 0.15,
		GroundMaterial = Enum.Material.Sand,
		GroundColor = Color3.fromRGB(200, 180, 140),
		Brightness = 1.8,
		ClockTime = 11,
		WallMaterial = Enum.Material.Cardboard,
		WallColor = Color3.fromRGB(210, 190, 150),
		AccentColor = Color3.fromRGB(100, 160, 60),
	},
	-- Zone 3: The Crayon Caverns - dark with neon crayon crystals
	[3] = {
		Name = "The Crayon Caverns",
		SkyColor = Color3.fromRGB(20, 15, 30),
		AmbientColor = Color3.fromRGB(30, 20, 50),
		FogColor = Color3.fromRGB(15, 10, 25),
		FogDensity = 0.4,
		GroundMaterial = Enum.Material.Slate,
		GroundColor = Color3.fromRGB(40, 35, 50),
		Brightness = 0.3,
		ClockTime = 0,
		WallMaterial = Enum.Material.Slate,
		WallColor = Color3.fromRGB(50, 40, 60),
		AccentColor = Color3.fromRGB(200, 50, 255),
	},
	-- Zone 4: The Watercolor Wetlands - soft, blurry, painted
	[4] = {
		Name = "The Watercolor Wetlands",
		SkyColor = Color3.fromRGB(150, 180, 200),
		AmbientColor = Color3.fromRGB(130, 150, 170),
		FogColor = Color3.fromRGB(160, 180, 200),
		FogDensity = 0.25,
		GroundMaterial = Enum.Material.Mud,
		GroundColor = Color3.fromRGB(100, 120, 90),
		Brightness = 1.5,
		ClockTime = 16,
		WallMaterial = Enum.Material.SmoothPlastic,
		WallColor = Color3.fromRGB(140, 160, 180),
		AccentColor = Color3.fromRGB(80, 150, 200),
	},
	-- Zone 5: The Ink Ruins - ancient, dark stone stained with ink
	[5] = {
		Name = "The Ink Ruins",
		SkyColor = Color3.fromRGB(80, 70, 90),
		AmbientColor = Color3.fromRGB(60, 55, 70),
		FogColor = Color3.fromRGB(70, 60, 80),
		FogDensity = 0.2,
		GroundMaterial = Enum.Material.Cobblestone,
		GroundColor = Color3.fromRGB(70, 65, 75),
		Brightness = 1.0,
		ClockTime = 19,
		WallMaterial = Enum.Material.Brick,
		WallColor = Color3.fromRGB(80, 70, 85),
		AccentColor = Color3.fromRGB(30, 20, 60),
	},
	-- Zone 6: The Neon Grid - Tron-like digital space
	[6] = {
		Name = "The Neon Grid",
		SkyColor = Color3.fromRGB(5, 5, 15),
		AmbientColor = Color3.fromRGB(10, 10, 30),
		FogColor = Color3.fromRGB(5, 5, 20),
		FogDensity = 0.1,
		GroundMaterial = Enum.Material.SmoothPlastic,
		GroundColor = Color3.fromRGB(10, 10, 20),
		Brightness = 0.5,
		ClockTime = 0,
		WallMaterial = Enum.Material.Neon,
		WallColor = Color3.fromRGB(0, 200, 255),
		AccentColor = Color3.fromRGB(255, 0, 200),
	},
	-- Zone 7: The Storm Peaks - harsh outdoor mountain
	[7] = {
		Name = "The Storm Peaks",
		SkyColor = Color3.fromRGB(60, 65, 80),
		AmbientColor = Color3.fromRGB(80, 80, 90),
		FogColor = Color3.fromRGB(100, 100, 110),
		FogDensity = 0.35,
		GroundMaterial = Enum.Material.Rock,
		GroundColor = Color3.fromRGB(90, 85, 80),
		Brightness = 0.8,
		ClockTime = 18,
		WallMaterial = Enum.Material.Rock,
		WallColor = Color3.fromRGB(100, 95, 90),
		AccentColor = Color3.fromRGB(200, 200, 220),
	},
	-- Zone 8: The Living Canvas - surreal, breathing walls
	[8] = {
		Name = "The Living Canvas",
		SkyColor = Color3.fromRGB(120, 50, 80),
		AmbientColor = Color3.fromRGB(100, 60, 80),
		FogColor = Color3.fromRGB(110, 50, 70),
		FogDensity = 0.2,
		GroundMaterial = Enum.Material.Fabric,
		GroundColor = Color3.fromRGB(180, 140, 160),
		Brightness = 1.2,
		ClockTime = 12,
		WallMaterial = Enum.Material.Fabric,
		WallColor = Color3.fromRGB(160, 120, 140),
		AccentColor = Color3.fromRGB(255, 80, 120),
	},
	-- Zone 9: The Void - empty space, floating fragments
	[9] = {
		Name = "The Void",
		SkyColor = Color3.fromRGB(2, 2, 5),
		AmbientColor = Color3.fromRGB(5, 5, 10),
		FogColor = Color3.fromRGB(2, 2, 5),
		FogDensity = 0.0,
		GroundMaterial = Enum.Material.ForceField,
		GroundColor = Color3.fromRGB(20, 20, 40),
		Brightness = 0.2,
		ClockTime = 0,
		WallMaterial = Enum.Material.ForceField,
		WallColor = Color3.fromRGB(30, 30, 60),
		AccentColor = Color3.fromRGB(100, 80, 255),
	},
	-- Zone 10: The Cliff - epic finale, stormy heights
	[10] = {
		Name = "The Cliff",
		SkyColor = Color3.fromRGB(40, 30, 50),
		AmbientColor = Color3.fromRGB(50, 40, 60),
		FogColor = Color3.fromRGB(60, 50, 70),
		FogDensity = 0.3,
		GroundMaterial = Enum.Material.Rock,
		GroundColor = Color3.fromRGB(60, 55, 65),
		Brightness = 0.6,
		ClockTime = 21,
		WallMaterial = Enum.Material.Rock,
		WallColor = Color3.fromRGB(70, 60, 75),
		AccentColor = Color3.fromRGB(255, 100, 50),
	},
}

function ZoneThemes.GetTheme(zone: number): ZoneTheme
	return ZoneThemes.Themes[zone] or ZoneThemes.Themes[1]
end

return ZoneThemes
