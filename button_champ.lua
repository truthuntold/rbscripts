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
local MAX_BUTTON_NUMBER_TO_CHECK = 15 -- <<<< MAKE SURE THIS IS >= HIGHEST BUTTON # (e.g., 15 for Hyper) >>>>
local TELEPORT_OFFSET = Vector3.new(0, 5, 0) -- How high above the button to teleport
local MOVE_ASIDE_OFFSET = Vector3.new(2, 0, 1) -- << How far to move sideways after TP (World X, Y, Z) >>
local POST_TELEPORT_DELAY = 0.1 -- << Short delay AFTER teleporting to allow tier rebuild (seconds) >>
local LOOP_DELAY = 1 -- Seconds between the START of each full tier scan
local GUI_NAME = "ButtonTierTeleporter_MultiTP_V2" -- Unique name for the GUI (updated)

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
    print("ButtonTierTeleporter (MultiTP V2): Cleaning up previous GUI instance.")
    oldGui:Destroy()
    task.wait()
end
print("ButtonTierTeleporter (MultiTP V2): Initializing script...")

-- ====================================================
-- GUI Setup (Create Fresh)
-- ====================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Text = "Auto Multi-TP: OFF"
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
    print("ButtonTierTeleporter (MultiTP V2): Updated character references.")
end)


-- ====================================================
-- Toggle Functionality
-- ====================================================
toggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    if isEnabled then
        toggleButton.Text = "Auto Multi-TP: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        print("ButtonTierTeleporter (MultiTP V2): Enabled")
        if not humanoidRootPart or not humanoidRootPart.Parent then
             character = player.Character
             if character then
                 humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
             end
        end
    else
        toggleButton.Text = "Auto Multi-TP: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        print("ButtonTierTeleporter (MultiTP V2): Disabled")
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
print("ButtonTierTeleporter (MultiTP V2): Starting main loop.")
while true do
    -- Main delay between full scans
    local waitTime = isEnabled and LOOP_DELAY or 1
    task.wait(waitTime)

    -- Only run if enabled
    if not isEnabled then
        continue
    end

    -- Validate character and HumanoidRootPart
    if not character or not character.Parent then
        character = player.Character
        if not character then continue end
    end
    if not humanoidRootPart or not humanoidRootPart.Parent then
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then continue end
    end

    -- Find buttons folder
    local buttonsParentFolder = Workspace:FindFirstChild(BUTTONS_PARENT_FOLDER_PATH)
    if not buttonsParentFolder then
        warn("ButtonTierTeleporter (MultiTP V2): Main 'Buttons' folder not found in Workspace yet.")
        continue
    end

    local actionTakenThisCycle = false

    -- Iterate through ALL defined tiers in THIS cycle
    for _, tierName in ipairs(BUTTON_TIERS) do
        local tierFolder = buttonsParentFolder:FindFirstChild(tierName)
        if not tierFolder then continue end -- Skip if tier folder doesn't exist

        local lastButtonNum = findLastButtonNumber(tierFolder)
        if lastButtonNum == 0 then continue end -- Skip if no numbered buttons

        local lastButton = tierFolder:FindFirstChild(tostring(lastButtonNum))
        local lastButtonTouch = lastButton and lastButton:FindFirstChild("Touch")

        -- Check if the tier is incomplete
        if lastButtonTouch and lastButtonTouch.Material == Enum.Material.Plastic then
            actionTakenThisCycle = true -- Mark action needed for this tier

            -- Find the highest Neon button
            local targetTeleportPart = nil
            for buttonNum = lastButtonNum - 1, 1, -1 do
                local currentButton = tierFolder:FindFirstChild(tostring(buttonNum))
                local currentTouch = currentButton and currentButton:FindFirstChild("Touch")
                if currentTouch and currentTouch.Material == Enum.Material.Neon then
                    targetTeleportPart = currentTouch
                    break -- Found highest Neon in this tier
                end
            end

            -- If we found a Neon button to teleport to
            if targetTeleportPart then
                 if humanoidRootPart and humanoidRootPart.Parent then
                    -- 1. Teleport slightly above the target button
                    local targetButtonPosition = targetTeleportPart.Position
                    local teleportAbovePosition = targetButtonPosition + TELEPORT_OFFSET
                    humanoidRootPart.CFrame = CFrame.new(teleportAbovePosition)
                    print(string.format("ButtonTierTeleporter (MultiTP V2): Teleporting above: %s %s", tierName, targetTeleportPart.Parent.Name))

                    -- 2. Move slightly aside immediately after teleporting
                    -- Wait a tiny moment for physics to settle from TP if needed (optional)
                    -- task.wait()
                    humanoidRootPart.CFrame = humanoidRootPart.CFrame + MOVE_ASIDE_OFFSET
                    print("ButtonTierTeleporter (MultiTP V2): Moved aside.")

                    -- 3. Add a short delay specifically AFTER teleporting
                    -- This gives time for lower tiers to rebuild (Plastic->Neon flash)
                    task.wait(POST_TELEPORT_DELAY)

                    -- No 'break' here - allows checking subsequent tiers per user request

                 else
                     print("ButtonTierTeleporter (MultiTP V2): Teleport cancelled, HumanoidRootPart lost.")
                 end
            else
                -- Incomplete tier, but no preceding Neon button found
                print(string.format("ButtonTierTeleporter (MultiTP V2): Identified %s as incomplete (first button likely Plastic).", tierName))
                -- No 'break' here
            end

        elseif lastButtonTouch and lastButtonTouch.Material == Enum.Material.Neon then
             -- Tier is complete, continue to the next tier
             continue
        else
             -- Error case, continue to the next tier
             continue
        end

    end -- End of the FOR loop iterating through tiers

    -- Optional: Message if a full pass resulted in no action needed
    if not actionTakenThisCycle and isEnabled then
         print("ButtonTierTeleporter (MultiTP V2): Full tier scan complete. No incomplete tiers found needing action.")
    end

end -- End of main while loop