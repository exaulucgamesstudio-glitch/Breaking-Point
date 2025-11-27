# Breaking Point – Gameplay Systems & Mission Flow

## 1. Systèmes transversaux
### 1.1 DialogueSystem (client + serveur callbacks)
- **Data format**
```lua
local Scene = {
    id = "M2_BrianConfront",
    startNode = "n1",
    nodes = {
        n1 = { speaker = "Brian", line = "Tu as désobéi, Bernard.", choices = {
            { text = "J'ai fait ce qui était juste.", next = "n2", flag = {FabienTrust = true} },
            { text = "Ordres reçus, ordres suivis.", next = "n3" },
        }},
        n2 = { speaker = "Brian", line = "Nous en reparlerons.", endNode = true },
        n3 = { speaker = "Brian", line = "Bien. Pas de vagues.", endNode = true },
    }
}
return Scene
```
- **API (ModuleScript)** :
  - `DialogueSystem:Play(sceneTable, onFinished)` — construit UI, gèle contrôles, applique flags locaux, renvoie choix final au serveur via RemoteEvent.
  - `DialogueSystem:SetFlag(key, value)` / `GetFlag(key)`.
  - `DialogueSystem:BindPortraits(map)` pour lier avatars/portraits aux speakers.

### 1.2 QuestSystem (partagé)
- **Data format** (MissionConfig extrait)
```lua
Objectives = {
  main = {
    {id="INFILTRATE", text="Infiltre l'entrepôt sans alarme", autoComplete=false},
    {id="NEUTRALIZE", text="Neutralise les hommes de Marco", autoComplete=true, trigger="AllEnemiesDown"},
    {id="CAPTURE", text="Capture Marco", autoComplete=false}
  },
  optional = {
    {id="NO_ALARM", text="Aucune alarme déclenchée", failOnTrigger="AlarmRaised"}
  }
}
```
- **API** :
  - `QuestSystem:Start(missionConfig)`
  - `QuestSystem:CompleteObjective(id)` → déclenche événements/Remote pour UI.
  - `QuestSystem:FailObjective(id)`
  - `QuestSystem:GetState()` renvoie tables pour sauvegarde.

### 1.3 WeaponSystem (partagé)
- **Data**
```lua
Weapons = {
  Pistol = {damage=20, fireRate=0.35, clip=12, reload=1.6, spread=2, recoil=2, range=150},
  Rifle  = {damage=12, fireRate=0.12, clip=30, reload=2.2, spread=3.5, recoil=3, range=200},
}
```
- **API** :
  - `WeaponSystem:GetWeaponData(id)`
  - `WeaponSystem:CanFire(player)` (cadence / reload)
  - `WeaponSystem:ClientFire(player, weaponId, origin, direction)` → Raycast local + VFX.
  - `WeaponSystem:ServerValidateShot(player, shotData)` → recalcule le raycast serveur et applique les dégâts si le résultat correspond.

### 1.4 EnemyAI (serveur)
- **États** : `"Idle" | "Patrol" | "Alert" | "Combat"`
- **Composants** :
  - `patrolPath` (liste de waypoints, Vector3 ou Parts)
  - `vision` (angle, distance, raycast). Accroupi joueur réduit distance (ex: *0.65*).
  - `coverNodes` : liste de `Part` tagués `Cover` à proximité.
- **API** :
  - `EnemyAI.Spawn(enemyModel, config)`
  - `EnemyAI.Update(dt)` (appel depuis `EnemySpawner` heartbeat)
  - `EnemyAI.OnDamage(enemy, amount, attacker)` pour transférer en combat/alerte.

### 1.5 StealthSystem (client + serveur signal)
- **Jauge suspicion** : valeur 0–100, incrémentée quand raycast vision ennemie touche le joueur. 
- **Accroupi** : diminue vitesse + coefficient détection.
- **Fail** : `StealthSystem:TriggerAlarm(source)` → RemoteEvent serveur, peut échouer la mission ou passer en combat.

### 1.6 MiniGames (client)
- **Enquête** : liste d’indices interactifs; `MiniGames.StartInvestigation(zoneId, requiredClues)`, UI coche les indices. 
- **Désamorçage** : timer, fils à couper dans ordre défini; `MiniGames.StartDefuse(config)` renvoie bool réussite. 
- **Preuves (M10)** : UI documents, `MiniGames.StartEvidence(selectionOrder)`.

### 1.7 Cinematics & QTE
- Caméra scriptée : `Cinematics:PlayTrack(trackTable)` où chaque keyframe = position, orientation, durée. 
- QTE : prompt UI avec touche (ou bouton mobile), délai court; résultat renvoyé au serveur pour poursuivre cinématique ou infliger dégâts.

### 1.8 DataFlags (progression)
- Stocke `missionsCompleted` (table), `narrativeFlags` (key/boolean). 
- Serveur valide progression quand `QuestSystem` signale succès.

## 2. Mission Flow (résumé complet)
1. **M1 Villa** : intro, suivre Marco (StealthSystem), conversations (DialogueSystem). 
2. **M2 Entrepôt** : vertical slice combat/furtivité/dialogue (base systems). 
3. **M3 QG/Café** : mini-jeu enquête sur vidéos, dialogues Derek. 
4. **M4 Planque** : infiltration + photo documents, cinématique Royal Blood/Roblox. 
5. **M5 Hôtel de Ville** : timer exploration, explosion centrale (swap map), parkour sortie. 
6. **M6 Gare** : désamorçage + boss double. 
7. **M7 Aéroport/FLUX** : explosion cinématique, enquête décombres. 
8. **M8 Archives** : furtivité pure, bonus zéro détection. 
9. **M9 Convoi** : rail shooter + combat sol, recrutement alliés. 
10. **M10 Verdict** : mini-jeu preuves, confrontation finale, épilogue parc.

## 3. Hub & Progression
- Hub propose mission list verrouillée par progression DataFlags. 
- Téléport vers place mission. Après succès, retour hub avec Remote signal pour sauvegarder. 
- Tutoriel mouvement/tir dans hub optionnel.

## 4. Mobile & Performance Rappels
- UI boutons pour tir, visée, accroupi, choix dialogue, QTE. 
- Limiter VFX et Humanoids, IA sur rails, collisions simplifiées. 
- Précharger assets critiques; priorité client pour VFX.

