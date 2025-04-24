-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService") -- Or use task.wait() for loop delay
local UserInputService = game:GetService("UserInputService") -- Added for potential future use, good practice

-- Configuration
local BUTTON_TIERS = {
    "Multiplier", "Rebirth", "Ultra", "Omega", "Insane",
    "Extreme", "Hyper", "Godly", "Supreme", "Cyber",
    "Hologram", "Sakura"
}
local BUTTONS_PARENT_FOLDER_PATH = "Buttons" -- Relative path within Workspace
local MAX_BUTTON_NUMBER_TO_CHECK = 15 -- How high to check for the last button number (adjust if tiers have more)
local TELEPORT_OFFSET = Vector3.new(0, 2, 0) -- How high above the button to teleport
local LOOP_DELAY = 1 -- Seconds between checks when active
local GUI_NAME = "ButtonTierTeleporterGui" -- Unique name for the GUI

-- Player Variables
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") -- Get PlayerGui service safely

-- State Variable
local isEnabled = false -- Default to off each time script runs

-- ====================================================
-- Cleanup Previous Instances
-- ====================================================
-- Check if a GUI with the same name already exists and destroy it
local oldGui = playerGui:FindFirstChild(GUI_NAME)
if oldGui then
    print("ButtonTierTeleporter: Cleaning up previous GUI instance.")
    oldGui:Destroy()
    -- Wait a frame to ensure destruction completes if needed, though usually synchronous
    task.wait()
end
print("ButtonTierTeleporter: Initializing script...")

-- ====================================================
-- GUI Setup (Create Fresh)
-- ====================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false -- Keep GUI state after player respawn, but script re-run cleans it
screenGui.Parent = playerGui -- Parent to the obtained PlayerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Text = "Auto TP: OFF" -- Start as OFF
toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red for OFF
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Size = UDim2.new(0, 150, 0, 50)
toggleButton.Position = UDim2.new(0, 10, 0.5, 0) -- Position near left-middle edge
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.TextSize = 18
toggleButton.Parent = screenGui

-- ====================================================
-- Core Logic Variables (Initialized after cleanup/GUI creation)
-- ====================================================
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Ensure HRP is updated if character resets during gameplay
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
    print("ButtonTierTeleporter: Updated character references.")
end)


-- ====================================================
-- Toggle Functionality
-- ====================================================
toggleButton.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled -- Flip the state
    if isEnabled then
        toggleButton.Text = "Auto TP: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Green for ON
        print("ButtonTierTeleporter: Enabled")
        -- Immediately try to find HRP if it was missing
        if not humanoidRootPart or not humanoidRootPart.Parent then
             character = player.Character
             if character then
                 humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
             end
        end
    else
        toggleButton.Text = "Auto TP: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red for OFF
        print("ButtonTierTeleporter: Disabled")
    end
end)

-- ====================================================
-- Helper Functions
-- ====================================================
-- Function to find the actual highest button number in a tier
local function findLastButtonNumber(tierFolder)
    local lastNum = 0
    -- Iterate downwards to find the highest existing numbered child efficiently
    for i = MAX_BUTTON_NUMBER_TO_CHECK, 1, -1 do
        local buttonModel = tierFolder:FindFirstChild(tostring(i))
        -- Optional: Check if it's actually a Model, though structure implies it is
        if buttonModel then -- and buttonModel:IsA("Model") then
            lastNum = i
            break -- Found the highest numbered button model that exists
        end
    end
    return lastNum
end

