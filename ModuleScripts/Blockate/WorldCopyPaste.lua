if not getgenv().BlockateWorldUtilities_Settings then
	getgenv().BlockateWorldUtilities_Settings = {
    		TIME_BETWEEN_BLOCK_PLACE = 0.05, -- task.wait(getgenv().BlockateWorldUtilities_Settings.TIME_BETWEEN_BLOCK_PLACE)
	}
end

local WorldCopyPaste_Module = {}
-- vars;
local modules = game:GetService("ReplicatedStorage").Modules

-- how does blockate calculate the orientations!??!

local NonVIPColors = {
    "White",
    "Medium stone grey",
    "Black",
    "Bright blue",
    "Bright violet",
    "Pink",
    "Bright red",
    "Brown",
    "Bright orange",
    "Br. yellowish orange",
    "Bright yellow",
    "Br. yellowish green",
    "Bright green",
    "Quill grey",
    "Mid grey",
    "Dark stone grey",
}

local orientations = {
        ["0"] = Vector3.new(0, 0, 0),
        ["1"] = Vector3.new(0, 0, 90),
        ["2"] = Vector3.new(0, 0, 180),
        ["3"] = Vector3.new(0, 0, -90),
        ["4"] = Vector3.new(0, 180, 0),
        ["5"] = Vector3.new(0, 180, 90),
        ["6"] = Vector3.new(0, 180, 180),
        ["7"] = Vector3.new(0, -180, -90),
        ["8"] = Vector3.new(90, 90, 0),
        ["9"] = Vector3.new(90, 0, 0),
        ["10"] = Vector3.new(90, -90, 0),
        ["11"] = Vector3.new(90, 180, 0),
        ["12"] = Vector3.new(-90, -90, 0),
        ["13"] = Vector3.new(-90, 0, 0),
        ["14"] = Vector3.new(-90, 90, 0),
        ["15"] = Vector3.new(-90, -180, 0),
        ["16"] = Vector3.new(0, -90, 0),
        ["17"] = Vector3.new(0, -90, 90),
        ["18"] = Vector3.new(0, -90, 180),
        ["19"] = Vector3.new(0, -90, -90),
        ["20"] = Vector3.new(0, 90, 0),
        ["21"] = Vector3.new(0, 90, 90),
        ["22"] = Vector3.new(0, 90, 180),
        ["23"] = Vector3.new(0, 90, -90),
    }

--[[

    // INTERNAL FUNCTIONS!
    // DO NOT EDIT!

--]]

-- getAxisString<num> -> number [Internal!]
local getAxisString;


function toBlockateCoordinatesFromVector(vector)
    local x = vector.X
    local y = vector.Y
    local z = vector.Z
    local xString = getAxisString(x)
    local yString = getAxisString(y)
    local zString = getAxisString(z)
    return ("%s %s %s/0"):format(xString, yString, zString)
end

-- toBlockateCoordinates<instance: Instance> -> string [Internal!]
-- TODO: Orientation
function toBlockateCoordinates(instance, fixer)
    if instance.Name == "Cube" or instance.Name == "Ball" then return toBlockateCoordinatesFromVector(instance.Functionality.Movable.SpawnPoint.Value) end
    assert(typeof(instance) == "Instance")
    local instance_pos = instance.Position
    local instance_orientation = instance.Orientation
    
-- have to make the code this ugly because it won't work
    for i,v in pairs(orientations) do
        if v == instance_orientation then
            instance_orientation = i
            break
        end
    end
    
    if instance_orientation == instance.Orientation then 
        return
    end

    return ("%s %s %s/%s"):format(getAxisString(math.round(instance_pos.X)), getAxisString(math.round(instance_pos.Y)), getAxisString(math.round(instance_pos.Z)), instance_orientation)
end 

-- toBlockateSize<instance: Instance> -> number [Internal!]
function toBlockateMaterial(instance)
    assert(typeof(instance) == "Instance")
    local BlockMaterials = require(modules.Data.PropertiesIndex.BlockMaterials)
    for i, material in ipairs(BlockMaterials) do
        if instance.Material == material then
            return i
        end
    end
end

-- toBlockateSize<instance: Instance> -> number [Internal!]
function toBlockateSize(instance)
    assert(typeof(instance) == "Instance")
    local BlockSizes = require(modules.Data.PropertiesIndex.BlockSizes)
    for i, size in ipairs(BlockSizes) do
        if instance.Size == size.Value then
            return i
        end

        if Vector3.new(instance.Size.X+0.1, instance.Size.Y+0.1, instance.Size.Z+0.1) == size.Value then
            return i
        end
    end
end

-- toBlockateShape<instance: Instance> -> number [Internal!]
function toBlockateShape(instance)
    assert(typeof(instance) == "Instance")
    local BlockShapes = require(modules.Data.PropertiesIndex.BlockShapes)

    if instance.Name == "Part" then
        return 1
    end

    for i, shape in pairs(BlockShapes) do
        if instance.Name == shape.Name then
            return i
        end
    end
end

--[[

    // FUNCTIONS

--]]

