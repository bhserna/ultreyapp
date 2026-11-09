# Cobertura de pruebas de controlador

Estas son las **22 pruebas de controlador**, complementando la cobertura de sistema.

El foco es comprobar límites de las peticiones: qué registros pueden consultar o modificar, qué parámetros aceptan y qué ocurre cuando se rechaza una operación. Comparten con sistema y modelos el conjunto de **8 actividades y 2 preparaciones** de `test/fixtures/`. Los demás registros se crean en cada escenario, sin depender del evento completo.

## Acts

- **reject non-act activities**: Rechazar con 404 los IDs de operaciones y acciones de preparación en las rutas de actos, preguntas, documentos y producción. En las escrituras rechazadas, comprobar que no se crean registros ni adjuntos.
- **reject an unknown act**: Devolver 404 cuando el acto de la URL no existe, sin crear registros asociados.

## Operations

- **resolve operations by source ID**: Buscar por `source_id`, aunque sea distinto del ID interno de la actividad; no confundir la operación con el acto del mismo número.
- **reject an unknown operation**: Devolver 404 si el ID recibido no corresponde al `source_id` de ninguna operación, aunque exista una actividad con ese ID interno.

## Preparations

- **reject an unknown preparation**: Devolver 404 cuando el grupo de preparación no existe.

## Questions

- **create under the act in the URL**: Enviar otro `act_id` y un `topic_id` en el formulario y comprobar que la pregunta queda asociada únicamente al acto de la URL.
- **create under the selected topic**: Usar el tema indicado en la URL, ignorando un `topic_id` distinto y un `act_id` enviados dentro de los atributos de la pregunta.
- **ignore topic selection for act questions**: En una ruta de acto, ignorar también un `topic_id` en la URL y no asignar la pregunta a ningún tema.
- **protect question associations and answers**: Al editar el texto, ignorar intentos de cambiar `act_id`, `topic_id` o `answer`; modificar únicamente `body`.
- **return to the question context**: Después de editar o eliminar, redirigir a las preguntas del acto o del tema al que pertenecía la pregunta, no al contexto enviado por el cliente.

## Answers

- **update only the answer**: Permitir cambiar `answer`, pero ignorar cambios enviados para el texto, el acto o el tema de la pregunta.
- **return to the question context**: Redirigir a las preguntas del acto o tema de la pregunta respondida, ignorando parámetros que intenten cambiar ese destino.

## Documents

- **upload under the act in the URL**: Asociar los documentos al acto de la ruta, aunque se envíe otro `act_id` en la petición.
- **list only the act documents**: No incluir en la respuesta documentos asociados a otro acto.
- **reject deletion through another act**: Intentar eliminar un documento desde la ruta de otro acto y recibir 404, conservando el documento, el adjunto y su archivo.
- **purge the deleted document file**: Al eliminar un documento propio del acto, borrar también su adjunto y blob, sin afectar los demás documentos.

## Production details

- **create under the act in the URL**: Ignorar un `act_id` enviado en el formulario y crear el detalle para el acto de la ruta.
- **protect the act association on update**: Editar campos permitidos sin permitir que el formulario cambie el acto asociado.
- **reject access through another act**: No permitir editar, actualizar ni eliminar los detalles de un acto utilizando la ruta de otro; devolver 404 y conservar el registro.
- **reject duplicate details**: Intentar crear un segundo detalle para el mismo acto, recibir 422 con el formulario y sus errores, y conservar intacto el detalle existente.

## Topics

- **protect question assignments**: Al editar el nombre, ignorar atributos como `question_ids` que intenten asociar o desasociar preguntas mediante ese formulario.
- **reject an unknown topic**: Devolver 404 al editar, actualizar o eliminar un tema inexistente.

## Schedule

No hay pruebas específicas de su controlador mientras solo construya `Schedule` y renderice el resultado:

- Las reglas de selección, filtros y orden corresponden a pruebas de `Schedule`.
- Los controles, enlaces y resultados visibles ya se cubren en sistema.

## Fuera de esta cobertura de controlador

- Repetir los recorridos completos de crear, editar y navegar que ya cubren las pruebas de sistema.
- Verificar todos los campos, textos, columnas o clases CSS de una página.
- Comparar horarios, participantes o cantidades del evento real.
- Repetir cálculos y validaciones que pertenecen a modelos.
- Pruebas que solo comprueben una respuesta exitosa sin verificar una regla adicional.

## Notas

- La cobertura de identidad antes ubicada en `test/integration/activity_identity_test.rb` ahora está en las pruebas de actos y operaciones, sin duplicarla.
- No incluyo una expectativa nueva de formularios con 422 para preguntas o temas: actualmente usan `create!`/`update!`, y `Topic` no tiene validaciones de nombre. Agregar ese comportamiento sería otro cambio de aplicación. El rechazo de producción duplicada sí tiene manejo explícito del formulario.
- Un 404 o 422 en una escritura debe acompañarse de la comprobación de que los registros relevantes quedaron intactos.

Puedes dar instrucciones por contexto y nombre, por ejemplo: «Documents / reject deletion through another act: dejarla».
