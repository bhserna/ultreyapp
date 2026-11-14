Mi mamá quiere...

1. Poder ver la información que está en el nuevo spreadsheet
2. Leer la información de ahí ese spreadsheet es el bueno por ahora
3. Pero quiere seguir manteniendo las "operaciones antes del evento"
4. Quiere poder agregar a esas operaciones archivos
5. Quiere agregar a esas operaciones...
  - Montaje de escenografía
  - Montar instrumentos, creo que esta ya esta
  - Montaje de acuerdo al layout
6. Quiere poder después accesar esto sin internet

Preguntas iniciales

- Cómo podemos estructurar la información para lograr eso?
- Cómo podemos ir subiendo de manera segura?
- Cómo podemos fácilmente deshacer cambios si subimos algo que no nos gusta?

Consideraciones

- No sabemos cual es el spreadshhet definitivio y creo que va a seguir cambiando
- No me interesa editar el contenido offline
- Las "operaciones antes del evento", tal vez pueden ser como "Actividades previas" y son las cosas que van a estar sucediendo antes de que empiece
- Van a poder modificar columnas pero sería raro
- También sería raro que agreguen filas, pero es posible
- El contenido de cada cuadro sí va a cambiar constantemente
- El contenido sin conexión me gustaría que se pudiera ver tanto en una computadora como en un celular... pero no se si es posible

Ideas a rebotar tomando en cuenta lo que comentaste

- Estoy pensando que podemos tener un record "SpreadsheetCopy" que podamos actualizar con un botón
- De ese copy nosotros construir value objects que nos permitan mostrar el programa de forma similar a como lo hacemos ahorita
- Que los documentos estén asociados de forma "dinámica", es decir vamos a asociar de acuerdo a un id que va a aparecer en el spreadsheet, si por algún motivo lo cambian, se mostrará una sección de documentos que ya no están asociados con actividades.
- En esta nueva sección, las preguntas las dejaremos fuera por ahora
- Empezaremos creando una nueva pestaña "Programa actualizado"


Decisiones

- Nueva pestaña “Programa actualizado”.
- Copias versionadas del spreadsheet.
- Lectura mediante value objects.
- Botón para descargar, y activar una nueva copia.
- Al descargar se debe siempre guardar y ya al momento de presentarse, mostrar un error si por algo no podemos mostrar la información, buscando ser muy laxos en la estructura
- Documentos vinculados por ID estable y sección de documentos sin actividad.
- Posibilidad de activar una copias anteriores facilemente, aunque por default es la más nueva
- Sin preguntas y sin modificar todavía el programa actual.
- Quiero que sea facil imprimir el programa
- Primera version offline es un zip
- Segunda versión offline vemos lo del serviceworker
- Podemos tener una forma de activar versión para todos
- Cada descarga correcta crea una copia nueva; la última se muestra por defecto.
- Se puede navegar por copias anteriores, incluso si la última no puede interpretarse.
- Por ahora no hay un paso de aprobación o activación.
- Exploraremos llevar las actividades previas al mismo spreadsheet, posiblemente en una pestaña separada.
- Los archivos permanecen en la aplicación y se vinculan mediante identificadores estables.
- El programa actual no se modifica durante esta primera entrega.

Stories

- [x] poder guardar el spreadhsheet
- [x] poder descargar de nuevo
- [x] mostrar los actos en lista
- [x] detalle de un acto
- [ ] preparaciones en la lista
- [ ] filtrar entre preparaciones y detalle
- [ ] detalle de las preparaciones
- [ ] actividades previas
- [ ] filtrar también actividades previas
- [ ] detalle de actividad previa
- [ ] ver y adjuntar documentos
- [ ] imprimir detalle
- [ ] descargar pdf
- [ ] descargar zip
- [ ] guardar versión en navegador
- [ ] navegar versiones
