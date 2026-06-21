# 3seventeen Hub

Script modules served via GitHub raw URLs. Loader fetches from here.

## Supported Games

| Game | File |
|------|------|
| Murder Mystery 2 | `mm2.lua` |
| Flee the Facility | `ftf.lua` |
| Tower of Hell | `toh.lua` |
| Underground War | `uw.lua` |
| Guess My Game | `gmg.lua` |
| Glass Bridge | `glass_bridge.lua` |

## Structure

```
loader.lua            -- game router (detects PlaceId, fetches module)
premium_loader.lua    -- sets tier=paid, uploaded to Luarmor
dist/
  mm2.lua
  ftf.lua
  toh.lua
  uw.lua
  gmg.lua
  glass_bridge.lua
```

## Usage

**Free tier:**
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/123workforme/3seventeenhub/main/dist/loader.lua"))()
```

**Premium tier (via Luarmor):**
```lua
loadstring(game:HttpGet("LUARMOR_LOADER_URL"))()
```

Premium users go through Luarmor's key gate (HWID locked) before the loader executes.
