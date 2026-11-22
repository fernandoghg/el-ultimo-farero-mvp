# Publicación futura del MVP

El destino público previsto es [fernandoghg/el-ultimo-farero-mvp](https://github.com/fernandoghg/el-ultimo-farero-mvp). El repositorio privado de desarrollo seguirá intacto. La publicación requiere autorización expresa y utilizará un historial nuevo e independiente.

1. Vuelve a comprobar la disponibilidad del nombre y la autorización. GitHub no encontró la ruta en la consulta autenticada como propietario del 22 de noviembre de 2026.
2. Prepara una carpeta nueva, fuera de cualquier repositorio o worktree existente. Copia las 171 rutas de la [lista final](manifiesto-derechos.md) con sus licencias, atribución, fuentes Blender saneadas y GLB. Excluye los cuatro respaldos, el historial privado, metadatos Git, evidencias locales, cachés y artefactos de compilación como EXE, PCK y ZIP. Comprueba las huellas y la privacidad de la copia.
3. Configura solo en la carpeta independiente el nombre público autorizado y la dirección `noreply` de GitHub que apruebe el propietario. Comprueba que autor y committer efectivos usan esa identidad antes de crear el commit.
4. Tras la autorización, inicializa Git únicamente en la carpeta nueva y crea un único commit raíz. Comprueba que el total de commits es uno y que ese commit carece de padres. Crea un repositorio GitHub vacío, desvinculado del historial privado, y configura exclusivamente su nuevo remoto. Tras publicar la rama principal, verifica desde una sesión sin credenciales el árbol, las licencias, la atribución y la visibilidad. Revisa los permisos antes de habilitar CI.
5. La distribución Windows requiere autorización propia. Antes de publicar un ZIP, verifica el paquete extraído, los avisos del juego y los de Godot y sus componentes. [Distribución Windows](windows-distribution.md).
