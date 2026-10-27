# The Silent Keep: Moonlit Oath — Background Assets — Codex Ready

SOURCE_BACKGROUND_ATLAS_ORIGINAL.png is the untouched atlas.

Folders:
- parallax: separate scenic background panels
- tiles: gothic ground/platform/architecture source strip
- props: transparent-friendly props source
- effects: environmental VFX source
- foreground: transparent-friendly depth overlay source
- special_tiles: water/special tile source
- weather: fog/moon/weather lighting source

Godot recommendations:
- nearest-neighbor texture filtering
- use parallax panels as separate layers
- do not automatically merge neighboring assets
- preserve PNG transparency for props/effects
- use the source strips as the visual authority when making individual tile/prop files
