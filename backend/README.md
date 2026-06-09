# Backend — Copa Mundial FIFA 2026 (Rails 7.1 API)

API REST en Ruby on Rails (modo API) con SQLite que gestiona la Copa del
Mundo 2026: registro de selecciones, fase de grupos con tabla de posiciones
automática y fase de eliminación directa hasta el campeón.

## Requisitos

- Ruby 3.3.6 (gestionado con `rbenv`)
- Rails 7.1.x
- SQLite 3

## Instalación

```bash
cd backend
bundle install        # instala las gemas
rails db:create       # crea la base de datos SQLite
rails db:migrate      # crea las tablas
rails db:seed         # carga 12 grupos, 48 equipos y el fixture de grupos
```

## Ejecutar

```bash
rails server -p 3000
```

La API queda disponible en `http://localhost:3000/api/v1`.

## Estructura

```
app/
├── controllers/api/v1/   # Presentación: endpoints REST
├── models/               # Dominio: Tournament, Group, Team, Match
├── services/             # Aplicación: lógica de negocio (SOLID)
│   ├── standings_calculator.rb   # ordena la tabla de posiciones
│   ├── match_result_recorder.rb  # registra resultado y actualiza stats
│   ├── third_place_selector.rb   # 8 mejores terceros
│   └── knockout_advancer.rb      # arma y avanza el bracket
└── serializers/          # Forma de las respuestas JSON
```

## Endpoints principales

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/v1/tournament` | Estado, campeón, subcampeón, tercer lugar |
| PATCH | `/api/v1/tournament/advance` | Avanza de fase (grupos → eliminatoria → siguiente ronda) |
| GET | `/api/v1/groups` | Los 12 grupos con su tabla de posiciones |
| GET | `/api/v1/groups/:id` | Detalle de grupo + partidos |
| GET/POST/PUT/DELETE | `/api/v1/teams` | CRUD de selecciones |
| GET | `/api/v1/matches?phase=group` | Partidos (filtrable por fase/estado) |
| PATCH | `/api/v1/matches/:id/result` | Registra resultado (incluye prórroga/penales) |
| GET | `/api/v1/knockout/bracket` | Bracket eliminatorio completo |
| GET | `/api/v1/knockout/qualifiers` | Clasificados: top 2 por grupo + 8 mejores terceros |

## Documentación de arquitectura

Ver la carpeta [`../docs/`](../docs/): requerimientos, diseño de base de
datos, modelo de dominio, contratos de API y decisiones (ADRs).
