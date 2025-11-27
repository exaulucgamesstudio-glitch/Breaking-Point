--!strict
-- Breaking Point - DialogueSystem (client-major, server notified on completion)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DialogueSystem = {}

local flags: {[string]: any} = {}
local activeDialogue = nil

export type Choice = {text: string, next: string?, flag: {[string]: any}?}
export type Node = {speaker: string, line: string, choices: {Choice}?, endNode: boolean?}
export type Scene = {id: string, startNode: string, nodes: {[string]: Node}}

local function applyFlags(choice: Choice)
if choice.flag then
for key, value in pairs(choice.flag) do
flags[key] = value
end
end
end

function DialogueSystem:SetFlag(key: string, value: any)
flags[key] = value
end

function DialogueSystem:GetFlag(key: string)
return flags[key]
end

function DialogueSystem:BindPortraits(map: {[string]: string})
self.portraits = map
end

local function sendResult(sceneId: string, choice: Choice?)
if RunService:IsServer() then
-- server could directly handle; placeholder no-op
return
end
local remote = ReplicatedStorage:FindFirstChild("DialogueFinished")
if remote and remote:IsA("RemoteEvent") then
remote:FireServer({sceneId = sceneId, choice = choice})
end
end

local function renderNode(node: Node)
-- In Studio: this would populate DialogueUI elements. Here we return data.
return {
speaker = node.speaker,
portrait = DialogueSystem.portraits and DialogueSystem.portraits[node.speaker] or nil,
line = node.line,
choices = node.choices,
}
end

function DialogueSystem:Play(scene: Scene, onFinished: ((Choice?) -> ())?)
activeDialogue = scene.id
local currentId = scene.startNode
local finishedChoice: Choice? = nil

while currentId do
local node = scene.nodes[currentId]
if not node then break end
local uiData = renderNode(node)
-- UI rendering/pausing handled elsewhere. Here assume instant auto-choice for testing.
local chosen: Choice? = nil
if node.choices and #node.choices > 0 then
chosen = node.choices[1]
applyFlags(chosen)
currentId = chosen.next
else
currentId = nil
end
finishedChoice = chosen
if node.endNode then
currentId = nil
end
end

activeDialogue = nil
sendResult(scene.id, finishedChoice)
if onFinished then
onFinished(finishedChoice)
end
end

return DialogueSystem