-- getBlockProperties<instance: Instance> -> table
function getBlockProperties(instance)
    -- Light properties; because it errors >:(
    local Light, LightColor = 0, "ffff00"
    if instance:FindFirstChild("PointLight") then
        LightColor = instance.PointLight.Color:ToHex()
        Light = instance.PointLight.Range
    end
    
    local properties

    if string.find(instance.Name, "Cube") or string.find(instance.Name, "Ball") then
        properties = {
            [1] = toBlockateCoordinatesFromVector(instance.Functionality.Movable.SpawnPoint.Value),
            [2] = {
                ["Reflectance"] = instance.Reflectance,
                ["CanCollide"] = instance.CanCollide,
                ["Color"] = instance.Color:ToHex(),
                ["LightColor"] = LightColor,
                ["Transparency"] = instance.Transparency,
                ["Light"] = Light,
                ["Material"] = toBlockateMaterial(instance),
                ["Shape"] = toBlockateShape(instance),
                ["Size"] = toBlockateSize(instance)
            }
        }
    else
        properties = {
            [1] = toBlockateCoordinates(instance),
            [2] = {
                ["Reflectance"] = instance.Reflectance,
                ["CanCollide"] = instance.CanCollide,
                ["Color"] = instance.Color:ToHex(),
                ["LightColor"] = LightColor,
                ["Transparency"] = instance.Transparency,
                ["Light"] = Light,
                ["Material"] = toBlockateMaterial(instance),
                ["Shape"] = toBlockateShape(instance),
                ["Size"] = toBlockateSize(instance)
            }
        }
    end

    -- Fix PillarX position kick
    if properties[2]["Size"] == 7 then
        properties[1] = toBlockateCoordinates(instance, true)
    end

    return properties
end

-- get functions
for i,v in pairs(getgc()) do
    if type(v) == "function" and getfenv(v).script == game.ReplicatedStorage.Modules.BlockPosition then
        if getinfo(v).name == "getAxisString" then
            getAxisString = v
        end
    end
end

local HttpService = game:GetService("HttpService")

function WorldCopyPaste_Module:Copy(fileName)
  local HttpService = game:GetService("HttpService")
  local saved = {}
  local savedVectors = {}
for _, block in ipairs(workspace.Blocks:GetChildren()) do

    -- Ignore movables;
    --[[if block.Name == "Cube" or block.Name == "Ball" then
        continue
    end]]
    -- Errors if block has no Creator for some reason..
    --[[if not block:FindFirstChild("Creator") then
        continue
    end]]
    
    if getBlockProperties(block)[2]["Shape"] == 6 then
        continue
    end
    table.insert(saved, getBlockProperties(block))
end

writefile(fileName, HttpService:JSONEncode(saved))
end

function WorldCopyPaste_Module:Paste(fileName)
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local BuildRemote = game:GetService("ReplicatedStorage").Sockets.Edit.Place
local blockCount = 0
local isBuilding = true
local completedBuilding = false
local paintPaused = false

local BuildingProgress = nil
if isfile("BlockateWorldCopier_Progress.txt") then
    BuildingProgress = tonumber(readfile("BlockateWorldCopier_Progress.txt"))
end

local WorldData = HttpService:JSONDecode(readfile(fileName))
local WorldData2 = HttpService:JSONDecode(readfile(fileName))

local Dir = CoreGui:FindFirstChild("RobloxPromptGui"):FindFirstChild("promptOverlay")
Dir.DescendantAdded:Connect(function(Err)
	if Err.Name ~= "ErrorTitle" then return end
    isBuilding = false
end)

local function GivePaintBucket()
    local args = {
        [1] = "!gear me 18474459"
    }

    game:GetService("ReplicatedStorage"):WaitForChild("Sockets"):WaitForChild("Command"):InvokeServer(unpack(args))
end

local function PaintBlock(Block, Color)
    local args = {
        [1] = "PaintPart",
        [2] = {
            ["Part"] = Block,
            ["Color"] = Color
        }
    }
    
    game:GetService("Players").LocalPlayer.Character.PaintBucket.Remotes.ServerControls:InvokeServer(unpack(args))
end

GivePaintBucket()
local PaintBucket = Players.LocalPlayer.Backpack:WaitForChild("PaintBucket")
PaintBucket.Parent = Players.LocalPlayer.Character

PaintBucket:GetPropertyChangedSignal("Parent"):Connect(function()
    if PaintBucket.Parent ~= Players.LocalPlayer.Backpack then return end
    paintPaused = true
    PaintBucket.Parent = Players.LocalPlayer.Character
end)

for i,v in pairs(WorldData) do
    if not isBuilding then
        writefile("BlockateWorldCopier_Progress.txt", i)
        return
    end

    if BuildingProgress then
        if i <= BuildingProgress then
            continue
        end
    end

    task.wait(getgenv().BlockateWorldUtilities_Settings.TIME_BETWEEN_BLOCK_PLACE)
    
    blockCount = i
    task.spawn(function()
        v[2]["Color"] = Color3.fromRGB(242.0000159740448, 243.00001591444016, 243.00001591444016)
        v[2]["LightColor"] = Color3.fromRGB(242.0000159740448, 243.00001591444016, 243.00001591444016)

        local Block = BuildRemote:InvokeServer(table.unpack(v))
        PaintBlock(Block, Color3.fromHex(WorldData2[i][2]["Color"]))
    end)
end

if blockcount == #WorldData then
    completedBuilding = true
end

if completedBuilding then
    delfile("BlockateWorldCopier_Progress.txt")
end
end

return WorldCopyPaste_Module
