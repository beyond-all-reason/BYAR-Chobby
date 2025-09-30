# Enable Custom Map Selection in Chobby (Dev Lobby)

This document captures the exact code changes and steps used to enable selecting any locally installed custom map in multiplayer from Chobby (BYAR-Chobby) when running the “Dev Lobby”. Use this to reproduce the patch in another working copy.

Audience: Developers running Chobby from a local BYAR-Chobby.sdd (“Dev Lobby”) and wanting to pick non-curated (“Unofficial”) maps.

---

## What This Patch Does

- Adds a configuration flag `allowUnofficialMaps` (default: true).
- Allows selecting any installed map in multiplayer when the flag is ON.
- Shows “Unofficial” maps in the multiplayer map list when the flag is ON.

Notes:
- Every player still needs the same `.sd7` map locally. If the map isn’t in BAR repositories, pr-downloader won’t fetch it for other clients automatically.
- Server/bot enforcement of curated pools is separate. This patch only affects the lobby UI selection and listing.

---

## Files Changed

1) Lua
- BYAR-Chobby/LuaMenu/widgets/chobby/components/configuration.lua
- BYAR-Chobby/LuaMenu/widgets/gui_maplist_panel.lua

---

## Exact Code Changes

### 1) Add configuration flag (persisted)

File: `LuaMenu/widgets/chobby/components/configuration.lua`

a) In `Configuration:init()` add after `self.onlyShowFeaturedMaps = true`:

```lua
self.onlyShowFeaturedMaps = true
self.allowUnofficialMaps = true
self.simpleAiList = true
```

b) In `Configuration:GetConfigData()` add this line among the returned table entries:

```lua
allowUnofficialMaps = self.allowUnofficialMaps,
```

This persists the flag in the user’s configuration state.

---

### 2) Allow selecting and listing non-pool maps in multiplayer

File: `LuaMenu/widgets/gui_maplist_panel.lua`

a) In `CreateMapEntry(...)` click handler, relax guard to allow unofficial maps when flag is enabled:

Before:
```lua
if (lobby.name == "singleplayer") or (mapData and mapData.IsInPool) then
    lobby:SelectMap(mapName)
    CloseFunc()
end
```

After:
```lua
if Configuration.allowUnofficialMaps or (lobby.name == "singleplayer") or (mapData and mapData.IsInPool) then
    lobby:SelectMap(mapName)
    CloseFunc()
end
```

b) In `AddTheNextBatchOfMaps()` and follow-up blocks where items are added, broaden filter that previously excluded “Unofficial” in multiplayer:

Change all occurrences of:

```lua
if lobby.name == "singleplayer" or certification ~= "Unofficial" then
    ...
end
```

to:

```lua
if lobby.name == "singleplayer" or certification ~= "Unofficial" or Configuration.allowUnofficialMaps then
    ...
end
```

There are three such locations:
- When iterating `featuredMapList`
- When appending locally installed archives (`VFS.GetAllArchives()`)
- When appending remaining `Configuration.gameConfig.mapDetails`

---

## How to Run Chobby Dev Lobby

1) Install and run the BAR Launcher at least once
- Download: https://github.com/beyond-all-reason/BYAR-Chobby/releases
- Launch the lobby once so it downloads the engine and base content.

2) Create the `games` directory in the state/data dir
- Windows: `%APPDATA%\BeyondAllReason\data\games`
  - Example: `C:\Users\YOUR_USER\AppData\Roaming\BeyondAllReason\data\games`
- Linux: `~/.local/state/BeyondAllReason/data/games`

3) Put your BYAR-Chobby source under `BYAR-Chobby.sdd`
- Option A (copy): Copy your working repo (containing `LuaMenu/…`) into:
  - Windows: `%APPDATA%\BeyondAllReason\data\games\BYAR-Chobby.sdd`
  - Linux: `~/.local/state/BeyondAllReason/data/games/BYAR-Chobby.sdd`
- Option B (clone):
  ```bash
  git clone https://github.com/beyond-all-reason/BYAR-Chobby.git BYAR-Chobby.sdd
  ```
  Ensure `.../BYAR-Chobby.sdd/LuaMenu/configs/gameConfig` exists.

4) Launch “Dev Lobby”
- Open the BAR Launcher.
- Select “Dev Lobby” in the top-right dropdown.
- Start/Play.
- Chobby now runs from your local `BYAR-Chobby.sdd` (with the patch).

5) Optional: Developer UI
- Create an empty `devmode.txt` file in the `data` dir:
  - Windows: `%APPDATA%\BeyondAllReason\data\devmode.txt`
  - Linux: `~/.local/state/BeyondAllReason/data/devmode.txt`
- Restart Chobby; “Settings/Developer” tab appears.

---

## Installing and Selecting a Custom Map

1) Place your `.sd7` map in the maps folder:
- Windows: `%APPDATA%\BeyondAllReason\data\maps\MyCustomMap.sd7`
- Linux: `~/.local/state/BeyondAllReason/data/maps/MyCustomMap.sd7`

2) Restart Chobby (or reopen the map list).

3) In Multiplayer, open the map list and search for your map.
- With `allowUnofficialMaps = true`, you can select it even if marked “Unofficial”.

Reminder: Others must also install the same `.sd7` to join your game.

---

## Troubleshooting

- Map not showing up:
  - Verify `.sd7` is valid (contains proper `mapinfo` and `springName`).
  - Confirm correct path: `%APPDATA%\BeyondAllReason\data\maps` (Windows) or `~/.local/state/BeyondAllReason/data/maps` (Linux).
  - Restart the lobby.

- Can’t select in multiplayer:
  - Ensure the code changes above are in effect and you’re running “Dev Lobby” from your `BYAR-Chobby.sdd`.
  - `allowUnofficialMaps` defaults to `true` in this patch.

- Others can’t join:
  - They need the same `.sd7` locally; share the file.

---

## Optional Future Improvement

Add a Settings UI toggle:
- Expose `allowUnofficialMaps` on a “Lobby Settings” screen to turn this behavior on/off without code changes.

---
