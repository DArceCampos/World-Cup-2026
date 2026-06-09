# API Contracts — FIFA World Cup 2026

**Base URL:** `/api/v1`  
**Formato:** JSON  
**Auth:** Ninguna (sistema de administrador único)

---

## Tournaments

### GET /api/v1/tournament
Retorna el estado actual del torneo (único torneo en el sistema).

```
Response 200:
  data:
    id: integer
    name: string
    status: string  — setup | group_stage | knockout | finished
    champion: { id, name } | null
    runner_up: { id, name } | null
    third_place: { id, name } | null
```

### PATCH /api/v1/tournament/advance
Avanza la fase del torneo (group_stage → knockout, o genera siguiente ronda eliminatoria).

```
Response 200:
  data:
    status: string  — nuevo estado del torneo
    message: string

Errores:
  422 UNPROCESSABLE — partidos pendientes sin resultado
```

---

## Groups

### GET /api/v1/groups
Lista los 12 grupos con sus equipos ordenados por posición.

```
Response 200:
  data: [
    {
      id: integer
      name: string           — "A" ... "L"
      standings: [
        {
          position: integer
          team: { id, name, points, goals_for, goals_against, goal_difference,
                  matches_played, wins, draws, losses }
        }
      ]
    }
  ]
```

### GET /api/v1/groups/:id
Detalle de un grupo incluyendo sus partidos.

```
Response 200:
  data:
    id: integer
    name: string
    standings: [...]        — igual que arriba
    matches: [
      { id, home_team, away_team, home_goals, away_goals, status }
    ]

Errores:
  404 NOT_FOUND — grupo no existe
```

### POST /api/v1/groups
Crea un nuevo grupo asociado al torneo activo.

```
Request:
  group:
    name: string       requerido  — una letra, ej. "M"
    tournament_id: integer  opcional (usa el torneo activo si se omite)

Response 201:
  data:
    id: integer
    name: string
    standings: []

Errores:
  422 VALIDATION_ERROR — nombre duplicado o parámetros inválidos
```

### PUT /PATCH /api/v1/groups/:id
Actualiza el nombre de un grupo.

```
Request:
  group:
    name: string

Response 200:
  data:
    id: integer
    name: string
    standings: [...]

Errores:
  404 NOT_FOUND       — grupo no existe
  422 VALIDATION_ERROR — nombre duplicado
```

### DELETE /api/v1/groups/:id
Elimina un grupo.

```
Response 204  — sin cuerpo

Errores:
  404 NOT_FOUND — grupo no existe
```

---

## Teams

### GET /api/v1/teams
Lista todos los equipos ordenados por nombre.

```
Response 200:
  data: [
    { id, name, group_id, group_name, points, goals_for, goals_against,
      goal_difference, matches_played, wins, draws, losses }
  ]
```

### GET /api/v1/teams/:id
Detalle de un equipo.

```
Response 200:
  data:
    id: integer
    name: string
    group_id: integer
    group_name: string
    points: integer
    goals_for: integer
    goals_against: integer
    goal_difference: integer
    matches_played: integer
    wins: integer
    draws: integer
    losses: integer

Errores:
  404 NOT_FOUND — equipo no existe
```

### POST /api/v1/teams
Registra un nuevo equipo.

```
Request:
  team:
    name: string       requerido
    group_id: integer  requerido

Response 201:
  data: { id, name, group_id, points: 0, ... }

Errores:
  422 VALIDATION_ERROR — nombre duplicado o grupo lleno (> 4 equipos)
```

### PUT /PATCH /api/v1/teams/:id
Actualiza nombre o grupo de un equipo.

```
Request:
  team:
    name: string       opcional
    group_id: integer  opcional

Response 200:
  data: { id, name, group_id, ... }

Errores:
  404 NOT_FOUND        — equipo no existe
  422 VALIDATION_ERROR — nombre duplicado
```

### DELETE /api/v1/teams/:id
Elimina un equipo. Solo permitido si no tiene partidos registrados.

