local required_artifacts = Tracker:FindObjectForCode("RequiredArtifacts")
local final_bosses = Tracker:FindObjectForCode("FinalBoss")
local artifacts = Tracker:FindObjectForCode("Artifacts")
if final_bosses then
    -- ??? allow_disabled is already false and the actual item doesn't show as disabled, so I have
    -- no idea why this is false. I have to do this for the Lua item to not show as disabled
    final_bosses.Active = true
end


local function decrement_required()
    if not required_artifacts then return end
    if required_artifacts.AcquiredCount <= required_artifacts.MinCount then
        required_artifacts.AcquiredCount = required_artifacts.MaxCount
    else
        required_artifacts.AcquiredCount = required_artifacts.AcquiredCount + required_artifacts.Increment
    end
end

local function increment_artifacts()
    if not artifacts then return end
    if artifacts.AcquiredCount >= artifacts.MaxCount then
        artifacts.AcquiredCount = artifacts.MinCount
    else
        artifacts.AcquiredCount = artifacts.AcquiredCount + artifacts.Increment
    end
end

Goal = ScriptHost:CreateLuaItem()
Goal.Name = "Goal"

function Goal.CanProvideCodeFunc(self, code)
    return code == "Goal"
end

Goal.OnLeftClickFunc = decrement_required

function Goal.OnRightClickFunc()
    if not final_bosses then return end
    if final_bosses.CurrentStage == 3 then
        final_bosses.CurrentStage = 0
    else
        final_bosses.CurrentStage = final_bosses.CurrentStage + 1
    end
end

local function update_goal()
    if final_bosses and final_bosses.CurrentStage ~= 3 then
        Goal.Icon = final_bosses.Icon
    else
        Goal.Icon = ImageReference:FromPackRelativePath("images/items/artifacts12.png")
    end
    if required_artifacts then
        Goal:SetOverlay(tostring(required_artifacts.AcquiredCount))
    end
end

ArtifactProgress = ScriptHost:CreateLuaItem()
ArtifactProgress.Name = "Artifacts"
ArtifactProgress.Icon = ImageReference:FromPackRelativePath("images/items/artifacts0.png")

function ArtifactProgress.CanProvideCodeFunc(self, code)
    return code == "ArtifactProgress"
end

ArtifactProgress.OnLeftClickFunc = increment_artifacts

ArtifactProgress.OnRightClickFunc = decrement_required

local function update_progress()
    local acquired = "?"
    if artifacts then acquired = tostring(artifacts.AcquiredCount) end
    if required_artifacts then
        ArtifactProgress:SetOverlay(string.format("%s/%s", acquired, required_artifacts.AcquiredCount))
        if artifacts and artifacts.AcquiredCount >= required_artifacts.AcquiredCount then
            ArtifactProgress:SetOverlayColor("#00ff00")
        else
            ArtifactProgress:SetOverlayColor("")
        end
    else
        ArtifactProgress:SetOverlay(acquired)
    end
end

update_goal()
ScriptHost:AddWatchForCode("GoalArtifacts", "RequiredArtifacts", update_goal)
ScriptHost:AddWatchForCode("GoalBosses", "FinalBoss", update_goal)

update_progress()
ScriptHost:AddWatchForCode("ProgressAcquired", "Artifacts", update_progress)
ScriptHost:AddWatchForCode("ProgressRequired", "RequiredArtifacts", update_progress)
