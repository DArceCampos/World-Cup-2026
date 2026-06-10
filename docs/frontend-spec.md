# Frontend Spec — Copa Mundial FIFA 2026

## Contexto

Aplicación web para gestionar la Copa Mundial FIFA 2026. El torneo tiene 48 selecciones distribuidas en 12 grupos (A–L) de 4 equipos cada uno. Hay una fase de grupos y una fase de eliminación directa (dieciseisavos → octavos → cuartos → semifinales → final + tercer lugar).

## Estilo visual general

- Tema oscuro (fondo negro/gris muy oscuro)
- Colores principales: dorado/amarillo para destacados, blanco para texto, gris para elementos secundarios
- Tipografía moderna y deportiva
- Cards con bordes sutiles y sombras
- Responsive (desktop y mobile)

---

## Páginas

### 1. Dashboard (página principal `/`)

**Propósito:** Vista general del estado del torneo.

**Elementos visuales:**
- Header grande con el logo o título "Copa Mundial FIFA 2026" y los países sede (México, EE. UU., Canadá)
- Tarjeta de estado del torneo: muestra en qué fase está actualmente (fase de grupos / eliminación directa / finalizado)
- Si el torneo ha terminado: sección destacada con campeón (1°), subcampeón (2°) y tercer lugar (3°), cada uno con su nombre del país en grande y un trofeo o medalla visual
- Accesos rápidos: botones o cards que llevan a Grupos, Partidos y Eliminatorias
- Contador o resumen: cuántos partidos jugados vs pendientes

---

### 2. Grupos (`/groups`)

**Propósito:** Ver todos los grupos con sus tablas de posiciones.

**Elementos visuales:**
- Título de página "Fase de Grupos"
- Grid de 12 cards, una por grupo (A hasta L)
- Cada card de grupo muestra:
  - Título "Grupo A", "Grupo B", etc. destacado
  - Tabla de posiciones con columnas: Pos | Equipo | PJ | G | E | P | GF | GC | DG | Pts
  - Los equipos ordenados por posición (1° al 4°)
  - El 1° y 2° lugar visualmente destacados (color verde o borde dorado) porque clasifican directamente
  - El 3° lugar con destacado diferente (color amarillo/naranja) porque puede clasificar como mejor tercero
  - El 4° lugar sin destacado (eliminado)
  - Botón o link "Ver partidos" que lleva al detalle del grupo

---

### 3. Detalle de grupo (`/groups/:id`)

**Propósito:** Ver la tabla de posiciones y los partidos de un grupo específico.

**Elementos visuales:**
- Título "Grupo A" (o el que corresponda)
- Tabla de posiciones igual a la descrita arriba pero más grande y detallada
- Sección "Partidos" con lista de los 6 partidos del grupo
- Cada partido muestra:
  - Equipo local vs Equipo visitante
  - Si ya tiene resultado: marcador (ej. 2 - 1) en grande y centrado, estado "Jugado"
  - Si no tiene resultado: marcador vacío o guiones (- vs -), estado "Pendiente", y un formulario inline o botón para registrar el resultado
- Formulario de registro de resultado: dos campos numéricos (goles local / goles visitante) y botón "Guardar resultado"

---

### 4. Partidos (`/matches`)

**Propósito:** Ver todos los partidos de fase de grupos con opción de filtrar y registrar resultados.

**Elementos visuales:**
- Título "Partidos — Fase de Grupos"
- Filtros por grupo (tabs o dropdown): Todos | Grupo A | Grupo B | ... | Grupo L
- Filtros por estado: Todos | Pendientes | Jugados
- Lista de partidos en cards:
  - Cada card muestra: nombre del grupo, equipo local vs equipo visitante, resultado o "Pendiente"
  - Si está pendiente: botón "Registrar resultado" que abre un formulario (modal o inline)
  - Si está jugado: marcador en grande, indicación del ganador o "Empate"
- Formulario de resultado: campos para goles local y goles visitante, botón confirmar

---

### 5. Eliminatorias (`/knockout`)

**Propósito:** Ver el bracket completo de la fase eliminatoria.

**Elementos visuales:**
- Título "Fase Eliminatoria"
- Si la fase de grupos no ha terminado: mensaje indicando que primero deben completarse todos los partidos de grupos
- Si la fase eliminatoria está activa: bracket visual horizontal con todas las rondas
  - Columnas de izquierda a derecha: Dieciseisavos (32) → Octavos (16) → Cuartos (8) → Semifinales (4) → Final (1)
  - Cada partido del bracket muestra: equipo local vs equipo visitante, resultado si ya se jugó, ganador destacado
  - Los equipos que avanzan tienen una línea o flecha visual que los conecta al siguiente partido
  - El campeón aparece al final del bracket destacado con trofeo
- Sección separada para el "Partido por el Tercer Lugar"
- Si un partido de eliminatoria tiene tiempo extra o penales, mostrar el marcador con nota "(p.e.)" o "(T.E.)"

---

## Componentes reutilizables

### Navbar
- Fija en la parte superior
- Logo o nombre del torneo a la izquierda
- Links: Dashboard | Grupos | Partidos | Eliminatorias
- Indicador visual de la página activa

### Card de partido
- Dos equipos con sus nombres centrados
- Marcador en el centro (grande si está jugado, guiones si está pendiente)
- Badge de estado: "Jugado" (verde) / "Pendiente" (gris)
- Nombre del grupo o ronda en la parte superior de la card

### Tabla de posiciones
- Encabezado con columnas: Pos | Equipo | PJ | G | E | P | GF | GC | DG | Pts
- Filas alternadas para legibilidad
- Color de fondo diferente para las posiciones que clasifican

### Badge de clasificación
- Verde: clasifica directo (1° y 2° de grupo)
- Amarillo: posible mejor tercero (3° de grupo)
- Rojo/gris: eliminado (4° de grupo)
