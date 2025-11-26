--!strict
-- Breaking Point - EnemyAI module (serveur)

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local EnemyAI = {}
EnemyAI.__index = EnemyAI

export type EnemyConfig = {
enemyModel: Model,
patrolPoints: {BasePart},
visionAngle: number?,
visionDistance: number?,
coverNodes: {BasePart}?,
shootCooldown: number?,
}

local activeAIs: {EnemyAI} = {}

local function lookAt(target: Vector3, humanoidRootPart: BasePart)
humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, Vector3.new(target.X, humanoidRootPart.Position.Y, target.Z))
end

local function playerVisible(ai: EnemyAI, player: Player): boolean
local char = player.Character
if not char then return false end
local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then return false end

local origin = ai.model.HumanoidRootPart.Position
local direction = (hrp.Position - origin)
local distance = direction.Magnitude
if distance > ai.visionDistance then return false end

local forward = ai.model.HumanoidRootPart.CFrame.LookVector
local angle = math.deg(math.acos(forward:Dot(direction.Unit)))
if angle > ai.visionAngle / 2 then return false end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Blacklist
params.FilterDescendantsInstances = {ai.model}
local result = workspace:Raycast(origin, direction, params)
return result and result.Instance and result.Instance:IsDescendantOf(char) or false
end

function EnemyAI.new(config: EnemyConfig)
local self = setmetatable({}, EnemyAI)
self.model = config.enemyModel
self.humanoid = self.model:FindFirstChildOfClass("Humanoid")
self.patrolPoints = config.patrolPoints
self.currentIndex = 1
self.state = "Patrol"
self.visionAngle = config.visionAngle or 90
self.visionDistance = config.visionDistance or 80
self.coverNodes = config.coverNodes or {}
self.shootCooldown = config.shootCooldown or 1.5
self.lastShot = 0
return self
end

function EnemyAI:step(dt: number)
local player = game.Players:GetPlayers()[1]
if not player then return end

if self.state == "Patrol" then
self:patrol()
if playerVisible(self, player) then
self.state = "Alert"
end
elseif self.state == "Alert" then
if playerVisible(self, player) then
self.state = "Combat"
else
self.state = "Patrol"
end
elseif self.state == "Combat" then
self:engage(player, dt)
end
end

function EnemyAI:patrol()
local targetPoint = self.patrolPoints[self.currentIndex]
if not targetPoint then return end
local hrp = self.model:FindFirstChild("HumanoidRootPart")
if not hrp then return end
self.model:MoveTo(targetPoint.Position)
if (hrp.Position - targetPoint.Position).Magnitude < 2 then
self.currentIndex = (self.currentIndex % #self.patrolPoints) + 1
end
end

function EnemyAI:findCover(): BasePart?
local hrp = self.model:FindFirstChild("HumanoidRootPart")
if not hrp then return nil end
local best: BasePart? = nil
local bestDist = math.huge
for _, node in ipairs(self.coverNodes) do
local d = (node.Position - hrp.Position).Magnitude
if d < bestDist then
bestDist = d
best = node
end
end
return best
end

function EnemyAI:engage(player: Player, dt: number)
local hrp = self.model:FindFirstChild("HumanoidRootPart")
local humanoid = self.humanoid
if not hrp or not humanoid then return end
local cover = self:findCover()
if cover then
humanoid:MoveTo(cover.Position)
else
humanoid:MoveTo(player.Character and player.Character:GetPivot().Position or hrp.Position)
end

if playerVisible(self, player) and (os.clock() - self.lastShot) >= self.shootCooldown then
self.lastShot = os.clock()
lookAt(player.Character.HumanoidRootPart.Position, hrp)
-- Simple damage application: assume hitscan from enemy
local targetHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
if targetHum then
targetHum:TakeDamage(10)
end
end
end

function EnemyAI:OnDamage(amount: number)
if self.state == "Idle" or self.state == "Patrol" then
self.state = "Combat"
end
end

-- Spawner helpers
function EnemyAI.Spawn(enemyModel: Model, config)
local ai = EnemyAI.new({
enemyModel = enemyModel,
patrolPoints = config.patrolPoints,
visionAngle = config.visionAngle,
visionDistance = config.visionDistance,
coverNodes = config.coverNodes,
shootCooldown = config.shootCooldown,
})
table.insert(activeAIs, ai)
return ai
end

function EnemyAI.Update(dt: number)
for _, ai in ipairs(activeAIs) do
ai:step(dt)
end
end

if RunService:IsServer() then
RunService.Heartbeat:Connect(function(dt)
EnemyAI.Update(dt)
end)
end

return EnemyAI
