# Architecture — FIFA World Cup 2026

## Patrón: Monolito Modular (Rails API + React SPA)

**Stack:**
- Backend: Ruby on Rails 7.1 (modo API)
- Frontend: React 18 + Vite
- Base de datos: SQLite 3
- Comunicación: REST/JSON

---

## Diagrama C4 — Nivel 1: Contexto

```
                    ┌─────────────────────┐
                    │      Navegador      │
                    │  (Administrador)    │
                    └──────────┬──────────┘
                               │ HTTP/JSON
                               ▼
              ┌────────────────────────────────┐
              │   World Cup 2026 System        │
              │                                │
              │  ┌──────────┐  ┌───────────┐  │
              │  │  React   │  │ Rails API │  │
              │  │   SPA    │◀▶│           │  │
              │  └──────────┘  └─────┬─────┘  │
              │                      │        │
              │               ┌──────▼──────┐ │
              │               │   SQLite    │ │
              │               └─────────────┘ │
              └────────────────────────────────┘
```

---

## Diagrama C4 — Nivel 2: Contenedores

```
┌─────────────────────────────────────────────────────────┐
│                    Sistema FIFA 2026                    │
│                                                         │
│  ┌──────────────────────┐   ┌──────────────────────┐   │
│  │     React SPA        │   │    Rails 7.1 API      │   │
│  │   (Vite, port 5173)  │   │    (port 3000)        │   │
│  │                      │   │                       │   │
│  │  Pages:              │   │  Controllers          │   │
│  │  - Dashboard         │   │  Services             │   │
│  │  - Groups            │   │  Models               │   │
│  │  - Standings         │   │  Serializers          │   │
│  │  - Knockout          │◀──│                       │   │
│  │  - Results           │   │         │             │   │
│  └──────────────────────┘   └─────────┼─────────────┘   │
│                                       │                  │
│                             ┌─────────▼─────────────┐   │
│                             │       SQLite           │   │
│                             │   db/development.sqlite│   │
│                             └───────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## Diagrama C4 — Nivel 3: Componentes Rails

```
┌───────────────────────────────────────────────────────┐
│                   Rails API App                       │
│                                                       │
│  ┌─────────────────────────────────────────────────┐  │
│  │               Controllers (Presentation)        │  │
│  │  TeamsController  GroupsController              │  │
│  │  MatchesController  TournamentController        │  │
│  └────────────────────┬────────────────────────────┘  │
│                       │ delegates to                  │
│  ┌────────────────────▼────────────────────────────┐  │
│  │               Services (Application)            │  │
│  │  MatchResultRecorder   KnockoutAdvancer         │  │
│  │  MatchSimulator                                 │  │
│  └────────────────────┬────────────────────────────┘  │
│                       │ uses                          │
│  ┌────────────────────▼────────────────────────────┐  │
│  │               Models (Domain)                   │  │
│  │  Tournament  Group  Team  Match                 │  │
│  │  (ActiveRecord + lógica de dominio:             │  │
│  │   standings, ranking_key, best_third_places)    │  │
│  └────────────────────┬────────────────────────────┘  │
│                       │                               │
│  ┌────────────────────▼────────────────────────────┐  │
│  │           Infrastructure (ActiveRecord)         │  │
│  │               SQLite via ActiveRecord           │  │
│  └─────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────┘
```

---

## Estructura de Carpetas

```
World-Cup-2026/
├── backend/                          # Rails 7.1 API
│   ├── app/
│   │   ├── controllers/
│   │   │   └── api/
│   │   │       └── v1/
│   │   │           ├── tournaments_controller.rb
│   │   │           ├── groups_controller.rb
│   │   │           ├── teams_controller.rb
│   │   │           ├── matches_controller.rb
│   │   │           ├── knockout_controller.rb     # bracket y clasificados
│   │   │           └── simulations_controller.rb  # simulación de resultados
│   │   ├── models/
│   │   │   ├── tournament.rb               # best_third_places (mejores terceros)
│   │   │   ├── group.rb                    # standings (tabla ordenada)
│   │   │   ├── team.rb                     # ranking_key (desempate FIFA)
│   │   │   └── match.rb
│   │   ├── services/
│   │   │   ├── match_result_recorder.rb    # SRP: registra resultado y actualiza stats
│   │   │   ├── knockout_advancer.rb        # SRP: avanza ganadores al bracket
│   │   │   └── match_simulator.rb          # SRP: simula partido/grupo/torneo
│   │   └── serializers/
│   │       ├── team_serializer.rb
│   │       ├── group_serializer.rb
│   │       └── match_serializer.rb
│   ├── config/
│   │   └── routes.rb
│   ├── db/
│   │   ├── migrate/
│   │   │   ├── 001_create_tournaments.rb
│   │   │   ├── 002_create_groups.rb
│   │   │   ├── 003_create_teams.rb
│   │   │   └── 004_create_matches.rb
│   │   └── seeds.rb                      # carga los 48 equipos y grupos
│   └── Gemfile
│
├── frontend/                         # React + Vite
│   ├── src/
│   │   ├── api/
│   │   │   └── client.js             # fetch wrapper con base URL
│   │   ├── components/
│   │   │   ├── GroupTable.jsx        # tabla de posiciones de un grupo
│   │   │   ├── MatchCard.jsx         # tarjeta de partido
│   │   │   ├── KnockoutBracket.jsx   # bracket eliminatorio visual
│   │   │   └── TeamBadge.jsx
│   │   ├── pages/
│   │   │   ├── Dashboard.jsx         # resumen del torneo
│   │   │   ├── GroupsPage.jsx        # lista de grupos con standings
│   │   │   ├── GroupDetailPage.jsx   # detalle de un grupo
│   │   │   ├── MatchesPage.jsx       # registro de resultados
│   │   │   └── KnockoutPage.jsx      # bracket y resultados eliminatorios
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── package.json
│   └── vite.config.js
│
└── docs/                             # artefactos de arquitectura
    ├── requirements.md
    ├── architecture.md
    ├── database-design.md
    ├── domain-model.md
    ├── api-contracts.md
    └── decisions.md
```

---

## Principios SOLID Aplicados

| Principio | Aplicación concreta |
|-----------|---------------------|
| **S** — Single Responsibility | Cada Service tiene una sola razón de cambio. `MatchResultRecorder` solo registra resultados y actualiza stats; `KnockoutAdvancer` solo arma el bracket; `MatchSimulator` solo genera resultados. El ordenamiento (tabla y mejores terceros) vive como lógica de dominio en los modelos (`Group#standings`, `Team#ranking_key`, `Tournament#best_third_places`). |
| **O** — Open/Closed | `Match#winner` es extensible: la lógica de desempate (normal → prórroga → penales) puede añadirse sin modificar el contrato del método. |
| **L** — Liskov Substitution | Los modelos `GroupMatch` y `KnockoutMatch` comparten la interfaz de `Match`; cualquier servicio que opere sobre un `Match` funciona sin saber el tipo. |
| **I** — Interface Segregation | Los serializers exponen solo los atributos necesarios por contexto (ej: `GroupSerializer` no incluye bracket data). |
| **D** — Dependency Inversion | Los controllers dependen de servicios (abstracciones), no de ActiveRecord directamente. `MatchesController` llama `MatchResultRecorder.call(match, params)`. |
