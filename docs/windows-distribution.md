
# Distribución portátil para Windows x86-64

El preset **Windows x86-64** exporta un ejecutable y un PCK externo con Godot 4.7.2 estándar. Incluye la escena de arranque, los catálogos español e inglés y sus dependencias. La selección declara también light_geometry.gd y noise.gdshaderinc para el código y los shaders cargados indirectamente. El ejecutable sale sin firma y usa Forward+ con Vulkan. Los mínimos de hardware propios del juego siguen sin medirse.

## Exportar y montar el ZIP local de validación

Usa el editor de consola estándar de Godot 4.7.2 para Windows x86-64 y las plantillas oficiales de la misma versión. En el editor, selecciona **Editor → Administrar plantillas de exportación → Instalar desde archivo** y elige el fichero TPZ. El SHA-256 del ZIP oficial del editor es 731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953. El SHA-256 del TPZ es f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011. [Descargas oficiales](https://godotengine.org/download/archive/4.7.2-stable/), [guía de exportación de Godot](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html).

Establece $godot con la ruta a Godot_v4.7.2-stable_win64_console.exe. Desde la raíz del proyecto, ejecuta el siguiente bloque con una carpeta de salida nueva. Revisa los diagnósticos ERROR: y SCRIPT ERROR: incluso cuando Godot sale con código cero.

~~~powershell
$ErrorActionPreference = 'Stop'
$version = & $godot --version
if ($LASTEXITCODE -ne 0 -or $version -ne '4.7.2.stable.official.ed1daf0bf') {
    throw 'Se requiere Godot 4.7.2 estándar oficial.'
}
$output = Join-Path ([IO.Path]::GetTempPath()) ('farero-windows-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path "$output/ElUltimoFarero"
$package = "$output/ElUltimoFarero"
& $godot --headless --path . --import
if ($LASTEXITCODE -ne 0) { throw 'Falló la importación.' }
& $godot --headless --path . --export-release 'Windows x86-64' "$package/ElUltimoFarero.exe"
if ($LASTEXITCODE -ne 0) { throw 'Falló la exportación.' }
Get-Item -LiteralPath "$package/ElUltimoFarero.exe","$package/ElUltimoFarero.pck" | Out-Null
Copy-Item -LiteralPath 'docs/windows-player-guide.txt' -Destination "$package/LEEME.txt"
foreach ($notice in 'LICENSE.txt', 'COPYRIGHT.txt') {
    Copy-Item -LiteralPath "third_party/godot/$notice" -Destination "$package/Godot-$notice"
}
$archive = "$output/ElUltimoFarero-Windows-x64-MVP.zip"
Compress-Archive -LiteralPath $package -DestinationPath $archive
Get-FileHash -LiteralPath $archive -Algorithm SHA256
~~~

El ZIP local de validación contiene cinco archivos. La carpeta extraída debe conservar juntos EXE, PCK, guía y los dos avisos del motor. El PCK y el ZIP pueden presentar hashes distintos entre compilaciones por la serialización del motor y los metadatos del archivo ZIP.

## Validar desde el ZIP extraído

1. Extrae el ZIP completo y arranca ElUltimoFarero.exe. Pulsa **Intro** desde la tarjeta inicial.
2. Sigue el [recorrido de pruebas](pruebas.md#recorrido-manual-con-soluciones). Comprueba los tres puzles, el faro, el puente, el desenlace, el reinicio y la salida.
3. Repite en inglés con .\ElUltimoFarero.exe -- --game-language en. Las comprobaciones de juego en un equipo de destino incluyen una sesión sin conexión desde una cuenta estándar.

En MVP-03, la persona responsable validó **9/9 comprobaciones manuales** en Windows 11. El arranque gráfico anterior se verificó con Vulkan y una RTX 4070. MVP-04B repite la importación, la batería automatizada y la exportación desde la copia independiente. [Resultados de la preparación](preparacion-candidata.md).

## Avisos para una eventual distribución pública

El paquete público debe acompañar los avisos `Godot-LICENSE.txt` y `Godot-COPYRIGHT.txt` con el texto MIT, la declaración de CC BY 4.0 y la atribución del juego, junto con su alcance por recurso. Incluye el manifiesto o una referencia a la revisión pública exacta que cubra el contenido del paquete. Verifica que las referencias sean accesibles desde el ZIP extraído y que los avisos del motor correspondan a la versión exportada. La publicación del ZIP requiere autorización separada. [MIT del proyecto](../LICENSE) · [Arte y contenidos](../LICENSE-ASSETS.md) · [Atribución](../ATTRIBUTION.md) · [Manifiesto](manifiesto-derechos.md).