```
Response 204  — sin cuerpo

Errores:
  404 NOT_FOUND — equipo no existe
  409 CONFLICT  — el equipo tiene partidos registrados
```

---

## Matches

### GET /api/v1/matches
Lista partidos. Acepta query params: `?phase=group`, `?phase=r16`, `?status=scheduled`.

```
Response 200:
  data: [
    {
      id: integer
      phase: string
      home_team: { id, name }
      away_team: { id, name }
      home_goals: integer | null
      away_goals: integer | null
      home_extra_goals: integer | null
      away_extra_goals: integer | null
      home_penalties: integer | null
      away_penalties: integer | null
      status: string       — scheduled | played
      winner: { id, name } | null
    }
  ]
```

### PATCH /api/v1/matches/:id/result
Registra el resultado de un partido.

```
Request:
  home_goals: integer  requerido
  away_goals: integer  requerido
  home_extra_goals: integer  opcional (solo eliminatoria, si hubo prórroga)
  away_extra_goals: integer  opcional
  home_penalties: integer  opcional (solo si hubo penales)
  away_penalties: integer  opcional

Response 200:
  data:
    match: { ...atributos actualizados }
    standings_updated: boolean   — true si era partido de grupo
    next_match_created: boolean  — true si era eliminatoria y generó siguiente partido

Errores:
  404 NOT_FOUND        — partido no existe
  422 VALIDATION_ERROR — resultado inválido (ej: penales sin prórroga en grupo)
  409 CONFLICT         — partido ya tiene resultado registrado
```

---

## Knockout

### GET /api/v1/knockout/bracket
Retorna el bracket completo de la fase eliminatoria.

```
Response 200:
  data:
    rounds: [
      {
        phase: string        — r32 | r16 | qf | sf | 3rd | final
                             — r32=dieciseisavos, r16=octavos, qf=cuartos, sf=semis
        matches: [
          {
            id: integer
            round_number: integer
            home_team: { id, name } | null
            away_team: { id, name } | null
            winner: { id, name } | null
            status: string
          }
        ]
      }
    ]
```

### GET /api/v1/knockout/qualifiers
Retorna los 32 clasificados a dieciseisavos (top 2 por grupo + 8 mejores terceros).

```
Response 200:
  data:
    from_groups: [{ team, group, position }]  — 24 equipos (pos 1 y 2)
    best_thirds: [{ team, group, points, goal_difference, goals_for }]  — 8 equipos
```

---

## Simulations

Genera resultados automáticos aleatorios. No requiere body. Cada llamada sobreescribe
los partidos pendientes del alcance indicado.

### POST /api/v1/simulations/match/:id
Simula un único partido (debe estar en estado `scheduled`).

```
Response 200:
  data:
    simulated_count: integer     — siempre 1
    simulated: [
      { id, home_team, away_team, home_goals, away_goals,
        home_extra_goals, away_extra_goals, home_penalties, away_penalties,
        status: "played", winner: { id, name } | null }
    ]

Errores:
  404 NOT_FOUND — partido no existe
```

### POST /api/v1/simulations/group/:id
Simula todos los partidos pendientes de un grupo.

```
Response 200:
  data:
    simulated_count: integer
    simulated: [ ...mismos atributos que arriba ]

Errores:
  404 NOT_FOUND — grupo no existe
```

### POST /api/v1/simulations/groups
Simula todos los partidos pendientes de todos los grupos.

```
Response 200:
  data:
    simulated_count: integer
    simulated: [ ...mismos atributos que arriba ]
```

### POST /api/v1/simulations/tournament
Simula el torneo completo (grupos + fase eliminatoria hasta el campeón).
Avanza las fases automáticamente hasta que el torneo quede en estado `finished`.

```
Response 200:
  data:
    status: string           — "finished"
    champion: { id, name }
    simulated_count: integer
    simulated: [ ...todos los partidos simulados ]
```
