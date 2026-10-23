# DataStore Profile Schema

Relacionado: [[economy-systems]], [[client-server-network-map]]

- **DataStore:** `PlayerData_v1` · **Llave:** `Player_<UserId>`

```json
{
  "SchemaVersion": 1,
  "LockJobId": "<JobId del servidor dueño o null>",
  "LockTime": 1730000000,
  "Data": { "Coins": 0, "Level": 1, "Experience": 0, "Inventory": {} }
}
```

## Session locking
1. Al entrar, `UpdateAsync` toma el bloqueo si no existe, es de este servidor o tiene más de 30 min (`SessionLockTimeoutSeconds`).
2. Si otro servidor lo tiene, se expulsa al jugador con un mensaje para reintentar.
3. Autoguardado cada 120 s manteniendo el bloqueo; al salir o en `BindToClose` se guarda y se libera.
4. Un guardado nunca sobrescribe un registro bloqueado por otro `JobId`.

## Migraciones
Aditivas: los campos nuevos de `GameConfig.Data.Template` se rellenan al cargar (`reconcile`). Cambios destructivos requieren subir `SchemaVersion`.
