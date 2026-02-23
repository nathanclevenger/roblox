--!strict

--[[
	Remotes
	Creates and manages all RemoteEvents and RemoteFunctions
	for client-server communication.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)

local Remotes = {}

local remotesFolder: Folder

function Remotes.Init()
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage

	-- Create all RemoteEvents
	for _, remoteName in Constants.REMOTES do
		local remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = remotesFolder
	end
end

function Remotes.Get(name: string): RemoteEvent
	return remotesFolder:WaitForChild(name) :: RemoteEvent
end

function Remotes.FireClient(name: string, player: Player, ...: any)
	local remote = remotesFolder:FindFirstChild(name) :: RemoteEvent?
	if remote then
		remote:FireClient(player, ...)
	end
end

function Remotes.FireAllClients(name: string, ...: any)
	local remote = remotesFolder:FindFirstChild(name) :: RemoteEvent?
	if remote then
		remote:FireAllClients(...)
	end
end

return Remotes
