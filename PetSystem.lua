-- Roblox Pet System
-- Place this Script in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local PetStore = DataStoreService:GetDataStore("PlayerPets_V1")

local PETS = {
	Dog = {Chance = 50, Multiplier = 1.2, Color = Color3.fromRGB(150, 100, 60)},
	Cat = {Chance = 35, Multiplier = 1.5, Color = Color3.fromRGB(180, 180, 180)},
	Dragon = {Chance = 15, Multiplier = 2, Color = Color3.fromRGB(80, 200, 100)}
}

local HATCH_COST = 100
local HATCH_COOLDOWN = 2

-- Create remotes
local function getRemote(name, class)
	local remote = ReplicatedStorage:FindFirstChild(name)

	if not remote then
		remote = Instance.new(class)
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end

	return remote
end

local HatchPet = getRemote("HatchPet", "RemoteEvent")
local EquipPet = getRemote("EquipPet", "RemoteEvent")
local PetUpdate = getRemote("PetUpdate", "RemoteEvent")
local GetPetData = getRemote("GetPetData", "RemoteFunction")

local playerPets = {}
local hatchCooldowns = {}
local followers = {}

-- Choose a random pet
local function choosePet()
	local roll = math.random(1, 100)
	local total = 0

	for petName, data in pairs(PETS) do
		total += data.Chance

		if roll <= total then
			return petName
		end
	end

	return "Dog"
end

-- Create a simple pet model
local function createPet(petName, player)
	local data = PETS[petName]
	if not data then return end

	local model = Instance.new("Model")
	model.Name = petName

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2, 2, 2)
	body.Color = data.Color
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	model.PrimaryPart = body
	model.Parent = workspace

	followers[player] = model
	return model
end

-- Update player's pet multiplier
local function updateMultiplier(player)
	local petData = playerPets[player]
	if not petData or not petData.Equipped then
		player:SetAttribute("PetMultiplier", 1)
		return
	end

	local data = PETS[petData.Equipped]
	player:SetAttribute("PetMultiplier", data and data.Multiplier or 1)
end

-- Save pet data
local function savePets(player)
	local data = playerPets[player]
	if not data then return end

	local success, err = pcall(function()
		PetStore:SetAsync("Player_" .. player.UserId, data)
	end)

	if not success then
		warn("Could not save pets for " .. player.Name .. ": " .. tostring(err))
	end
end

-- Load pet data
local function loadPets(player)
	local success, data = pcall(function()
		return PetStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and type(data) == "table" then
		playerPets[player] = data
	else
		playerPets[player] = {
			Inventory = {},
			Equipped = nil
		}
	end

	updateMultiplier(player)
	PetUpdate:FireClient(player, playerPets[player])
end

-- Hatch a pet
local function hatchPet(player)
	local now = os.clock()

	if hatchCooldowns[player] and now - hatchCooldowns[player] < HATCH_COOLDOWN then
		return
	end

	hatchCooldowns[player] = now

	local coins = player:FindFirstChild("leaderstats")
		and player.leaderstats:FindFirstChild("Coins")

	if not coins or coins.Value < HATCH_COST then
		return
	end

	coins.Value -= HATCH_COST

	local petName = choosePet()
	local data = playerPets[player]

	if not data then return end

	table.insert(data.Inventory, petName)

	if not data.Equipped then
		data.Equipped = petName
	end

	updateMultiplier(player)
	PetUpdate:FireClient(player, data)

	savePets(player)

	print(player.Name .. " hatched a " .. petName)
end

-- Equip a pet
EquipPet.OnServerEvent:Connect(function(player, petName)
	local data = playerPets[player]
	if not data or type(petName) ~= "string" then return end

	if not PETS[petName] then return end

	local ownsPet = false

	for _, ownedPet in ipairs(data.Inventory) do
		if ownedPet == petName then
			ownsPet = true
			break
		end
	end

	if not ownsPet then return end

	data.Equipped = petName

	if followers[player] then
		followers[player]:Destroy()
	end

	createPet(petName, player)
	updateMultiplier(player)
	PetUpdate:FireClient(player, data)
	savePets(player)
end)

HatchPet.OnServerEvent:Connect(hatchPet)

GetPetData.OnServerInvoke = function(player)
	return playerPets[player]
end

-- Create physical egg and prompt
local egg = workspace:FindFirstChild("PetEgg")

if egg and egg:IsA("BasePart") then
	local prompt = egg:FindFirstChildOfClass("ProximityPrompt")

	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Hatch Pet"
		prompt.ObjectText = "Pet Egg"
		prompt.Parent = egg
	end

	prompt.Triggered:Connect(hatchPet)
end

-- Make pets follow players
RunService.Heartbeat:Connect(function()
	for player, pet in pairs(followers) do
		local character = player.Character

		if character and character:FindFirstChild("HumanoidRootPart")
			and pet and pet.Parent and pet.PrimaryPart then

			local root = character.HumanoidRootPart
			local target = root.CFrame * CFrame.new(3, 0, 4)
			pet:PivotTo(pet:GetPivot():Lerp(target, 0.1))
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	loadPets(player)

	local data = playerPets[player]
	if data and data.Equipped then
		createPet(data.Equipped, player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	savePets(player)

	if followers[player] then
		followers[player]:Destroy()
	end

	playerPets[player] = nil
	followers[player] = nil
	hatchCooldowns[player] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePets(player)
	end
end)
