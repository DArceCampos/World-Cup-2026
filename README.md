# World Cup 2026

API REST para la gestión de la Copa Mundial FIFA 2026. Administra grupos, equipos, partidos, tabla de posiciones, fase eliminatoria y simulación automática de resultados.

**Stack:** Ruby on Rails 7.1 (API) · SQLite 3 · React 18 + Vite

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
    ├── api-contracts.md
    └── World-Cup-2026.postman_collection.json
```

---

## Correr el proyecto

```bash
cd backend
rails server -p 3000
```

La API queda disponible en `http://localhost:3000/api/v1`.

---

## Documentación

Ver [`docs/api-contracts.md`](docs/api-contracts.md) para ver todos los endpoints.  
Colección Postman lista para importar en [`docs/World-Cup-2026.postman_collection.json`](docs/World-Cup-2026.postman_collection.json).
