# Cobertura de pruebas de modelo

Estas son las **39 pruebas de modelo**, organizadas por el modelo dueño de cada regla. Complementan las pruebas de sistema y controlador.

Cada caso usa pocos registros con nombres descriptivos. El objetivo es comprobar reglas, no conservar una copia del evento ni reducir el número de pruebas a cualquier costo.

## Activity

- **select activities by kind**: Los scopes de actos, operaciones y acciones devuelven únicamente su tipo; actos y operaciones conservan el orden por ID definido en sus scopes.
- **find an operation by source ID**: Resolver la operación por `source_id`, aunque difiera de su ID interno y coincida con el ID de un acto.
- **validate required attributes**: Exigir título, día y `source_id`, y aceptar únicamente los tipos y fases definidos.
- **keep source IDs unique within each kind**: Rechazar dos actividades del mismo tipo con igual `source_id`, permitiendo reutilizarlo entre tipos distintos.
- **require a preparation for actions**: Una acción necesita un grupo existente y una posición entera positiva.
- **keep action positions unique within a preparation**: Rechazar posiciones repetidas dentro del grupo, permitiendo la misma posición en otro grupo.
- **restrict grouping to preparation actions**: Los actos y operaciones no pueden tener `preparation_id` ni `position`.

## Activity information

Estas reglas pertenecen a los lectores de `Activity` y están en `test/models/activity_information_test.rb`.

- **read act information from production details**: Obtener responsables, notas, pendientes y campos técnicos del `ProductionDetail` asociado al acto.
- **handle missing production details**: Devolver información ausente cuando el acto no tiene un detalle de producción.
- **read operation and action information from JSON**: Obtener su información del JSON propio, ignorando detalles de producción cuyos IDs coincidan con el ID de la actividad o su referencia original.
- **separate technical and general information**: La información técnica contiene solo sus campos; responsables, notas, preguntas y pendientes permanecen fuera de ella, en sus lectores generales o en `details`.
- **reflect production changes in fresh instances**: Una nueva instancia del acto refleja las modificaciones o la eliminación de su detalle de producción.

## Preparation

- **validate required attributes**: Exigir título y día, y una fase válida.
- **allow only act references**: Aceptar una lista vacía o IDs enteros positivos de actos existentes; rechazar listas mal formadas, IDs inexistentes, operaciones y acciones.
- **order actions by position**: Devolver las acciones propias según `position`, aunque sus IDs estén en otro orden, sin incluir acciones de otro grupo.
- **use the first action start time**: Tomar el inicio de la primera acción por posición, no el menor horario ni la primera acción con un horario disponible.
- **fall back to the preparation start time**: Usar el horario guardado del grupo cuando no tiene acciones o la primera acción no tiene inicio, sin tomar el horario de una acción posterior.
- **collect unique action commissions**: Agrupar las comisiones asignadas a sus acciones sin duplicados; no inferir comisiones a partir de preguntas o instrucciones del JSON.
- **prevent deletion with actions**: Rechazar la eliminación del grupo mientras tenga acciones y conservar tanto el grupo como sus acciones.

## Schedule

- **list available days**: Incluir los días presentes en actos, operaciones y preparaciones, sin duplicados.
- **list available commissions**: Incluir las comisiones de todos los tipos de fila, también las derivadas de acciones agrupadas, sin duplicados y ordenadas.
- **select a default day**: Cuando no se elige un día, usar el día del primer acto, aunque existan operaciones de otro día.
- **ignore unknown filters**: Un día desconocido usa el predeterminado; una comisión o tipo desconocido no se aplica como filtro.
- **combine day, type and commission filters**: Devolver únicamente las filas que coinciden con los tres criterios, con unos pocos registros que permitan distinguir cada condición.
- **keep a commission with no results**: Conservar una comisión válida aunque no tenga filas para el día seleccionado, devolviendo una lista vacía.
- **order by phase**: Respetar el orden de fases explícitas, aunque los horarios, títulos o tipos de actividad sugieran otro orden.
- **order by start time**: Ordenar las filas de una misma fase por su hora de inicio conocida.
- **fall back to end time for ordering**: Usar el final para ordenar cuando el inicio esté ausente o sea un texto como «Por confirmar», sin modificar el inicio guardado.
- **place unknown times last within their phase**: Sin inicio ni final conocidos, colocar la fila al final de su fase, no al final de todo el programa.
- **exclude preparation action rows**: Mostrar el grupo de preparación una sola vez, sin convertir sus acciones en filas independientes.

## Question

- **require a body**: Rechazar preguntas sin texto.
- **normalize blank answers**: Convertir respuestas vacías o compuestas de espacios en `nil`.
- **resolve only act references**: Obtener el acto desde `act_id`, devolver `nil` si no hay referencia y rechazar referencias a actividades que no sean actos al resolverla.

## ProductionDetail

- **require an act reference**: Rechazar detalles sin `act_id`.
- **allow one detail per act**: Rechazar un segundo detalle para el mismo acto y permitir detalles de actos distintos.

## Topic

- **keep questions when deleting a topic**: Eliminar el tema sin eliminar sus preguntas; dejarlas sin tema, conservando su texto y respuesta.

## Document

- **require an act reference**: Rechazar documentos sin `act_id`, aunque tengan un archivo.
- **require a file**: Rechazar documentos sin archivo, aunque tengan `act_id`.
- **label the file format**: Mostrar la extensión en mayúsculas y usar «ARCHIVO» cuando el nombre no tenga extensión.

## Fixtures

Todas las capas comparten las fixtures convencionales de Rails:

- `test/fixtures/activities.yml`: 8 actividades representativas.
- `test/fixtures/preparations.yml`: 2 grupos de preparación.
- `test/fixtures/files/`: archivos de ejemplo para adjuntos.

Se accede por nombres, por ejemplo `activities(:opening_act)`, y cada prueba crea o modifica registros cuando necesita una condición especial. Se eliminaron el conjunto grande, `test/scenario_fixtures/`, `EventFixtures`, `ApplicationRequestTestCase` y la configuración especial de caché.

## Fuera de esta cobertura de modelo

- Cantidades totales, rangos de IDs, participantes y horarios del evento real.
- Copiar a modelos los recorridos de formularios, navegación y carga de archivos que ya cubre sistema.
- Respuestas HTTP, redirecciones y parámetros permitidos, que corresponden a controladores.
- Probar getters o asociaciones convencionales sin una regla adicional.
- Demostrar que Ruby congela objetos `Data` o que Active Record permite buscar un ID numérico enviado como texto.
- Agregar reglas nuevas, como exigir un nombre no vacío en `Topic` o validar que cualquier `act_id` pertenezca a un acto, donde el modelo todavía no lo hace. Eso sería un cambio de aplicación separado.

Puedes dar instrucciones por contexto y nombre, por ejemplo: «Schedule / order by phase: dejarla».
