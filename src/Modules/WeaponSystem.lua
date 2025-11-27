--!strict
-- Breaking Point - WeaponSystem Module
-- Partagé client/serveur. Client gère VFX/UX, serveur valide les dégâts.

local RunService = game:GetService("RunService")

local WeaponSystem = {}
WeaponSystem.Weapons = {
Pistol = {damage = 20, fireRate = 0.35, clip = 12, reload = 1.6, spread = 2, recoil = 2, range = 150},
Rifle = {damage = 12, fireRate = 0.12, clip = 30, reload = 2.2, spread = 3.5, recoil = 3, range = 200},
}

local playerState: {[Player]: {lastShot: number, ammo: {[string]: {clip: number, reserve: number}}}} = {}

local function getPlayerState(player: Player)
local state = playerState[player]
if not state then
state = {
lastShot = 0,
ammo = {
Pistol = {clip = WeaponSystem.Weapons.Pistol.clip, reserve = WeaponSystem.Weapons.Pistol.clip * 3},
Rifle = {clip = WeaponSystem.Weapons.Rifle.clip, reserve = WeaponSystem.Weapons.Rifle.clip * 3},
},
}
playerState[player] = state
end
return state
end

function WeaponSystem:GetWeaponData(id: string)
return self.Weapons[id]
end

function WeaponSystem:CanFire(player: Player, weaponId: string): boolean
local weapon = self.Weapons[weaponId]
if not weapon then
return false
end
local state = getPlayerState(player)
local ammo = state.ammo[weaponId]
local now = os.clock()
return ammo.clip > 0 and (now - state.lastShot) >= weapon.fireRate
end

function WeaponSystem:ConsumeAmmo(player: Player, weaponId: string)
local state = getPlayerState(player)
local ammo = state.ammo[weaponId]
if ammo.clip > 0 then
ammo.clip -= 1
state.lastShot = os.clock()
end
end

function WeaponSystem:Reload(player: Player, weaponId: string)
local weapon = self.Weapons[weaponId]
local state = getPlayerState(player)
local ammo = state.ammo[weaponId]
local needed = weapon.clip - ammo.clip
local take = math.min(needed, ammo.reserve)
ammo.reserve -= take
ammo.clip += take
state.lastShot = os.clock() + weapon.reload -- lock fire until reload done
end

-- Client side: do a fast raycast and send minimal info for validation.
function WeaponSystem:ClientFire(player: Player, weaponId: string, origin: Vector3, direction: Vector3)
local weapon = self.Weapons[weaponId]
if not weapon or not self:CanFire(player, weaponId) then
return nil
end
self:ConsumeAmmo(player, weaponId)

local castDirection = direction.Unit
-- Simple cone spread
local randomYaw = math.rad(weapon.spread) * (math.random() - 0.5)
local randomPitch = math.rad(weapon.spread) * (math.random() - 0.5)
local spreadCF = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), randomYaw) * CFrame.fromAxisAngle(Vector3.new(1, 0, 0), randomPitch)
local finalDir = (spreadCF:VectorToWorldSpace(castDirection)).Unit

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.FilterDescendantsInstances = {player.Character}
local result = workspace:Raycast(origin, finalDir * weapon.range, raycastParams)

-- Client VFX: handled externally (muzzle flash, tracer, camera recoil)

return {
weaponId = weaponId,
origin = origin,
direction = finalDir,
position = result and result.Position or (origin + finalDir * weapon.range),
hit = result and result.Instance or nil,
distance = result and result.Distance or weapon.range,
}
end

-- Server-side validation: recompute raycast and cadence server-side
function WeaponSystem:ServerValidateShot(player: Player, shotData)
local weaponId = shotData and shotData.weaponId
local weapon = weaponId and self.Weapons[weaponId]
if not weapon then
return
end

-- Enforce cadence/ammo server-side to prevent client spam.
if not self:CanFire(player, weaponId) then
return
end
self:ConsumeAmmo(player, weaponId)

local character = player.Character
local head = character and character:FindFirstChild("Head")
local aimDirection = shotData.direction
if not (head and typeof(aimDirection) == "Vector3" and aimDirection.Magnitude > 0) then
return
end

local origin = head.Position
if shotData.origin and (shotData.origin - origin).Magnitude <= 8 then
origin = shotData.origin
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.FilterDescendantsInstances = {character}

local result = workspace:Raycast(origin, aimDirection.Unit * weapon.range, raycastParams)
if result and result.Instance then
local targetParent = result.Instance.Parent
local humanoid = targetParent and targetParent:FindFirstChildOfClass("Humanoid")
if humanoid then
humanoid:TakeDamage(weapon.damage)
end
end
end

function WeaponSystem:OnPlayerRemoving(player: Player)
playerState[player] = nil
end

if RunService:IsServer() then
game.Players.PlayerRemoving:Connect(function(player)
WeaponSystem:OnPlayerRemoving(player)
end)
end

return WeaponSystem
