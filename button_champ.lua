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
local TELEPORT_OFFSET = Vector3.new(0, 1, 0) -- How high above the button to teleport
local MOVE_ASIDE_OFFSET = Vector3.new(3, 0, 3) -- << How far to move sideways after TP (World X, Y, Z) >>
local POST_TELEPORT_DELAY = 0.1 -- << Short delay AFTER teleporting to allow tier rebuild (seconds) >>
local LOOP_DELAY = .3 -- Seconds between the START of each full tier scan
local GUI_NAME = "ButtonTierTeleporter_MultiTP_V3" -- Unique name for the GUI (updated)

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
    print("ButtonTierTeleporter (MultiTP V3): Cleaning up previous GUI instance.")
    oldGui:Destroy()
    task.wait()
end
print("ButtonTierTeleporter (MultiTP V3): Initializing script...")

-- ====================================================
-- GUI Setup (Create Fresh)
-- ====================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Text = "Auto TP All: OFF" -- Updated text
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
    print("ButtonTierTeleporter (MultiTP V3): Updated character references.")
end)


-- ====================================================
-- Toggle Functionality
-- ====================================================
toggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    if isEnabled then
        toggleButton.Text = "Auto TP All: ON" -- Updated text
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        print("ButtonTierTeleporter (MultiTP V3): Enabled")
        if not humanoidRootPart or not humanoidRootPart.Parent then
             character = player.Character
             if character then
                 humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
             end
        end
    else
        toggleButton.Text = "Auto TP All: OFF" -- Updated text
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        print("ButtonTierTeleporter (MultiTP V3): Disabled")
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
-- Main Loop (Checks ALL tiers every cycle, acts on Incomplete AND Complete)
-- ====================================================
print("ButtonTierTeleporter (MultiTP V3): Starting main loop.")
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
        warn("ButtonTierTeleporter (MultiTP V3): Main 'Buttons' folder not found in Workspace yet.")
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

        -- Case 1: Tier is INCOMPLETE (Last button is Plastic)
        if lastButtonTouch and lastButtonTouch.Material == Enum.Material.Plastic then
            actionTakenThisCycle = true
            local targetTeleportPart = nil
            -- Find highest Neon button before the last one
            for buttonNum = lastButtonNum - 1, 1, -1 do
                local currentButton = tierFolder:FindFirstChild(tostring(buttonNum))
                local currentTouch = currentButton and currentButton:FindFirstChild("Touch")
                if currentTouch and currentTouch.Material == Enum.Material.Neon then
                    targetTeleportPart = currentTouch
                    break -- Found highest Neon
                end
            end

            if targetTeleportPart then -- Found a Neon button to TP to
                 if humanoidRootPart and humanoidRootPart.Parent then
                    local targetButtonPosition = targetTeleportPart.Position
                    local teleportAbovePosition = targetButtonPosition + TELEPORT_OFFSET
                    humanoidRootPart.CFrame = CFrame.new(teleportAbovePosition)
                    print(string.format("ButtonTierTeleporter (MultiTP V3): Teleporting above INCOMPLETE tier's highest Neon: %s %s", tierName, targetTeleportPart.Parent.Name))
                    task.wait(LOOP_DELAY)
                    humanoidRootPart.CFrame = humanoidRootPart.CFrame + MOVE_ASIDE_OFFSET
                    print("ButtonTierTeleporter (MultiTP V3): Moved aside.")
                    task.wait(POST_TELEPORT_DELAY)
                 else
                     print("ButtonTierTeleporter (MultiTP V3): Teleport cancelled (Incomplete Tier), HRP lost.")
                 end
            else -- Incomplete tier, but no preceding Neon found
                print(string.format("ButtonTierTeleporter (MultiTP V3): Identified %s as incomplete (first button likely Plastic). No preceding Neon TP target.", tierName))
                -- Optionally add a small delay here too if needed, otherwise it just moves to the next tier check
                -- task.wait(0.05)
            end

        -- Case 2: Tier is COMPLETE (Last button is Neon)
        elseif lastButtonTouch and lastButtonTouch.Material == Enum.Material.Neon then
             actionTakenThisCycle = true
             -- Teleport to the LAST button of this COMPLETED tier
             if humanoidRootPart and humanoidRootPart.Parent then
                local targetButtonPosition = lastButtonTouch.Position -- Target is the last button's touch part
                local teleportAbovePosition = targetButtonPosition + TELEPORT_OFFSET
                humanoidRootPart.CFrame = CFrame.new(teleportAbovePosition)
                -- Use lastButtonTouch.Parent.Name which should be the button number model's name
                print(string.format("ButtonTierTeleporter (MultiTP V3): Teleporting above COMPLETED tier's last button: %s %s", tierName, lastButtonTouch.Parent.Name))

                humanoidRootPart.CFrame = humanoidRootPart.CFrame + MOVE_ASIDE_OFFSET
                print("ButtonTierTeleporter (MultiTP V3): Moved aside.")
                task.wait(POST_TELEPORT_DELAY)
             else
                 print("ButtonTierTeleporter (MultiTP V3): Teleport cancelled (Complete Tier), HRP lost.")
             end

        -- Case 3: Unknown state or error
        else
             -- Could not determine state or find touch part, continue to next tier
             continue
        end

        -- No 'break' statements here, allowing the loop to continue to the next tier regardless

    end -- End of the FOR loop iterating through tiers

    -- Optional: Message if a full pass resulted in no action needed (Shouldn't happen if any tiers exist)
    if not actionTakenThisCycle and isEnabled then
         print("ButtonTierTeleporter (MultiTP V3): Full tier scan complete. No actions taken (maybe no tiers found?).")
    end

end -- End of main while loop