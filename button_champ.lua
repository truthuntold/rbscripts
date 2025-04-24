-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Configuration
local BUTTON_TIERS = {
    "Multiplier", "Rebirth", "Ultra", "Omega", "Insane",
    "Extreme", "Hyper", "Godly", "Supreme", "Cyber",
    "Hologram", "Sakura"
}
local BUTTONS_PARENT_FOLDER_PATH = "Buttons" -- Relative path within Workspace
local MAX_BUTTON_NUMBER_TO_CHECK = 16 -- <<<< MAKE SURE THIS IS >= HIGHEST BUTTON # (e.g., 15 for Hyper) >>>>
local TELEPORT_OFFSET = Vector3.new(0, 3, 0) -- How high above the button to teleport
local LOOP_DELAY = .3 -- Seconds between the START of each full tier scan
local GUI_NAME = "ButtonTierTeleporterGui_MultiTP" -- Unique name for the GUI (changed slightly)

-- Player Variables
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- State Variable
local isEnabled = false

-- ====================================================
-- Cleanup Previous Instances
-- ====================================================
local oldGui = playerGui:FindFirstChild(GUI_NAME)
if oldGui then
    print("ButtonTierTeleporter (MultiTP): Cleaning up previous GUI instance.")
    oldGui:Destroy()
    task.wait()
end
print("ButtonTierTeleporter (MultiTP): Initializing script...")

-- ====================================================
-- GUI Setup (Create Fresh)
-- ====================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Text = "Auto Multi-TP: OFF" -- Updated text
toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Size = UDim2.new(0, 150, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0.5, 0)
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.Parent = screenGui

-- ====================================================
-- Core Logic Variables (Initialized after cleanup/GUI creation)
-- ====================================================
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
    print("ButtonTierTeleporter (MultiTP): Updated character references.")
end)


-- ====================================================
-- Toggle Functionality
-- ====================================================
toggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    if isEnabled then
        toggleButton.Text = "Auto Multi-TP: ON" -- Updated text
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        print("ButtonTierTeleporter (MultiTP): Enabled")
        if not humanoidRootPart or not humanoidRootPart.Parent then
             character = player.Character
             if character then
                 humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
             end
        end
    else
        toggleButton.Text = "Auto Multi-TP: OFF" -- Updated text
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        print("ButtonTierTeleporter (MultiTP): Disabled")
    end
end)

-- ====================================================
-- Helper Functions
-- ====================================================
local function findLastButtonNumber(tierFolder)
    local lastNum = 0
    for i = MAX_BUTTON_NUMBER_TO_CHECK, 1, -1 do
        local buttonModel = tierFolder:FindFirstChild(tostring(i))
        if buttonModel then
            lastNum = i
            break
        end
    end
    return lastNum
end

-- ====================================================
-- Main Loop (Checks ALL tiers every cycle)
-- ====================================================
print("ButtonTierTeleporter (MultiTP): Starting main loop.")
while true do
    local waitTime = isEnabled and LOOP_DELAY or 1
    task.wait(waitTime)

    if not isEnabled then
        continue
    end

    if not character or not character.Parent then
        character = player.Character
        if not character then
            continue
        end
    end

    if not humanoidRootPart or not humanoidRootPart.Parent then
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
             continue
        end
    end

    local buttonsParentFolder = Workspace:FindFirstChild(BUTTONS_PARENT_FOLDER_PATH)
    if not buttonsParentFolder then
        warn("ButtonTierTeleporter (MultiTP): Main 'Buttons' folder not found in Workspace yet.")
        continue
    end

    local actionTakenThisCycle = false -- Tracks if any TP or identification happened

    -- Iterate through ALL defined tiers in THIS cycle
    for _, tierName in ipairs(BUTTON_TIERS) do
        local tierFolder = buttonsParentFolder:FindFirstChild(tierName)

        if not tierFolder then
            continue -- Skip to the next tier
        end

        local lastButtonNum = findLastButtonNumber(tierFolder)
        if lastButtonNum == 0 then
            continue -- Skip if no numbered buttons found
        end

        local lastButton = tierFolder:FindFirstChild(tostring(lastButtonNum))
        local lastButtonTouch = lastButton and lastButton:FindFirstChild("Touch")

        -- Check if the tier is incomplete
        if lastButtonTouch and lastButtonTouch.Material == Enum.Material.Plastic then
            -- Tier is incomplete, find the highest Neon button in this tier
            local targetTeleportPart = nil
            for buttonNum = lastButtonNum - 1, 1, -1 do
                local currentButton = tierFolder:FindFirstChild(tostring(buttonNum))
                local currentTouch = currentButton and currentButton:FindFirstChild("Touch")

                if currentTouch and currentTouch.Material == Enum.Material.Neon then
                    targetTeleportPart = currentTouch
                    break -- Found the highest NEON, stop searching *within this tier*
                end
            end

            -- If we found a Neon button to teleport to in this tier
            if targetTeleportPart then
                 if humanoidRootPart and humanoidRootPart.Parent then
                    local targetPosition = targetTeleportPart.Position + TELEPORT_OFFSET
                    humanoidRootPart.CFrame = CFrame.new(targetPosition)
                    print("ButtonTierTeleporter (MultiTP): Teleporting to:", tierName, targetTeleportPart.Parent.Name)
                    actionTakenThisCycle = true
                    -- << NO BREAK HERE >> -- Allows checking subsequent tiers in the same cycle
                 else
                     print("ButtonTierTeleporter (MultiTP): Teleport cancelled, HumanoidRootPart lost.")
                 end
            else
                -- Incomplete tier, but no preceding Neon button found (likely button 1 is Plastic)
                actionTakenThisCycle = true -- Mark that we identified an active tier
                print("ButtonTierTeleporter (MultiTP): Identified", tierName, "as incomplete (first button likely Plastic).")
                -- << NO BREAK HERE >> -- Allows checking subsequent tiers in the same cycle
            end

        elseif lastButtonTouch and lastButtonTouch.Material == Enum.Material.Neon then
             -- Tier is complete (last button is Neon), skip to the next tier
             continue -- Continue the FOR loop to the next tier
        else
             -- Error case (cannot determine status), skip to the next tier
             continue -- Continue the FOR loop to the next tier
        end

    end -- End of the FOR loop iterating through tiers for THIS cycle

    -- Optional: Message if a full pass resulted in no action (likely all tiers complete)
    if not actionTakenThisCycle and isEnabled then
         print("ButtonTierTeleporter (MultiTP): Full tier scan complete. No incomplete tiers found needing action.")
    end

end -- End of main while loop