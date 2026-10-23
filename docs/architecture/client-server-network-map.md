# Client-Server Network Map

Relacionado: [[AntiExploit-protocol]], [[datastore-profile-schema]]

Todos los remotes viven en `ReplicatedStorage/LKMRemotes` y los crea el servidor mediante `RemoteSignal.server`.

| Remote | Dirección | Argumentos | Rate limit | Sanity |
|---|---|---|---|---|
| `ProfileUpdated` | Servidor → Cliente | `{ Coins, Level, Experience }` | — | — |
| `CollectCoin` | Cliente → Servidor | `coin: BasePart` (descendiente de Workspace) | 5 / s | etiqueta `Coin` + distancia ≤ 16 studs |

## Módulos
- Servidor: `Main.server.luau` → `DataService`, `SanityChecker`.
- Cliente: `Main.client.luau` → `UIController` → `StatLabel`.
- Compartido: `RemoteSignal`, `Janitor`, `Promise`, `GameConfig`.
