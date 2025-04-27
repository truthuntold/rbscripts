-- LocalScript: Teleport Saver GUI
-- Place this in StarterPlayerScripts or a LocalScript under StarterGui

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local guiName = "TeleportSaverGui"

-- Clean up existing GUI if present
local playerGui = player:WaitForChild("PlayerGui")
local existingGui = playerGui:FindFirstChild(guiName)
if existingGui then
    existingGui:Destroy()
end

-- Create ScreenGui container
local screenGui = Instance.new("ScreenGui")
screenGui.Name = guiName
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Create a frame to hold buttons
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 300)
frame.Position = UDim2.new(0, 10, 0.5, -150)
frame.BackgroundTransparency = 0.3
frame.BorderSizePixel = 1
frame.Parent = screenGui

-- Table to store saved CFrame positions
local savedPositions = {}

-- Function to create a save button
local function createSaveButton(index)
    local button = Instance.new("TextButton")
    button.Name = "Save" .. index
    button.Text = "Save " .. index
    button.Size = UDim2.new(1, -10, 0, 40)
    button.Position = UDim2.new(0, 5, 0, 5 + (index - 1) * 45)
    button.Parent = frame

    button.MouseButton1Click:Connect(function()
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                savedPositions[index] = hrp.CFrame
                button.BackgroundColor3 = Color3.new(0, 1, 0) -- indicate saved
            end
        end
    end)
end

-- Create five save buttons
for i = 1, 5 do
    createSaveButton(i)
end

-- Loop toggle button
local loopButton = Instance.new("TextButton")
loopButton.Name = "LoopToggle"
loopButton.Text = "Start Loop"
loopButton.Size = UDim2.new(1, -10, 0, 40)
loopButton.Position = UDim2.new(0, 5, 0, 5 + 5 * 45)
loopButton.Parent = frame

local looping = false
local loopThread = nil

local function teleportSequence()
    while looping do
        for i = 1, 5 do
            if not looping then return end
            local cf = savedPositions[i]
            if cf then
                local char = player.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = cf
                    end
                end
            end
            task.wait(0.1)
        end
    end
end

loopButton.MouseButton1Click:Connect(function()
    looping = not looping
    if looping then
        loopButton.Text = "Stop Loop"
        -- start teleport coroutine
        loopThread = task.spawn(teleportSequence)
    else
        loopButton.Text = "Start Loop"
        -- stopping the loopSequence by toggling looping to false
    end
end)
