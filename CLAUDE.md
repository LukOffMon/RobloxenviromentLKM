# CLAUDE.md

**MonOG: Pocket Seniors**: juego de Roblox (gacha de abuelos, crianza, combates por turnos) gestionado con Rojo. GDD: `docs/gdd/monog-gdd.md`. Meta de negocio: 50 M Robux netos (ver `docs/gdd/monetization-and-growth.md`).
Reglas de estilo y arquitectura completas: `AI_SYSTEM_INSTRUCTIONS.md` (sección Repositorio 1).

## Comandos
- Verificar todo antes de commit: `./scripts/check.ps1` (formato, Selene, tipos estrictos con luau-lsp, tests Lune, build de Rojo). `-Fix` reformatea.
- Probar sin el mapa: `rojo build playtest.project.json -o MonOG-Playtest.rbxl` y abrirlo en Studio (suelo y piezas etiquetadas de prueba).
- La lógica de juego va en `src/shared/Logic` sin dependencias de Roblox, con su test en `tests/run.luau`.
- Sincronizar con Studio: `rojo serve` y pulsar Connect en el plugin de Rojo.
- Herramientas fijadas en `rokit.toml`; `rokit install` en una máquina nueva. Paquetes: declarar en `wally.toml`, luego `wally install`.

## Studio y Obsidian
- Servidor MCP `Roblox_Studio` (`.mcp.json`) controla el Studio abierto: mundo, assets, playtests, capturas. Ver el skill `roblox-studio-build`.
- `docs/` es la bóveda de Obsidian (wikilinks `[[nota]]`, plugins Git, Dataview y Kanban). Roadmap en `docs/roadmap.md` (formato Kanban: no romper los encabezados `##` ni el bloque `kanban:settings`). Specs nuevas en `docs/specs/` desde la plantilla, con frontmatter `estado`/`metrica`.

## Estructura
- `src/server` → ServerScriptService.Server · `src/client` → StarterPlayerScripts.Client · `src/shared` → ReplicatedStorage.Shared
- `*.server.luau` / `*.client.luau` son scripts; el resto son ModuleScripts.
- Servicios en `src/server/Services`, controladores en `src/client/Controllers`, configuración en `src/shared/Configurations/GameConfig.luau`.
- Los remotes se crean solo con `Shared.Network.RemoteSignal` (middleware de 5 capas). Nunca `Instance.new("RemoteEvent")` a mano.

## Reglas
- `--!strict` en todo archivo nuevo; `./scripts/check.ps1` debe quedar en verde.
- El servidor es la única autoridad: validar todo lo que llega del cliente, monedas/compras solo vía `DataService`.
- Compras: `ProcessReceipt` idempotente por `PurchaseId`, guardar antes de `PurchaseGranted`.
- Limpiar conexiones e instancias con `Janitor`.
- Cada remote, campo de DataStore o sistema nuevo se documenta en `docs/` (bóveda de Obsidian, enlaces `[[nota]]`) y se añade a `docs/Home.md`. Sistemas nuevos parten de `docs/templates/feature-spec.md`.
- Valores de diseño (precios, recompensas, límites) en `GameConfig`, no en el código.
