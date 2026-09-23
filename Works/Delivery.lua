local ws = game:GetService("Workspace")
local rs = game:GetService("ReplicatedStorage")
local plyrs = game:GetService("Players")
local lp = plyrs.LocalPlayer
local remotes = rs:WaitForChild("Remotes")

if getgenv().DeliveryScriptRunning then return end
getgenv().DeliveryScriptRunning = true
getgenv().DeliveryMode = getgenv().DeliveryMode or "Easy"

local function cleanUp()
    local char = lp.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.Anchored = false
            for _, v in pairs(root:GetChildren()) do
                if v.Name == "AntiFall_Delivery" then v:Destroy() end
            end
        end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = true end
        end
    end
end
cleanUp()

task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().AutoFarmDelivery then
            getgenv().DeliveryScriptRunning = false
            break
        end
        
        local char = lp.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end

        local jobPad = nil
        for _, v in pairs(ws:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Name == "JobPadPrompt" then
                local dist = (char.HumanoidRootPart.Position - v.Parent.Position).Magnitude
                if dist < 20 then
                    jobPad = v
                    break
                end
            end
        end
        
        if jobPad then
            pcall(function() fireproximityprompt(jobPad) end)
            task.wait(1)
            
            local reqStart = remotes:FindFirstChild("RequestStartJobSession")
            if reqStart then pcall(function() reqStart:FireServer("Delivery") end) end
            task.wait(1)
            
            local setMode = remotes:FindFirstChild("SetDeliveryMode")
            if setMode then pcall(function() setMode:FireServer(getgenv().DeliveryMode) end) end
            task.wait(1)
            
            local pickup = remotes:FindFirstChild("AttemptDeliveryPickup")
            if pickup then pcall(function() pickup:InvokeServer() end) end
            
            task.wait(5)
        end
    end
end)
