# Breaking Point

Documentation et modules Roblox pour le jeu narratif/action **Breaking Point**.

## Contenu
- `docs/architecture.md` : architecture globale, places, roadmap de production.
- `docs/systems.md` : spécifications gameplay (dialogue, quêtes, IA, furtivité, mini-jeux...).
- `src/Modules/` : modules LuaU prêts à importer dans Roblox Studio (WeaponSystem, EnemyAI, DialogueSystem, QuestSystem).

## Démarrage rapide dans Roblox Studio
1. Créez le Hub (Place 1) puis une place par mission (2–11). 
2. Copiez les ModuleScripts de `src/Modules` dans `ReplicatedStorage/Modules` (ou équivalent). 
3. Configurez les `RemoteEvent` : `QuestUpdate`, `MissionSuccess`, `DialogueFinished`. 
4. Placez les `Waypoints` et `CoverNodes` dans `Workspace` pour alimenter `EnemyAI`. 
5. Ajoutez une `DialogueUI`, `MainUI`, `CrosshairUI`, `MiniGameUI` et branchez-les aux modules.
6. Utilisez `docs/architecture.md` et `docs/systems.md` comme guide pour l’ordre de production.
