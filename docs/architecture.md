# Breaking Point – Architecture & Production Plan

## 1. Vision & Place Layout
- **Hub (Place 1):** Menu, progression load, mission select, safe tutorial sandbox.
- **Missions (Places 2–11):** 10 linéaires, petites cartes dédiées, chargées depuis le hub via `TeleportService`.
- **Swap de map (destruction):** Deux versions de map pré-modélisées par mission concernée (intacte/détruite), swap côté serveur pendant cinématique (ex: M5 centrale, M7 hôtel FLUX, M9 camion). Utiliser `CollectionService` pour grouper les deux états et activer/désactiver via `Model.Parent`.

## 2. Explorer Tree Standard (par mission)
```
ReplicatedStorage
  Modules
    MissionConfig
    DialogueSystem
    QuestSystem
    WeaponSystem
    EnemyAI
    StealthSystem
    Cinematics
    MiniGames
    DataFlags
ServerScriptService
  MissionServer
  EnemySpawner
  MissionEvents
StarterPlayer
  StarterPlayerScripts
    PlayerController
    CameraController
    UIController
    InputHandler
StarterGui
  MainUI (objectifs, dialogues, interactions)
  CrosshairUI
  TimerUI
  DialogueUI
  MiniGameUI
Workspace
  Map
  Waypoints
  CoverNodes
  NPCs
  Triggers (zones événementielles)
  SpawnLocations
```

## 3. Modules & Responsabilités
- **MissionConfig (ModuleScript)** : tables `Objectives`, `Spawns`, `Triggers`, `Cinematics`. Utilisé par `MissionServer`.
- **DialogueSystem (ModuleScript, partagé)** : lance dialogues, gère choix, callbacks, flags de réputation.
- **QuestSystem (ModuleScript, partagé)** : enregistre objectifs, met à jour UI, déclenche événements serveur.
- **WeaponSystem (ModuleScript, partagé)** : données armes + logique client (tir raycast) + validation serveur dégâts.
- **EnemyAI (ModuleScript, serveur)** : état IA (Idle/Patrol/Alert/Combat), waypoints, cône de vision, prise de couverture.
- **StealthSystem (ModuleScript, partagé)** : jauge suspicion, accroupi, réduction distance détection, échec furtif.
- **Cinematics (ModuleScript, client)** : caméras scriptées, lock contrôles, QTE simples.
- **MiniGames (ModuleScript, client)** : registre de mini-jeux (enquête, désamorçage, preuves) et signale résultat au serveur.
- **DataFlags (ModuleScript, serveur)** : wrapper DataStore (progression missions, flags narratifs simples).

## 4. Core Gameplay Loop (Vertical Slice = Mission 2 "Contre-Ordre")
1. Brief UI (objectifs initiaux). 
2. Phase furtive : cônes de vision, jauge suspicion, objectif d'infiltration.
3. Combat TPS : tir client (raycast) + validation serveur. Ennemis sur rails, couvertures.
4. Capture de Marco (cinématique + DialogueSystem choix). 
5. Mission success/fail sauvegardé (DataFlags), retour hub.

## 5. Gameplay Systems (Résumé technique)
- **Contrôleur TPS** : mouvements (marche/course/saut/accroupi), caméra 3e personne (offset, collision), couverture via `CoverNodes` tagués (réduction hitbox + précision ennemie). 
- **Tir & Armes** : `WeaponSystem:GetWeaponData(id)`, `ClientFire`, `ServerValidateShot` (raycast serveur). Recul caméra léger, dispersion cône.
- **IA** : Waypoints (Parts dans `Workspace/Waypoints`). Vision = angle/distance + raycast. États simples, pas de pathfinding lourd. 
- **Furtivité** : jauge montée par détection raycast; accroupi réduit multiplicateur. Échec → alerte ou fail selon mission. 
- **Dialogue** : data table par scène, choix 2–4 options, callbacks + flags (ex: `FabienTrust`). 
- **Objectifs** : `QuestSystem:RegisterObjective(id, data)`, `CompleteObjective(id)`, événements. 
- **Mini-jeux** : UI client, résultat renvoyé au serveur via `RemoteEvent`. 
- **Cinematics** : caméra scriptée via `TweenService`, contrôle input off, QTE via prompts.
- **Progression** : `DataFlags` sauvegarde missions terminées (DataStore), flags scénarios clés.

## 6. Missions (résumé gameplay)
- **M1 Villa (furtivité sociale)** : suivre Marco, jauge suspicion, écouter 3 conversations (secondary). 
- **M2 Entrepôt (vertical slice)** : infiltre → combat → capture Marco → choix dialogue Brian. 
- **M3 QG/Café (narratif)** : briefing, interroger Derek, mini-jeu enquête vidéo. 
- **M4 Planque (mix)** : combat ext, infiltration int, photo plans bombes, fuite. 
- **M5 Hôtel de Ville** : timer, explosion centrale (swap map), parkour sortie. 
- **M6 Gare** : fouille rames, mini-jeu désamorçage, boss Royal Blood & Roblox. 
- **M7 Aéroport/FLUX** : fausse piste, explosion hôtel (swap), enquête décombres. 
- **M8 Archives RBI** : pure furtivité, zéro alarme objectif bonus. 
- **M9 Convoi (rail shooter)** : tir sur rails + combat sol, recrutement Samantha & Mark. 
- **M10 Verdict** : mini-jeu sélection preuves, cinématique finale, épilogue parc libre. 

## 7. Optimisation & Mobile
- Limiter Humanoids (≤12 actifs). PNJ décor = `AnimationController` + mesh ancrés. 
- Collisions simplifiées (Box/Hull). 
- Effets côté client; serveur ne fait que logique. 
- Pré-charger assets essentiels via `ContentProvider`. 

## 8. Production Roadmap
1. **Vertical Slice M2** : PlayerController, WeaponSystem, EnemyAI, Stealth, Dialogue, Quest, UI de base. 
2. **Acte 1 (M1–M6)** : ajouter mini-jeu enquête + désamorçage; swap map M5; boss M6. 
3. **Acte 2 (M7–M10)** : rail shooter M9, preuve UI M10, infiltration totale M8, cinématiques renforcées. 
4. **Polish** : VFX/SFX, optimisation mobile, localisation, QA.
