# AdjustableMirrors — Multiplayer Event Flow

Sequence diagram of how mirror data flows between client, server, and the
vehicle object in a listen-server multiplayer session.

```mermaid
sequenceDiagram
    autonumber
    participant C as Client (host)
    participant V as Vehicle (spec_adjustableMirrors)
    participant S as Server

    Note over C,S: === Vehicle load (onPostLoad) ===
    C->>V: onLoad()
    V-->>C: spec_enterable.mirrors count
    C->>V: onPostLoad()
    V->>V: create mirror entries (x1/x2/y1/y2 transform groups)
    V->>V: load savegame mirror positions<br/>(only if major version matches)

    Note over C,S: === Initial sync to server ===
    C->>S: onWriteStream()
    S->>V: store mirror count + x0/y0 per mirror

    Note over C,S: === Player enters vehicle ===
    C->>V: onEnterVehicle()
    V->>C: register action events (AM_AdjustMirrors)

    Note over C,S: === Player adjusts mirrors ===
    C->>V: onActionAdjustMirrors()
    V->>V: setMirror() → setRotation(x1, x2, y1, y2)
    V-->>C: mirrorsChanged = true

    Note over C,S: === Player leaves vehicle ===
    C->>V: onLeaveVehicle()
    alt mirrorsChanged
        C->>S: sendEvent(AMAdjustMirrorsEvent)
        S->>S: writeStream() — vehicle + mirror count + x0/y0 per mirror
        S->>S: readStream()
        S->>V: reconcile mirror count<br/>(extend if local < stream,<br/>send full update if local > stream)
        S->>V: setMirror() for each mirror<br/>(guard: mirror.x1 ~= nil)
        S-->>C: broadcastEvent()
        C->>C: readStream()
        C->>V: setMirror() for each mirror
    end
```

## Key behaviors

- **`onWriteStream`** runs when the vehicle is first synced to the server
  (after `onPostLoad`). It writes the mirror count and each mirror's `x0`/`y0`
  so the server has a baseline.
- **`AMAdjustMirrorsEvent`** is only sent on `onLeaveVehicle` if mirrors were
  actually changed. The host's own events go through the full
  `writeStream → readStream → broadcast` cycle on the server side.
- **`readStream` reconciliation** (in `AdjustMirrorsEvent.lua`):
  - Local has *fewer* mirrors than the stream → extend `spec.mirrors` with
    empty tables (dedicated server case), store `x0`/`y0` directly.
  - Local has *more* mirrors than the stream → send a full update event so
    the server gets the complete mirror data.
  - Counts match → apply `setMirror` for each mirror (guarded by
    `mirror.x1 ~= nil`).
- **Savegame version check** only resets mirror data on a *major* version
  change (e.g. `4.x` → `5.x`). Minor/patch bumps preserve the data.
