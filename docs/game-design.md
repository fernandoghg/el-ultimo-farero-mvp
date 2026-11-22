# Diseño del videojuego

El MVP ejecuta `scenes/new_game.tscn` con la introducción, la isla V3.2, los tres circuitos resolubles en cualquier orden, el faro, el puente y el desenlace. Las secciones siguientes recogen decisiones y experimentos históricos. [Estado actual](roadmap.md), [pruebas del MVP](pruebas.md).

## Faro V2 aprobado

El faro protagonista adopta la variante V2 de piedra estilizada, altura 3,9 y base aproximada 1,1, aprobada 5/5 artísticamente y 6/6 funcionalmente. Se conserva posición, orientación, interacción y progresión; V1 queda como referencia. El ajuste aprobado de cámara conserva su comportamiento habitual y termina el seguimiento residual con umbral 0,0025. Pequeño parpadeo de juntas aceptado provisionalmente, no bloqueante; no se investiga en esta separación.

La apariencia bajo la iluminación original de main se revisa en [la consolidación](lighthouse-v2-separation.md). No se considera aprobada la fase visual 5.1 completa ni se añaden caminos, rocas o vegetación.


## Estado de integración en 4.6 — validación manual 10/10

Aprobación comunicada por el responsable el 2026-11-02: diez comprobaciones correctas y sin observaciones.

El responsable cambia expresamente la secuencia encadenada por tres puzles resolubles en cualquier orden. No hay dependencia entre P1/P2/P3 ni cambios de orientaciones, soluciones, geometría o efectos. Cada resolución se registra una vez durante la sesión. Solo el faro requiere los tres; I con 0/1/2 muestra temporalmente el progreso localizado, sin revelar identidades pendientes. Con 3/3 hace falta una nueva pulsación junto al faro para activarlo y reconstruir el puente. No se muestra contador al resolver ni HUD permanente. Nueva partida reinicia 0/3; sin guardado. [Pruebas y checklist 4.6](phase-4-6-validation.md). Los alcances previos siguientes son históricos.

## Estado de P2 en 4.5 — validación manual 10/10

El responsable aprueba diez comprobaciones manuales correctas y sin observaciones. Confirma estados independientes, solución única por ambos espejos, muro, claridad/confirmación, es/en y ausencia de regresiones. Reutilización óptica aprobada; no se integra progreso con los otros puzles o el faro. Commit, push, PR y squash autorizados tras verificaciones locales y Actions satisfactorias; conservar rama remota y no comenzar otra fase.

Tras revisión de integración/4.4, se autoriza «Los espejos del guardián» aislado: dos placas de dos orientaciones, muro sólido en L, fuente y receptor. Una/dos marcas distinguen las piezas y un indicador muestra la recepción del segundo espejo. De cuatro parejas, solo una conduce físicamente por ambos espejos hasta el receptor. I actúa únicamente sobre el espejo próximo, sin repetición mantenida; antes de resolver se puede corregir. Confirmación breve, señal única y estabilización en sesión. Suministro propio provisional, sin progreso o nuevas condiciones del faro. [Pruebas y checklist](phase-4-5-validation.md). Sin zoom, pulido definitivo, guardado o dependencias.

## Concepto general

**El último farero: Los mundos del infinito** es una aventura fantástica isométrica 2.5D para Windows. El concepto general combina exploración, puzles, combates y descubrimiento en archipiélagos de islas flotantes procedimentales. Mandelbrot, Julia, la geometría fractal y los sistemas recursivos son inspiración visual y sistémica; no se exige una representación matemática exacta.

Los faros estabilizan la realidad y transforman los escenarios. El argumento, los personajes y las reglas completas del mundo siguen abiertos. El alcance del primer incremento se concreta a continuación y no incluye todas las mecánicas del concepto general.

## Decisiones aprobadas para el primer prototipo

### Representación y cámara

- Escenarios tridimensionales con cámara ortográfica y perspectiva isométrica. La proyección permanece siempre ortográfica.
- Estética objetivo: pixel art moderno con iluminación y efectos cuidados.
- Cámara giratoria en incrementos de 90 grados, seguimiento suave del personaje e inclinación inicialmente fija de aproximadamente 35 grados.
- La base funcional utiliza Godot 4.7.2 y GDScript; Forward+ está validado manualmente en Windows 11.

### Movimiento e interacción

- Movimiento directo mediante WASD, relativo a la orientación de la cámara.
- Sin salto libre. Las diferentes alturas se recorren mediante rampas, caminos, escaleras o puentes; no se exige incluir todos estos elementos en la primera isla.
- Al aproximarse al faro aparece un mensaje de interacción localizado en español e inglés.
- El jugador pulsa `I` para activar el faro.

### Bucle y transformación

Recorrer la isla, descubrir el puente destruido, aproximarse al faro, activarlo con `I`, observar la reconstrucción y cruzar a una zona anteriormente inaccesible. La reconstrucción debe ser visualmente perceptible y las colisiones coherentes con el estado del puente.

### Alcance y límites

Una isla flotante inicial, un personaje controlable, un faro y un puente reconstruible. Windows como plataforma inicial; español e inglés desde la primera interfaz; funcionamiento offline, sin telemetría ni servicios externos innecesarios.

No incluir combate, salto, archipiélagos completos ni sistemas fractales complejos en el primer incremento. Preparar la arquitectura para generación procedural futura sin implementarla prematuramente. No se ha elegido todavía el método de creación de la isla inicial; cualquier propuesta debe respetar esta exclusión de implementación procedural prematura.

## Diseño futuro de fase 4

