--!strict
-- Breaking Point - QuestSystem (partagé)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local QuestSystem = {}
QuestSystem.__index = QuestSystem

export type Objective = {id: string, text: string, autoComplete: boolean?, trigger: string?, failOnTrigger: string?}
export type MissionConfig = {main: {Objective}, optional: {Objective}?}

local state = {
activeObjectives = {},
optional = {},
completed = {},
failed = {},
}

local function broadcast(eventName: string, data)
local remote = ReplicatedStorage:FindFirstChild(eventName)
if remote and remote:IsA("RemoteEvent") then
if RunService:IsServer() then
remote:FireAllClients(data)
else
remote:FireServer(data)
end
end
end

function QuestSystem:Start(missionConfig: MissionConfig)
state.activeObjectives = {}
state.optional = {}
state.completed = {}
state.failed = {}
for _, obj in ipairs(missionConfig.main) do
state.activeObjectives[obj.id] = obj
end
if missionConfig.optional then
for _, obj in ipairs(missionConfig.optional) do
state.optional[obj.id] = obj
end
end
broadcast("QuestUpdate", self:GetState())
end

function QuestSystem:CompleteObjective(id: string)
if state.activeObjectives[id] then
state.completed[id] = state.activeObjectives[id]
state.activeObjectives[id] = nil
broadcast("QuestUpdate", self:GetState())
if next(state.activeObjectives) == nil then
broadcast("MissionSuccess", {completed = state.completed, optional = state.optional})
end
end
end

function QuestSystem:FailObjective(id: string)
if state.activeObjectives[id] or state.optional[id] then
state.failed[id] = state.activeObjectives[id] or state.optional[id]
state.activeObjectives[id] = nil
state.optional[id] = nil
broadcast("QuestUpdate", self:GetState())
end
end

function QuestSystem:GetState()
return {
active = state.activeObjectives,
optional = state.optional,
completed = state.completed,
failed = state.failed,
}
end

return QuestSystem
