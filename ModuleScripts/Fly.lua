--[[
    // Name: Improved Fly Module
    // Description: Allows a player to fly.
    // Author: <@208876506146013185>
    // Version: 1.0.0

    Call with:
        local FlyModule = require(path.to.this.modulescript)
        FlyModule:Start()
        FlyModule:Stop()
]]

local Configuration = {
	FlySpeed = 50
}

local FlyScript = {}
local Objects = {
	Instances = {},
	Connections = {}
}

local Internal_Values = {
	Forwards = Vector3.new(0, 0, -1),
	Backwards = Vector3.new(0, 0, 1),
	Left = Vector3.new(-1, 0, 0),
	Right = Vector3.new(1, 0, 0),
	Up = Vector3.new(0, 1, 0),
	Down = Vector3.new(0, -1, 0)
}

local actions = {
	{ Name = "Fly Forward", Key = Enum.KeyCode.W, Direction = Internal_Values.Forwards, GuiPosition = UDim2.new(0.5, -50, 0, 0) },
	{ Name = "Fly Backward", Key = Enum.KeyCode.S, Direction = Internal_Values.Backwards, GuiPosition = UDim2.new(0.5, -50, 0, 50) },
	{ Name = "Fly Left", Key = Enum.KeyCode.A, Direction = Internal_Values.Left, GuiPosition = UDim2.new(0.5, -100, 0, 25) },
	{ Name = "Fly Right", Key = Enum.KeyCode.D, Direction = Internal_Values.Right, GuiPosition = UDim2.new(0.5, 0, 0, 25) },
	{ Name = "Fly Up", Key = Enum.KeyCode.Space, Direction = Internal_Values.Up, GuiPosition = UDim2.new(0.5, -50, 0, 25) },
	{ Name = "Fly Down", Key = Enum.KeyCode.LeftShift, Direction = Internal_Values.Down, GuiPosition = UDim2.new(0.5, -50, 0, 25) }
}

local Services = {
	Players = game:GetService("Players"),
	ContextActionService = game:GetService("ContextActionService"),
	UserInputService = game:GetService("UserInputService")
}

local Camera = workspace.CurrentCamera
local Character = Services.Players.LocalPlayer.Character or Services.Players.LocalPlayer.CharacterAdded:Wait()

local function getRoot(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	return rootPart
end

local function getMovers(character)
	local rootPart = getRoot(character)
	if not rootPart then
		return
	end

	local attachment = rootPart:FindFirstChild("Attachment")
	local linearVelocity = rootPart:FindFirstChild("LinearVelocity")
	local alignOrientation = rootPart:FindFirstChild("AlignOrientation")

	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Parent = rootPart
		table.insert(Objects.Instances, attachment)
	end

	if not linearVelocity then
		linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
		linearVelocity.Attachment0 = rootPart:FindFirstChild("Attachment")
		linearVelocity.MaxForce = math.huge
		linearVelocity.Parent = rootPart
		table.insert(Objects.Instances, linearVelocity)
	end

	if not alignOrientation then
		alignOrientation = Instance.new("AlignOrientation")
		alignOrientation.MaxTorque = math.huge
		alignOrientation.MaxAngularVelocity = math.huge
		alignOrientation.Responsiveness = 200
		alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		alignOrientation.Attachment0 = rootPart:FindFirstChild("Attachment")
		alignOrientation.Parent = rootPart
		table.insert(Objects.Instances, alignOrientation)
	end

	return attachment, linearVelocity, alignOrientation
end

local function setupConnections(character)
	local rootPart = getRoot(character)
	if not rootPart then
		return
	end

	local _, _, alignOrientation = getMovers(character)

	local function onRenderStepped()
		if not Camera then
			return
		end

		alignOrientation.CFrame = CFrame.new(rootPart.Position, rootPart.Position + Camera.CFrame.LookVector)
	end

	table.insert(Objects.Connections, game:GetService("RunService").RenderStepped:Connect(onRenderStepped))
end

local function setupControls()
	local _, LinearVelocity, _ = getMovers(Character)
	local Humanoid = Character:FindFirstChild("Humanoid")

	local activeDirections = {}

	local function CalculateVelocity()
		local velocity = Vector3.new(0, 0, 0)

		for _, direction in pairs(activeDirections) do
			velocity = velocity + direction
		end

		LinearVelocity.VectorVelocity = velocity * Configuration.FlySpeed
	end

	local isMobile = Services.UserInputService.TouchEnabled

	if isMobile then
		local function GetMoveVector()
			return require(Services.Players.LocalPlayer:WaitForChild("PlayerScripts").PlayerModule:WaitForChild("ControlModule")):GetMoveVector()
		end

		Services.ContextActionService:BindAction(
			"Fly Down",
			function(_, state)
				activeDirections["Fly Down"] = state == Enum.UserInputState.Begin and Internal_Values.Down or nil
				CalculateVelocity()
			end,
			true,
			Enum.KeyCode.ButtonR2
		)
		Services.ContextActionService:SetTitle("Fly Down", "Fly Down")
		Services.ContextActionService:SetPosition("Fly Down", UDim2.new(0.5, -50, 0, 25))

		Humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
			if Humanoid.Jump then
				activeDirections["Fly Up"] = Internal_Values.Up
			else
				activeDirections["Fly Up"] = nil
			end
			CalculateVelocity()
		end)

		local TouchMoved = Services.UserInputService.TouchMoved:Connect(function()
			local JoystickDirection = GetMoveVector()
			if JoystickDirection == Vector3.new(0, 0, 0) then
				return
			end

			LinearVelocity.VectorVelocity = JoystickDirection * Configuration.FlySpeed
		end)

		local TouchEnded = Services.UserInputService.TouchEnded:Connect(function()
			LinearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
		end)

		table.insert(Objects.Connections, TouchMoved)
		table.insert(Objects.Connections, TouchEnded)
	else
		for _, action in ipairs(actions) do
			local actionName = action.Name
			local key = action.Key
			local direction = action.Direction

			Services.ContextActionService:BindAction(
				actionName,
				function(_, state)
					activeDirections[actionName] = state == Enum.UserInputState.Begin and direction or nil
					CalculateVelocity()
				end,
				true,
				key
			)
		end
	end
end

function FlyScript:Start()
	getMovers(Character)

	Character:FindFirstChild("Humanoid").PlatformStand = true

	setupConnections(Character)
	setupControls()
end

function FlyScript:Stop()
	for _, connection in pairs(Objects.Connections) do
		connection:Disconnect()
	end

	for _, instance in pairs(Objects.Instances) do
		instance:Destroy()
	end

	Character:FindFirstChild("Humanoid").PlatformStand = false

	for _, action in ipairs(actions) do
		Services.ContextActionService:UnbindAction(action.Name)
	end
end

return FlyScript
