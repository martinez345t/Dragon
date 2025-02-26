--[[
    Sistema Automatizado de Farming v2.1
    Características principales:
    1. AutoFarm inteligente con pathfinding
    2. AutoCollect con detección de proximidad
    3. Interfaz de usuario adaptable
    4. Sistema anti-AFK
    5. Notificaciones del sistema
    6. Prevención de errores
    7. Configuración personalizable
    8. Registro de estadísticas
]]

------ SERVICIOS ------
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local Pathfinding = game:GetService("PathfindingService")
local VirtualInput = game:GetService("VirtualInputManager")

------ CONFIGURACIÓN ------
local SETTINGS = {
    FarmKey = Enum.KeyCode.F,
    CollectRange = 20,
    WalkSpeed = 24,
    FarmRadius = 200,
    Collectables = {"Apple", "Coin", "Gem"},
    Blacklist = {"Enemy", "Trap"},
    UpdateInterval = 0.5
}

------ VARIABLES ------
local player = Players.LocalPlayer
local character, humanoid, root
local isRunning = false
local path
local connections = {}

------ ESTADÍSTICAS ------
local stats = {
    collectedItems = 0,
    lastCollectedItem = nil
}

------ INICIALIZACIÓN ------
local function initCharacter()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    root = character:WaitForChild("HumanoidRootPart")
    humanoid.WalkSpeed = SETTINGS.WalkSpeed
end

player.CharacterAdded:Connect(initCharacter)
initCharacter()

------ SISTEMA DE NOTIFICACIONES ------
local function showNotification(message)
    if not player.PlayerGui:FindFirstChild("Notifications") then
        local gui = Instance.new("ScreenGui")
        gui.Name = "Notifications"
        gui.Parent = player.PlayerGui
    end
    
    local notif = Instance.new("TextLabel")
    notif.Size = UDim2.new(0.4, 0, 0.1, 0)
    notif.Position = UDim2.new(0.3, 0, 0.05, 0)
    notif.Text = "📢 "..message
    notif.BackgroundColor3 = Color3.new(0, 0.2, 0.4)
    notif.TextColor3 = Color3.new(1, 1, 1)
    notif.Parent = player.PlayerGui.Notifications
    
    task.delay(3, function()
        notif:Destroy()
    end)
end

------ SISTEMA DE PATHFINDING MEJORADO ------
local function calculatePath(target)
    path = Pathfinding:CreatePath()
    path:ComputeAsync(root.Position, target)
    
    if path.Status == Enum.PathStatus.Success then
        return path:GetWaypoints()
    end
    return nil
end

------ LÓGICA DE AUTO-FARM ------
local function findFarmTarget()
    local targets = {}
    for _, obj in pairs(workspace:GetChildren()) do
        if table.find(SETTINGS.Collectables, obj.Name) and not table.find(SETTINGS.Blacklist, obj.Name) then
            if (root.Position - obj.Position).Magnitude < SETTINGS.FarmRadius then
                table.insert(targets, obj)
            end
        end
    end
    
    if #targets > 0 then
        return targets[math.random(1, #targets)].Position
    end
    return nil
end

------ SISTEMA DE AUTO-COLLECT ------
local function collectItems()
    for _, item in pairs(workspace:GetChildren()) do
        if table.find(SETTINGS.Collectables, item.Name) then
            if (root.Position - item.Position).Magnitude < SETTINGS.CollectRange then
                -- Simular click en el objeto
                firetouchinterest(root, item, 0)
                firetouchinterest(root, item, 1)
                stats.collectedItems = stats.collectedItems + 1
                stats.lastCollectedItem = item.Name
            end
        end
    end
end

------ SISTEMA ANTI-AFK ------
local function antiAFK()
    VirtualInput:SendKeyEvent(true, Enum.KeyCode.W, false, nil)
    task.wait(0.1)
    VirtualInput:SendKeyEvent(false, Enum.KeyCode.W, false, nil)
end

------ CICLO PRINCIPAL ------
local function mainLoop()
    while isRunning do
        local target = findFarmTarget()
        
        if target then
            local waypoints = calculatePath(target)
            if waypoints then
                for _, wp in pairs(waypoints) do
                    humanoid:MoveTo(wp.Position)
                    humanoid.MoveToFinished:Wait()
                end
            end
        end
        
        collectItems()
        
        antiAFK()
        
        task.wait(SETTINGS.UpdateInterval)
    end
end

------ INTERFAZ DE USUARIO ------
local function createGUI()
    local gui = player.PlayerGui:FindFirstChild("FarmGUI") or Instance.new("ScreenGui")
    gui.Name = "FarmGUI"
    gui.Parent = player.PlayerGui

    local button = Instance.new("TextButton")
    button.Name = "MainButton"
    button.Size = UDim2.new(0, 200, 0, 50)
    button.Position = UDim2.new(1, -210, 1, -60)
    button.AnchorPoint = Vector2.new(1, 1)
    button.Text = "▶ Iniciar Farming"
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    button.TextColor3 = Color3.new(1, 1, 1)
    
    local statusLight = Instance.new("Frame")
    statusLight.Size = UDim2.new(0, 15, 0, 15)
    statusLight.Position = UDim2.new(1, -20, 0.5, -7)
    statusLight.BackgroundColor3 = Color3.new(1, 0, 0)
    statusLight.Parent = button
    
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(0, 300, 0, 50)
    statsLabel.Position = UDim2.new(1, -310, 1, -120)
    statsLabel.BackgroundColor3 = Color3.new(0, 0, 0)
    statsLabel.TextColor3 = Color3.new(1, 1, 0)
    statsLabel.TextScaled = true
    statsLabel.Parent = gui

    button.Parent = gui
    
    button.MouseButton1Click:Connect(function()
        isRunning = not isRunning
        button.Text = isRunning and "⏸ Detener Farming" or "▶ Iniciar Farming"
        statusLight.BackgroundColor3 = isRunning and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
        
        if isRunning then
            showNotification("Sistema de Farming activado")
            coroutine.wrap(mainLoop)()
        else
            showNotification("Sistema de Farming detenido")
        end
    end)
    
    RS.Heartbeat:Connect(function()
        if isRunning then
            statsLabel.Text = string.format("Items recolectados: %d\nÚltimo objeto recolectado: %s", 
                stats.collectedItems, stats.lastCollectedItem or "Ninguno")
        end
    end)
end

------ CONFIGURACIÓN DE CONTROLES ------
local function setupControls()
    if UIS.KeyboardEnabled then
        UIS.InputBegan:Connect(function(input)
            if input.KeyCode == SETTINGS.FarmKey then
                isRunning = not isRunning
                if isRunning then
                    coroutine.wrap(mainLoop)()
                end
            end
        end)
    else
        createGUI()
    end
end

------ SISTEMA DE SEGURIDAD ------
connections.healthCheck = RS.Heartbeat:Connect(function()
    if isRunning and (humanoid.Health <= 0 or not root) then
        isRunning = false
        showNotification("¡Sistema detenido! (Personaje no válido)")
    end
end)

------ INICIALIZAR ------
setupControls()
createGUI()
showNotification("Sistema de Farming listo")

   