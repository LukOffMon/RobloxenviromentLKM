# Client-Server Network Map

Relacionado: [[AntiExploit-protocol]], [[datastore-profile-schema]], [[monog-gdd]]

Todos los remotes viven en `ReplicatedStorage/LKMRemotes` y los crea `Main.server.luau` con `RemoteSignal.server` (middleware de 5 capas).

## Cliente → Servidor (solo intención)
| Remote | Argumentos | Rate limit | Lo que decide el servidor |
|---|---|---|---|
| `OpenBox` | modo: Coin, Coin5, Gem, Ticket, EpicTicket | 2/s | Coste, tirada, piedad |
| `SetEquipped` | uid (≤64), bool | 6/s | Máximo 3 y mínimo 1 equipados |
| `StartTraining` | uid (≤64) | 2/s | Compás con su reloj y espera entre sesiones |
| `TrainingTap` | — | 12/s | Juicio con su reloj, corrigiendo la latencia |
| `StartBattle` | — | 2/s | Equipo, rival, simulación y premio |
| `ClaimDaily` | — | 2 cada 2 s | Racha según el día del servidor |
| `RequestProfile` | — | 2 cada 5 s | Reenvía el perfil completo |

## Servidor → Cliente
| Remote | Contenido |
|---|---|
| `ProfileUpdated` | Vista completa: monedas, OGs, equipo, piedad, racha, pases, tasa de pensión, `PaidRandomAllowed` |
| `CurrencyUpdated` | Solo monedas (cada tick de pensión) |
| `GachaResult` | Lista de tiradas → cinemática |
| `TrainingStarted` / `TrainingJudged` / `TrainingResult` | Sesión de ritmo (`StartTime`, `ServerNow`), juicio de cada toque, XP final |
| `BattleResult` | Registro completo del combate y premios |
| `DailyResult` | Día de racha y recompensa |
| `Notify` | Aviso de texto (Error / Reward) |

Los cambios del perfil se agrupan cada 0,25 s en un solo mensaje.

## Atributos públicos del jugador
`EquippedOGs` («Id:shiny,...»), `VIP`, `QuantumAura`, `BattleTier`: cada cliente dibuja con ellos las mascotas y auras de todos.

## Módulos
- **Servidor:** `DataService`, `OGService`, `GachaService`, `MonetizationService`, `PensionService`, `TrainingService`, `BattleService`, `DailyService`, `WorldService`, `SanityChecker`.
- **Cliente:** `HUDController`, `GachaController`, `InventoryController`, `TrainingController`, `BattleController`, `DailyController`, `PetController`, `ChatTagController`.
- **Compartido:** `GameConfig`, `OGCatalog`, `Logic/*` (lógica pura con tests en `tests/run.luau`), `RemoteSignal`, `Janitor`, `Promise`.