-- ====================================================
-- Main Loop
-- ====================================================
print("ButtonTierTeleporter: Starting main loop.")
while true do
    local waitTime = isEnabled and LOOP_DELAY or 1 -- Wait short if enabled, longer if disabled
    task.wait(waitTime)

    -- Only run core logic if enabled
    if not isEnabled then
        continue -- Skip the rest of the loop iteration
    end

    -- Validate Character and HumanoidRootPart before proceeding
    if not character or not character.Parent then
        -- Attempt to get character again if needed
        character = player.Character
        if not character then
            -- print("ButtonTierTeleporter: Waiting for character...") -- Optional debug spam
            continue
        end
    end

    if not humanoidRootPart or not humanoidRootPart.Parent then
        -- Attempt to get HRP again if needed
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
             -- print("ButtonTierTeleporter: Waiting for HumanoidRootPart...") -- Optional debug spam
             continue
        end
    end

    -- Attempt to find the main buttons folder dynamically each cycle - safer if it loads late
    local buttonsParentFolder = Workspace:FindFirstChild(BUTTONS_PARENT_FOLDER_PATH)
    if not buttonsParentFolder then
        warn("ButtonTierTeleporter: Main 'Buttons' folder not found in Workspace yet.")
        continue -- Wait for the folder to exist
    end


    local teleportedThisCycle = false

    -- Iterate through the defined tiers
    for _, tierName in ipairs(BUTTON_TIERS) do
        local tierFolder = buttonsParentFolder:FindFirstChild(tierName)

        if not tierFolder then
            -- This is expected if player hasn't unlocked the tier yet, don't warn unless debugging
            -- print("ButtonTierTeleporter: Could not find tier folder:", tierName)
            continue -- Skip to the next tier
        end

        local lastButtonNum = findLastButtonNumber(tierFolder)
        if lastButtonNum == 0 then
            -- Might happen if tier folder exists but buttons aren't named 1..N or are missing
            -- warn("ButtonTierTeleporter: Could not find any numbered buttons in tier:", tierName)
            continue -- Skip if no numbered buttons found
        end

        -- Get the touch part of the *last* button in the tier
        local lastButton = tierFolder:FindFirstChild(tostring(lastButtonNum))
        local lastButtonTouch = lastButton and lastButton:FindFirstChild("Touch") -- Safely find Touch part

        -- Check if the tier is incomplete (last button exists, has Touch, and is Plastic)
        if lastButtonTouch and lastButtonTouch.Material == Enum.Material.Plastic then
            -- Tier is incomplete, find the highest Neon button in this tier
            local targetTeleportPart = nil
            -- Iterate downwards from one below the last existing button
            for buttonNum = lastButtonNum - 1, 1, -1 do
                local currentButton = tierFolder:FindFirstChild(tostring(buttonNum))
                local currentTouch = currentButton and currentButton:FindFirstChild("Touch")

                if currentTouch and currentTouch.Material == Enum.Material.Neon then
                    -- Found the highest Neon button in this incomplete tier
                    targetTeleportPart = currentTouch
                    -- print("ButtonTierTeleporter: Found target button:", tierName, buttonNum) -- Optional debug
                    break -- Stop searching in this tier
                end
            end

            -- If we found a Neon button to teleport to
            if targetTeleportPart then
                -- Double-check HRP right before teleporting
                 if humanoidRootPart and humanoidRootPart.Parent then
                    local targetPosition = targetTeleportPart.Position + TELEPORT_OFFSET
                    humanoidRootPart.CFrame = CFrame.new(targetPosition)
                    print("ButtonTierTeleporter: Teleporting to:", tierName, targetTeleportPart.Parent.Name)
                    teleportedThisCycle = true
                    break -- Exit the tier loop for this cycle, start again next cycle
                 else
                     print("ButtonTierTeleporter: Teleport cancelled, HumanoidRootPart lost.")
                     -- Might want to set isEnabled = false here or just let the loop re-verify
                 end
            else
                -- This case means the tier's last button is Plastic, but no preceding Neon buttons were found.
                -- This is normal if only the first button is unlocked and it's Plastic.
                -- print("ButtonTierTeleporter: Tier", tierName, "is incomplete, but no previous Neon button found to teleport to.") -- Optional debug
                -- Since no target found, we need to process the next tier, so we implicitly continue the tier loop.
                -- IMPORTANT: If we found an incomplete tier, even if we didn't find a Neon button to TP to,
                -- we should stop checking further tiers in this cycle, as this IS the tier to work on.
                teleportedThisCycle = true -- Mark that we found the active tier, even if no TP spot
                print("ButtonTierTeleporter: Identified", tierName, "as the current tier (first button likely Plastic). Stopping tier check for this cycle.")
                break -- Exit the tier loop, focus on this tier next cycle.

            end

        elseif lastButtonTouch and lastButtonTouch.Material == Enum.Material.Neon then
             -- Tier is complete (last button is Neon), skip to the next tier
             -- print("Tier", tierName, "is complete (Neon). Skipping.") -- Optional debug
             continue -- Continue the FOR loop to the next tier
        else
             -- Last button touch part not found or has an unexpected material
             -- This could happen if the button model structure is wrong.
             -- warn("ButtonTierTeleporter: Could not determine status of tier", tierName, "- skipping.")
             continue -- Continue the FOR loop to the next tier
        end
    end -- End of tier loop

    -- If we looped through all tiers and didn't identify an active one (didn't teleport and didn't break early)
    if not teleportedThisCycle and isEnabled then
         -- This now primarily means all tiers are fully completed (last button is Neon)
         print("ButtonTierTeleporter: All checked tiers appear complete. Waiting...")
    end
end -- End of main while loop