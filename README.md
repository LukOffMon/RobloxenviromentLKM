# RobloxenviromentLKM

Workspace profesional de ingeniería de software para desarrollo modular en Roblox Studio.

## Ecosistema Integrado
- **Control de Versiones & Build:** Administrado vía [Rojo](https://rojo.space/).
- **Base de Conocimiento:** Bóveda de [Obsidian](https://obsidian.md/) completamente sincronizada en `/docs`.
- **Patrón de Arquitectura:** Servidor autoritativo con arquitectura basada en servicios y controladores.

## Estructura
- `/docs`: Game Design Documents (GDD), arquitectura de red, schemas de datos y Lore.
- `/src/server`: Servicios del servidor, base de datos y validaciones de seguridad.
- `/src/client`: Controladores de UI, efectos de cliente y cámara.
- `/src/shared`: Módulos compartidos, utilidades y declaraciones de red.

## Preparar una máquina nueva
1. Instala [Rokit](https://github.com/rojo-rbx/rokit) y ejecuta `rokit install` en la raíz: instala Rojo, Selene, StyLua, Wally, luau-lsp y Lune en las versiones de `rokit.toml`.
2. `rojo plugin install` instala el plugin de Rojo en Roblox Studio.
3. Abre la carpeta en VS Code y acepta las extensiones recomendadas (`.vscode/extensions.json`).
4. En Obsidian: *Open folder as vault* → `docs/`. Empieza por `Home.md`.

## Uso diario
```bash
rojo serve default.project.json
```
En Studio, pestaña Plugins → Rojo → Connect. Antes de cada commit:
```powershell
./scripts/check.ps1        # formato, lint, tipos estrictos y build (-Fix para reformatear)
```
El mismo pipeline corre en GitHub Actions y publica el `.rbxl` como artefacto.

## Flujo de una petición de red
Cliente → `RemoteSignal` → (1) Auth → (2) Rate Limit → (3) Validación de tipos → (4) Sanity/Distancia → (5) Ejecución.
Ver [docs/architecture/AntiExploit-protocol.md](docs/architecture/AntiExploit-protocol.md).
