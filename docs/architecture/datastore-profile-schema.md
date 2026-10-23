# DataStore Profile Schema

Relacionado: [[economy-systems]], [[client-server-network-map]]

- **DataStore:** `MonOG_PlayerData_v1` · **Llave:** `Player_<UserId>`

```json
{
  "SchemaVersion": 1,
  "LockJobId": "<JobId del servidor dueño o null>",
  "LockTime": 1730000000,
  "Data": {
    "PensionCoins": 300, "GigaGems": 0, "Tickets": 1, "EpicTickets": 0,
    "OGs": { "<uid>": { "Id": "DonChente", "Level": 1, "XP": 0, "Shiny": false, "Obtained": 1730000000 } },
    "Equipped": ["<uid>"],
    "Pity": 0, "TotalRolls": 0,
    "BattleTier": 1, "BattlesWon": 0,
    "DailyStreak": 0, "LastDailyDay": -1,
    "LastSeen": 0, "XpBoostUntil": 0,
    "ProcessedReceipts": { "<PurchaseId>": 1730000000 },
    "StarterPackBought": false
  }
}
```

## Session locking
1. Al entrar, `UpdateAsync` toma el bloqueo si no existe, es de este servidor o tiene más de 30 min.
2. Si otro servidor lo tiene, se expulsa al jugador con un mensaje para reintentar.
3. Autoguardado cada 120 s manteniendo el bloqueo; al salir o en `BindToClose` se guarda y se libera.
4. Un guardado nunca sobrescribe un registro bloqueado por otro `JobId`.

## Compras
`ProcessedReceipts` guarda los últimos 100 `PurchaseId`: cada compra se concede una sola vez y se guarda antes de responder `PurchaseGranted`.

## Studio
En un place sin publicar no hay DataStore: el perfil vive en memoria y el HUD avisa «Modo prueba». Para probar el guardado real: publicar el place y activar *Game Settings → Security → Enable Studio Access to API Services*.

## Migraciones
Aditivas: los campos nuevos de `GameConfig.Data.Template` se rellenan al cargar (`reconcile`). Cambios destructivos requieren subir `SchemaVersion`.
