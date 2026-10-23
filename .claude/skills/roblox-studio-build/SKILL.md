---
name: roblox-studio-build
description: Build, inspect or playtest the game inside the open Roblox Studio through the Roblox_Studio MCP server (maps, models, terrain, UI layout, lighting, assets, playtests, screenshots). Use whenever the task touches what is in Studio rather than only the Luau files in src/, or when asked to test the game, look at the place, or design a level, model or interface.
---

# Construir en Roblox Studio

El código vive en `src/` y Rojo lo sincroniza; el mundo (mapa, modelos, iluminación, UI hecha a mano) vive en el place de Studio. El servidor MCP `Roblox_Studio` (`.mcp.json`) da acceso al Studio abierto.

## Antes de empezar
1. `list_roblox_studios` y `get_studio_state`: confirma qué place está abierto. Si no responde, pide al usuario activar *Assistant → … → Manage MCP Servers → Enable Studio as MCP server*.
2. Si la tarea toca scripts, comprueba que `rojo serve` está conectado: los scripts bajo `ServerScriptService.Server`, `ReplicatedStorage.Shared` y `StarterPlayerScripts.Client` se editan en `src/`, **nunca** en Studio (Rojo los sobrescribe).

## Qué hacer con cada herramienta
- Explorar: `search_game_tree`, `inspect_instance`, `script_search`/`script_grep` para scripts que no gestiona Rojo.
- Construir mundo: `execute_luau` para crear/colocar Parts y modelos en `Workspace` por código (repetible y preciso), `search_asset` + `insert_asset` para la Creator Store, `generate_mesh` / `generate_material` / `generate_procedural_model` para assets nuevos (espera con `wait_job_finished`).
- Probar: `start_stop_play`, luego `get_console_output` y `screen_capture`; `character_navigation` y `user_keyboard_input` para recorrer el nivel como jugador. Detén siempre el play al terminar.

## Reglas de diseño
- Etiqueta con `CollectionService` lo que los sistemas usan (p. ej. `Coin`) en vez de depender de nombres.
- Agrupa cada zona en un `Model` con nombre de región de `docs/lore/world-building.md`; ancla (`Anchored = true`) lo estático.
- Presupuesto de rendimiento: preferir `MeshPart` reutilizadas, `CollisionFidelity` y `CastShadow` desactivados en decoración pequeña, `StreamingEnabled` activo.
- UI: escalar con `UDim2` en escala + `UIAspectRatioConstraint`; probar en móvil (más del 50 % de jugadores).
- Instancias que el juego necesita en runtime (plantillas de monedas, NPCs) van a `ServerStorage`/`ReplicatedStorage` y se documentan.

## Al terminar
- Captura de pantalla del resultado para el usuario.
- Recordar al usuario guardar/publicar el place (el mundo no está en git). Un modelo reutilizable se exporta a `assets/` como `.rbxm`.
- Documentar en `docs/` lo construido (zona, etiquetas, instancias nuevas) y moverlo en `docs/roadmap.md`.