El responsable solicita una evolución hacia exploración, misterio y puzles de luz/fractales. El [documento de fase 4](phase-4-light-fractal-puzzles.md) registra las decisiones generales aprobadas y distingue los detalles técnicos/de montaje aún propuestos. El mapa de 120° se conserva con una convención geométrica explícita. Secuencia futura requerida: La luz perdida → Los espejos del guardián → El eco del infinito → activación del faro → reconstrucción del puente. La activación directa actual con I es provisional; no se modifica en esta tarea.

El diseño de inspección aprobado reutiliza A/D para seleccionar, I para girar y Esc para volver al juego con prioridad sobre pausa. El contrato exige pulsaciones nuevas, consumo por contexto y liberación al entrar/salir, sin herencia a movimiento o faro. Fuera de inspección Esc conserva su reserva de pausa. 4.1 quedó validada manualmente 7/7 e integrada mediante revisión de integración. La ampliación autorizada 4.2 incorpora tres parejas independientes y un monumento provisional asentado en piedra dentro de la isla, próximo al faro; conserva autosimilitud fija y desfase físico de 120°. No hay puzles completos, detectores de solución o nuevas condiciones del faro. La validación manual 10/10 y la fase 4.2 están aprobadas por el responsable; checklist en README. El encuadre actual es aceptable y el zoom queda aplazado expresamente a una futura valoración de pulido.

## Controles aprobados

| Acción | Tecla inicial |
| --- | --- |
| Movimiento relativo a la cámara | WASD |
| Girar cámara 90 grados a la izquierda | `Q` |
| Girar cámara 90 grados a la derecha | `E` |
| Interactuar con el faro | `I` |
| Futuro menú de pausa | `Esc` |

La interacción mediante `I` sustituye a `E`; el conflicto anterior queda resuelto y la alternativa `Q`/`R` queda descartada. Registrar las teclas como acciones configurables mediante el Input Map de Godot. No implementar todavía un menú de reasignación ni el futuro menú de pausa.

## Idiomas y asuntos pendientes

**Estado de P3 en 4.3 (segunda validación manual 5/5):** tras integrar 4.2 mediante revisión de integración, el incremento autorizado incorpora tres objetivos fijos en el monumento, rutas energizadas y resolución lógica global. El suministro está disponible autónomamente desde el inicio, como excepción temporal explícita a la futura secuencia P1/P2. Comparar símbolo, muesca y objetivo entre escalas debe permitir deducir cada orientación; el modelo pequeño no replica los objetivos ni muestra números. Una recepción completa asentada emite una señal única, muestra confirmación breve y estabiliza el conjunto. La inspección se cierra y se puede reabrir sin editar; Esc permite salir antes. Faro y puente conservan el contrato actual sin condición nueva. El responsable confirma comprensión de la meta y deducción sin azar tras la primera ronda 8/10 y la revisión visual aprobada 5/5. Cámara y encuadre aceptados permanecen intactos; sin zoom o nuevas mecánicas fuera de P3. La representación natural de energía y cristales mediante materiales, iluminación, efectos y sonidos queda para pulido futuro, conservando legibilidad y lógica. Los apartados históricos de 4.1/4.2 describen sus respectivas versiones, no el alcance actual.

Externalizar todos los textos visibles y validar ambos idiomas, acentos, eñes, legibilidad y expansión del texto. Español es el idioma predeterminado y el inglés puede probarse con `-- --game-language en`. El aviso usa catálogos PO con clave estable. La fase 3.1 tiene pruebas automáticas y manuales satisfactorias, incluido inglés confirmado por el usuario. Selector y persistencia de preferencias siguen pendientes.

Se propone revisar contraste y claridad de la transformación sin depender solo del color. Soporte de mando y opciones concretas de accesibilidad siguen abiertos; el menú de reasignación se pospone. Movimiento y cámara funcionan y están validados: velocidad inicial 4 unidades/s, seguimiento 8/s y giros de 0,45 s, configurables. El faro tiene colisión, radio inicial configurable de 2 y activación única por escena. La fase 3.2 está implementada y validada automática y manualmente: seis segmentos ascienden durante 1,5 s configurables, con acceso bloqueado hasta activar el suelo físico y paso posterior de ida y vuelta a una plataforma de destino. Las diez comprobaciones manuales y la corrección del parpadeo por superficies superpuestas están confirmadas por el usuario; la geometría sigue siendo provisional; no hay reconstrucción repetida ni persistencia. No ampliar el alcance para resolverlos sin autorización.

## Estado de P1 en 4.4 — validación manual 10/10

El responsable aprueba diez comprobaciones manuales correctas, incluidas trayectoria, solución única, estabilización, es/en y regresiones. La independencia actual entre puzles es intencionada; progreso y conexión al faro serán posteriores. El cierre autoriza commit, push, PR y squash tras comprobaciones locales y Actions satisfactorias; conservar la rama remota y no iniciar otra fase.

Tras integrar 4.3 por revisión de integración, el incremento autorizado prototipa «La luz perdida» en la zona sureste accesible: fuente dorada, placa clara de dos diagonales, superficie inerte inicial y receptor con marco de rombo. I cerca alterna el reflector sin penalización; solo una trayectoria reflejada que alcanza físicamente la cara sensible, sin obstáculos, resuelve y estabiliza. Un pulso breve y avisos es/en confirman el resultado. El suministro es local e independiente; no hay conexión de progreso a P2/P3 ni al faro. Cámara y puente permanecen intactos. [Validación técnica y checklist humano](phase-4-4-validation.md); pulido audiovisual y zoom siguen aplazados.
