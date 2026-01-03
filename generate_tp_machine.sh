#!/usr/bin/env bash
set -euo pipefail

NAME="tp_machine"
VERSION="1.0.0"

echo "▶ Generating $NAME v$VERSION"

# cleanup
rm -rf "$NAME" "$NAME-$VERSION.zip"

# directories
mkdir -p \
  "$NAME/data/minecraft/tags/functions" \
  "$NAME/data/tp_machine/functions/selector"

# ------------------------
# pack.mcmeta
# ------------------------
cat > "$NAME/pack.mcmeta" <<'EOF'
{
  "pack": {
    "pack_format": 18,
    "description": "TP Machine – server-side, rotation-safe, multiplayer datapack"
  }
}
EOF

# ------------------------
# load.json
# ------------------------
cat > "$NAME/data/minecraft/tags/functions/load.json" <<'EOF'
{
  "values": ["tp_machine:selector/init"]
}
EOF

# ------------------------
# tick.json
# ------------------------
cat > "$NAME/data/minecraft/tags/functions/tick.json" <<'EOF'
{
  "values": ["tp_machine:selector/tick_global"]
}
EOF

# ------------------------
# init.mcfunction
# ------------------------
cat > "$NAME/data/tp_machine/functions/selector/init.mcfunction" <<'EOF'
# Initialize configuration
data modify storage tp_machine:selector config set value {
  destinations: [
    {name:"Base",color:"blue",cost:1,tp:[-1056,64,1167]},
    {name:"Palude",color:"green",cost:2,tp:[-3646,60,-2721]},
    {name:"Dest 3",color:"orange",cost:3,tp:[100,64,100]}
  ],
  max_index: 2
}
data modify storage tp_machine:selector players set value {}
EOF

# ------------------------
# place.mcfunction
# ------------------------
cat > "$NAME/data/tp_machine/functions/selector/place.mcfunction" <<'EOF'
# summon anchor
summon armor_stand ~ ~ ~ {Invisible:1b,Marker:1b,Tags:["selector"]}

# support block
setblock ~ ~ ~ oak_planks replace

# sign
setblock ~ ~1 ~ oak_sign replace

# buttons
setblock ~-1 ~1 ~ dark_oak_button replace
setblock ~1 ~1 ~ dark_oak_button replace
EOF

# ------------------------
# tick_global.mcfunction
# ------------------------
cat > "$NAME/data/tp_machine/functions/selector/tick_global.mcfunction" <<'EOF'
execute as @e[tag=selector] at @s run function tp_machine:selector/tick
EOF

# ------------------------
# tick.mcfunction
# ------------------------
cat > "$NAME/data/tp_machine/functions/selector/tick.mcfunction" <<'EOF'
# initialize player
execute unless data storage tp_machine:selector players."$(player_uuid)" run data modify storage tp_machine:selector players."$(player_uuid)" set value {index:0}

# left button
execute if block ^-1 ^1 ^ minecraft:dark_oak_button[powered=true] run data modify storage tp_machine:selector players."$(player_uuid)".index set value $(data get storage tp_machine:selector players."$(player_uuid)".index - 1)
setblock ^-1 ^1 ^ minecraft:dark_oak_button[powered=false] replace

# right button
execute if block ^1 ^1 ^ minecraft:dark_oak_button[powered=true] run data modify storage tp_machine:selector players."$(player_uuid)".index set value $(data get storage tp_machine:selector players."$(player_uuid)".index + 1)
setblock ^1 ^1 ^ minecraft:dark_oak_button[powered=false] replace

# wrap index
execute if data storage tp_machine:selector players."$(player_uuid)".index[-1] run data modify storage tp_machine:selector players."$(player_uuid)".index set value 2
execute if data storage tp_machine:selector players."$(player_uuid)".index[3] run data modify storage tp_machine:selector players."$(player_uuid)".index set value 0

# update sign
execute store result storage tp_machine:selector tmp int 1 run data get storage tp_machine:selector players."$(player_uuid)".index
execute store result storage tp_machine:selector name string 1 run data get storage tp_machine:selector config.destinations[$(tmp)].name
execute store result storage tp_machine:selector color string 1 run data get storage tp_machine:selector config.destinations[$(tmp)].color
execute store result storage tp_machine:selector cost int 1 run data get storage tp_machine:selector config.destinations[$(tmp)].cost

data modify block ~ ~1 ~ front_text.messages[0] set value '{"text":"$(name)","color":"$(color)"}'
data modify block ~ ~1 ~ front_text.messages[1] set value '{"text":"Costo: $(cost) stack","color":"gold"}'

# pay + tp
execute store result score @p cost_check run clear @p minecraft:copper_ingot 0
execute if score @p cost_check >= storage tp_machine:selector cost run function tp_machine:selector/tp
EOF

# ------------------------
# tp.mcfunction
# ------------------------
cat > "$NAME/data/tp_machine/functions/selector/tp.mcfunction" <<'EOF'
execute store result storage tp_machine:selector i int 1 run data get storage tp_machine:selector players."$(player_uuid)".index

execute store result entity @p Pos[0] double 1 run data get storage tp_machine:selector config.destinations[$(i)].tp[0]
execute store result entity @p Pos[1] double 1 run data get storage tp_machine:selector config.destinations[$(i)].tp[1]
execute store result entity @p Pos[2] double 1 run data get storage tp_machine:selector config.destinations[$(i)].tp[2]

execute store result storage tp_machine:selector cost int 1 run data get storage tp_machine:selector config.destinations[$(i)].cost
clear @p minecraft:copper_ingot $(cost)
EOF

# ------------------------
# README.md
# ------------------------
cat > "$NAME/README.md" <<'EOF'
# TP Machine Datapack

Server-side teleport selector datapack.
Rotation-safe, multiplayer-ready, no client mods required.

Minecraft Java 1.20.x
EOF

# ------------------------
# LICENSE.md
# ------------------------
cat > "$NAME/LICENSE.md" <<'EOF'
MIT License

Copyright (c) 2026 Erindel
EOF

# ------------------------
# CHANGELOG.md
# ------------------------
cat > "$NAME/CHANGELOG.md" <<'EOF'
## 1.0.0
- Initial release
EOF

# ------------------------
# BUILD ZIP
# ------------------------
zip -r "$NAME-$VERSION.zip" "$NAME" > /dev/null

echo "✅ Done"
echo "📦 Created $NAME-$VERSION.zip"
