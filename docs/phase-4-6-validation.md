# Fase 4.6 — Restauración del faro

Prototipo en `rama de integración`, desde main/revisión de integración. Validación manual aprobada por el responsable: **10/10 comprobaciones correctas, sin observaciones**. Cierre mediante commit, PR y squash autorizado tras pruebas locales y GitHub Actions satisfactorias; conservar la rama remota.

## Decisión vigente y arquitectura

El responsable sustituye expresamente la secuencia antigua P1→P2→P3 por **orden completamente libre**. «La luz perdida», «Los espejos del guardián» y «El eco del infinito» conservan suministro autónomo, accesibilidad, estados, soluciones, geometría, controles y mensajes. La única dependencia nueva es que el faro exige los tres resueltos. El faro sigue activándose manualmente con I; resolver el último circuito no lo activa ni reconstruye el puente.

`scripts/main.gd` conserva el idioma y registra tres booleanos locales de sesión: P1/LostLight, P2/GuardianMirrors y P3/FractalRotor. Conecta las señales existentes `resolved`, `resolved` y `circuit_completed` a un registro ligado a cada identidad. Solo acepta una transición pendiente→resuelto de un controlador realmente resuelto; ignora identidades desconocidas, señales prematuras y repeticiones. Verifica conexiones antes de añadirlas. El contador se deriva de esos tres booleanos; no hay conteo incremental separado, autoload, gestor de misiones o estado global mutable.

El faro referencia al controlador de su propia escena y consulta el número actual al pulsar I. Con 0/1/2 circuitos permanece apagado y el puente destruido. El Label contextual existente muestra durante **dos segundos** «Circuitos restaurados: X de 3» / «Circuits restored: X of 3». Es una fotografía del intento: resolver un circuito no muestra ni actualiza automáticamente un contador. Mantener I no renueva el aviso; al caducar vuelve la invitación contextual normal. Al alejarse se oculta. No se revelan circuitos pendientes o soluciones ni se añade HUD.

Con 3/3, solo una pulsación nueva en alcance usa la activación original: luz/material, señal `activated` única y conexión existente a `Bridge.reconstruct`. El puente conserva sus tiempos, colisiones, barreras y estabilización. Si falta el proveedor de progreso, el faro considera cero circuitos; no existe un bypass de partida. Una nueva instancia de la escena comienza siempre en 0/3 y puente destruido. No se escribe progreso en archivos.

## Pruebas

```powershell
Godot --headless --path . --script tests/restauracion_faro.gd
Godot --headless --path . --script tests/restauracion_faro.gd -- --game-language en
```

La suite restaura circuitos reales en los seis órdenes: P1-P2-P3, P1-P3-P2, P2-P1-P3, P2-P3-P1, P3-P1-P2 y P3-P2-P1. Comprueba estados inicial/individual, conteos 0/1/2/3, identidad, repetición/prematuridad de señales, conexión única, ausencia de aviso automático, mensajes exactos es/en y expiración. Mantiene I mientras termina el último circuito y exige soltar y volver a pulsar. Verifica falta de activación/reconstrucción prematura, activación única, una conexión al puente, reconstrucción y estabilidad, persistencia al alejarse/girar cámara, nueva partida limpia y cierre seguro si falta el proveedor.

`tests/circuit_fixture.gd` prepara las soluciones mediante los métodos existentes y espera sus consultas físicas/giros y señales. Solo se usa desde pruebas. Las regresiones de faro y puente satisfacen así la nueva precondición conservando sus comprobaciones anteriores. La suite fractal ahora comprueba que P3 solo no activa el faro; completa P1/P2 reales y conserva su comprobación de activación manual y puente. No se eliminan casos ni se añaden opciones de desbloqueo al juego.

Batería local: integración es/en, P2 es/en, P1 es/en, resolución fractal es/en, inspección de un rotor es/en, tres rotores es/en, personaje/cámara, faro es/en y puente: **16 ejecuciones headless**, todas con salida 0 y cero fallos, sin errores de Godot. Importación satisfactoria. La integración gráfica es/en también termina con salida 0 y cero fallos en Forward+ a 1280 × 720; seis capturas revisadas. Resultados reales en el diario. CI permanece sin cambios. El cierre autorizado exige comprobar GitHub Actions en la PR antes de fusionar.

Para revisión gráfica: quitar `--headless` y añadir `-- --capture` (o `-- --game-language en --capture`). Guarda capturas de intentos 0/1/2 a 1280 × 720 en build/ ignorado, usando la cámara normal. No sustituye la validación humana.

## Checklist manual de referencia

La validación humana comunicada el 2026-11-02 obtiene 10/10, sin observaciones. Los siguientes puntos agrupan el procedimiento para futuras regresiones.

1. F5 en Godot 4.7.2, ventana 1280 × 720. Sin resolver nada, acercarse al faro y pulsar I: mensaje 0 de 3, faro apagado, puente inaccesible. Mantener I: el aviso debe caducar tras unos dos segundos y no renovarse hasta soltar/repetir. Alejarse lo oculta.
2. Resolver cualquier primer puzle. No debe aparecer un contador automático ni cambiar los otros puzles. Volver al faro y pulsar I: 1 de 3, sin activación o reconstrucción. Repetir con un segundo puzle: 2 de 3 y mismo bloqueo.
3. Resolver el tercero, conservando sus efectos y estabilización originales. No debe activarse el faro ni comenzar el puente. Acercarse manteniendo I desde fuera: exigir liberación y nueva pulsación dentro de alcance.
4. Pulsar I con los tres resueltos: activación única y reconstrucción original. Repetir I, alejarse/volver y cruzar el puente en ambos sentidos: faro y segmentos permanecen estables.
5. Reiniciar entre recorridos y probar los seis órdenes listados arriba (como mínimo contrastar uno que empiece por P3 con otro que termine en P3). Siempre se comienza en 0/3; P1/P2/P3 permanecen accesibles y resolubles sin depender entre sí. Verificar movimiento, Q/E, A/D/I/Esc en el fractal y ausencia de pulsaciones heredadas al entrar/salir.
6. Repetir en inglés con `Godot --path . -- --game-language en`. Revisar «Circuits restored: X of 3» para 0/1/2, sin claves, identidades pendientes o soluciones; texto completo, discreto y temporal.

## Límites

Aceptación manual satisfactoria, incluida la duración del mensaje y el recorrido libre. Progreso solo durante la sesión; recargar reinicia los tres puzles. Sin contenido, recursos, servicios, telemetría, dependencias, persistencia, zoom o pulido audiovisual nuevo. Los puzles y el puente no se rediseñan. La secuencia antigua queda como historial, no como dependencia vigente.
