--!strict

local Types = {}

export type DrawingMaterial = "wood" | "stone" | "ice" | "balloon" | "metal" | "rubber" | "glass" | "magnet" | "neon"

export type DrawingPoint = {
	X: number,
	Y: number,
}

export type DrawingStroke = {
	Points: { DrawingPoint },
	Color: Color3,
	Thickness: number,
	Material: DrawingMaterial,
}

export type DrawingData = {
	Strokes: { DrawingStroke },
	Width: number,
	Height: number,
}

export type MaterialProperties = {
	Density: number,
	Friction: number,
	Elasticity: number,
	Buoyancy: number,
	RobloxMaterial: Enum.Material,
	Flammable: boolean,
	Conductive: boolean,
	Transparent: boolean,
	GlowsInDark: boolean,
}

export type DrawingBehavior = "static" | "walks" | "flies" | "rolls" | "bounces" | "follows" | "floats"

export type MaterializedDrawing = {
	Model: Model,
	Material: DrawingMaterial,
	Behavior: DrawingBehavior,
	CreatedAt: number,
	Lifetime: number,
	Owner: Player,
}

export type ZoneTheme = {
	Name: string,
	SkyColor: Color3,
	AmbientColor: Color3,
	FogDensity: number,
	Music: string,
	GroundMaterial: Enum.Material,
	GroundColor: Color3,
	Brightness: number,
}

export type StageObjective = "reach_end" | "defeat_enemy" | "solve_puzzle" | "survive_timer" | "collect_items"

export type StageDefinition = {
	Id: number,
	Name: string,
	Zone: number,
	ZoneName: string,
	Description: string,
	Objective: StageObjective,
	TimeLimit: number?,
	MaxDrawings: number,
	DrawingLifetime: number,
	UnlockedMaterials: { DrawingMaterial },
	Hint: string,
	ParTime: number,
}

export type PlayerProgress = {
	CurrentStage: number,
	HighestStage: number,
	StageStars: { [number]: number },
	UnlockedMaterials: { DrawingMaterial },
	TotalDeaths: number,
	TotalDrawings: number,
	BestTimes: { [number]: number },
}

export type StarRating = {
	Completed: boolean,
	UnderTime: boolean,
	Creative: boolean,
}

export type CheckpointData = {
	Stage: number,
	Position: Vector3,
	Timestamp: number,
}

return Types
