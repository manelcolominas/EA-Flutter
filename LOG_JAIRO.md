# LOG DE IMPLEMENTACION - FASE 2 Y AJUSTE DE ARQUITECTURA

## 1) Objetivo funcional alcanzado

1. Usuario entra en detalle de organization.
2. App hace GET de tasks de esa organization.
3. Usuario pulsa "Create task".
4. App abre formulario, valida datos y hace POST.
5. Al volver, la pantalla de detalle lanza de nuevo el GET y refresca lista.

## 2) Ficheros creados y carpeta

### Creado

- `lib/models/task.dart`

Que aporta:

- Modelo `Task` independiente (ya no depende de que organization traiga tasks embebidas).
- Campos: `id`, `titulo`, `fechaStart`, `fechaend`.
- `Task.fromJson(...)` para parsear respuestas de API.

## 3) Ficheros actualizados y carpeta

### Actualizado en servicios

- `lib/services/organization_service.dart`

Cambios clave:

- Metodo `fetchTasksByOrganization(String organizationId)`:
	- GET `/organizations/{organizationId}/tasks`
	- Retorna `Future<List<Task>>`.
- Metodo `createTaskByOrganization(...)`:
	- POST `/organizations/{organizationId}/tasks`
	- Body JSON enviado:
		- `titulo`
		- `fechaStart` (ISO UTC)
		- `fechaend` (ISO UTC)
		- `users` (lista de IDs)

### Actualizado en pantallas

- `lib/screens/organization_detail_screen.dart`

Cambios clave:

- Eliminada lista mock local de tasks.
- Integrado `FutureBuilder<List<Task>>` para cargar tasks reales.
- Estados de UI gestionados:
	- Cargando: `CircularProgressIndicator`.
	- Sin datos: "Aun no hay tasks en esta organization".
	- Con datos: `ListView.builder` + `Card` para cada tarea.
- Navegacion a Create task ahora pasa:
	- `organizationId`
	- `users`
- Al volver de formulario:
	- Si se creo tarea (`Navigator.pop(..., true)`), se recarga GET.

- `lib/screens/create_task_screen.dart`

Cambios clave:

- Sigue siendo `StatefulWidget` con `Form` y `GlobalKey<FormState>`.
- Validaciones locales:
	- Titulo obligatorio.
	- Fecha Start obligatoria.
	- Fecha end obligatoria.
	- Fecha end >= fecha Start.
- Uso de `TextEditingController` para titulo e inputs de fecha.
- Integracion con backend:
	- En submit valida formulario.
	- Llama a `createTaskByOrganization(...)`.
	- Si OK: `Navigator.pop(context, true)`.
	- Si error: `SnackBar` informativo.

## 4) Elementos clave de Flutter que han ayudado

### Gestion de UI reactiva

- `StatefulWidget`: necesario para manejar estado local (fechas, loading, future de tasks).
- `setState`: usado para refrescar UI tras cambios de estado.

### Formularios y validacion

- `Form` + `GlobalKey<FormState>`: base para validar de forma centralizada.
- `TextFormField` con `validator`: reglas de negocio locales inmediatas.
- `TextEditingController`: facilita lectura de valores y futura integracion con otras capas.

### Fechas

- `showDatePicker`: selector nativo y UX consistente en plataformas Flutter.
- Normalizacion de fecha para el payload del backend y envio en formato ISO UTC.

### Asincronia y datos remotos

- `Future<List<Task>>`: tipado fuerte para operaciones de red.
- `FutureBuilder`: simplifica renderizado declarativo de estados loading/error/data.
- `http` + `json.decode/json.encode`: cliente HTTP y serializacion del body/response.

### Navegacion y retorno de resultado

- `Navigator.push` para abrir formulario.
- `Navigator.pop(context, true)` para devolver exito.
- Patron de resultado booleano para decidir si refrescar en pantalla anterior.

## 5) Beneficio arquitectonico obtenido

La app ahora respeta mejor separacion de responsabilidades:

- Modelos en `lib/models`.
- Llamadas HTTP y transformacion de datos en `lib/services`.
- Renderizado y experiencia de usuario en `lib/screens`.

Esto facilita que futuras fases (estado global, cache, tests, backend real en produccion) se integren sin rehacer la UI.
