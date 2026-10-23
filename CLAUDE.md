# CLAUDE.md

Juego de Roblox gestionado con Rojo. Meta de negocio: 50 M Robux netos (ver `docs/gdd/monetization-and-growth.md`).
Reglas de estilo y arquitectura completas: `AI_SYSTEM_INSTRUCTIONS.md` (sección Repositorio 1).

## Comandos
- Verificar todo antes de commit: `./scripts/check.ps1` (formato, Selene, tipos estrictos con luau-lsp, build de Rojo). `-Fix` reformatea.
- Sincronizar con Studio: `rojo serve` y pulsar Connect en el plugin de Rojo.
- Herramientas fijadas en `rokit.toml`; `rokit install` en una máquina nueva. Paquetes: declarar en `wally.toml`, luego `wally install`.

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
