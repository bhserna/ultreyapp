# Cobertura de pruebas de sistema

Estas son las **32 pruebas de sistema**, organizadas por contexto y comportamiento. Cada contexto corresponde a un archivo en `test/system/`.

Las pruebas usan un conjunto independiente de **8 actividades y 2 preparaciones** en `test/scenario_fixtures/`, compartido con las pruebas de controlador. Preguntas, temas, documentos y detalles de producción se crean solo en los escenarios que los necesitan. No dependen de los textos ni de las cantidades de actividades del evento real.

## Schedule

- **show acts**: Mostrar los actos del día con número, título y horario.
- **show preparations**: Mostrar título, inicio y comisiones de las preparaciones del día, sin filas separadas para sus acciones.
- **show operations**: Mostrar las operaciones del día con su categoría, diferenciadas de los actos.
- **go to an activity**: Abrir el detalle correcto al elegir un acto o una operación del programa.
- **go to a preparation**: Abrir el detalle de una preparación desde su fila del programa.
- **go to a day**: Cambiar de día y mostrar únicamente sus actividades y preparaciones.
- **filter by activity type**: Seleccionar actos, preparaciones u operaciones y volver a mostrar todos los tipos.
- **filter by commission**: Mostrar únicamente las filas de la comisión seleccionada y recuperar todas al quitar el filtro.
- **filter from a commission link**: Pulsar una comisión de la tabla y aplicar ese filtro.
- **keep filters when changing days**: Conservar el tipo y la comisión al cambiar de día; mostrar un mensaje si no hay resultados.
- **use filters on a narrow screen**: Poder seleccionar y aplicar los filtros desde una pantalla móvil, sin controles fuera de la pantalla.

## Acts

- **show act details**: Mostrar el título, horario, comisiones y datos de producción guardados del acto seleccionado.
- **create an act question**: Crear una pregunta desde el acto y verla asociada a él, sin mezclarla con preguntas generales ni de otros actos.
- **filter from a commission link**: Pulsar una comisión del detalle y volver al programa con el día y la comisión correspondientes.

## Operations

- **show operation details**: Mostrar el horario, responsables, notas y datos técnicos propios de la operación, sin mostrar preguntas ni producción de un acto con el mismo número de referencia original.

## Preparations

- **show actions**: Mostrar las acciones de la preparación en su orden guardado, con sus horarios y detalles.
- **go to a related act**: Abrir un acto relacionado desde la preparación y poder volver al programa.

## Questions

Los flujos compartidos de edición y respuestas se prueban aquí, desde preguntas generales, sin repetirlos completos para cada contexto.

- **show general questions**: Mostrar las preguntas generales sin tema, excluyendo las de actos y las de temas específicos.
- **filter by topic**: Seleccionar un tema y mostrar solo sus preguntas; volver a las preguntas sin tema.
- **create a question without a topic**: Crear una pregunta en «Sin tema» y verla en esa lista.
- **create a question in a topic**: Crear una pregunta en el tema seleccionado y comprobar que no aparece en «Sin tema».
- **edit a question**: Modificar el texto y conservar el tema seleccionado al guardar.
- **delete a question**: Confirmar su eliminación y dejar de verla en la lista.
- **answer a question**: Guardar una respuesta, verla junto a su pregunta y conservar el tema seleccionado.
- **edit an answer**: Cambiar una respuesta existente y mostrar el nuevo texto.
- **clear an answer**: Guardar una respuesta vacía y volver a mostrar la opción de responder.

## Topics

- **create a topic**: Crear un tema desde la administración y poder seleccionarlo en preguntas generales.
- **rename a topic**: Cambiar su nombre y conservar las preguntas que le pertenecen.
- **cancel editing a topic**: Cancelar la edición sin guardar el nombre escrito.
- **delete a topic**: Confirmar su eliminación y encontrar sus preguntas en «Sin tema».

## Documents

- **upload and delete documents**: Adjuntar archivos desde un acto, verlos en su detalle y eliminar uno sin borrar los demás.

## Production details

- **create, edit and delete production details**: Recorrer el formulario desde un acto, guardar y modificar unos pocos campos representativos y eliminar los detalles con confirmación.

## Fuera de esta cobertura de sistema

- Colores, márgenes, radios de borde y clases CSS exactas.
- Nombres de participantes, instrucciones concretas y conteos del evento real.
- Pruebas específicas de que los datos ya no vienen de YAML.
- Validaciones, restricciones de IDs y cálculos exhaustivos de horarios/comisiones: conservar su cobertura en modelos o controladores.

Para dar instrucciones puedes referirte al contexto y al nombre, por ejemplo: «Schedule / show preparations: dejarla» o «Questions / edit an answer: unirla con answer a question».
