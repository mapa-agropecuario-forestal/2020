#
# GENERACIÓN DE LOS ARCHIVOS PNG DE LAS VERSIONES DEL MAPA
#
# Produce, con una misma plantilla, la imagen de cada versión del mapa
# (A4 horizontal a 300 dpi): título, leyenda con las clases presentes en la
# versión, mapa con el contorno del país, barra de escala y norte.
#
# Las versiones 1 a 3 se exportaron originalmente a mano desde QGIS y la 4
# con terra::plot(); este programa las regenera todas con el mismo estilo.
#
# Los contornos de Nicaragua y Panamá provienen de la capa "Admin 0 -
# Countries" (1:10 M, dominio público) de Natural Earth
# (https://www.naturalearthdata.com/), descargada el 2026-09-27 y guardada,
# reproyectada a EPSG:5367, en datos/originales/vectoriales/
# paises-vecinos-natural-earth.gpkg (no versionado). Si el archivo no
# existe, las imágenes se generan sin los países vecinos.
#
# Uso:
#   Rscript programas/generacion-png.R            # las cuatro versiones
#   Rscript programas/generacion-png.R 4          # solo la versión 4
#   Rscript programas/generacion-png.R 4 /ruta    # versión 4 en otro directorio
#


# PAQUETES
library(here)
library(terra)
library(ragg)


# PARÁMETROS GENERALES

# Directorios
DIRECTORIO_SALIDAS <- here("salidas")
ARCHIVO_VECTORIAL_COSTARICA <-
  here("datos", "originales", "vectoriales", "costarica.gpkg")
ARCHIVO_VECTORIAL_PAISES_VECINOS <-
  here("datos", "originales", "vectoriales", "paises-vecinos-natural-earth.gpkg")

# Posición (EPSG:5367) de los nombres de los países vecinos
NOMBRES_PAISES_VECINOS <- data.frame(
  nombre = c("NICARAGUA", "PANAMÁ"),
  x = c(430000, 645000),
  y = c(1232000, 905000)
)

# Versiones del mapa
VERSIONES <- list(
  list(
    version = 1, fecha = "marzo de 2025",
    archivo_tif = "mapa-agropecuario-forestal-2020.tif",
    archivo_png = "mapa-agropecuario-forestal-2020-v1.png",
    cambio = "Versión inicial, con 18 clases.",
    etiqueta_clase_3 = "Humedal"
  ),
  list(
    version = 2, fecha = "setiembre de 2025",
    archivo_tif = "mapa-agropecuario-forestal-2020-v2.tif",
    archivo_png = "mapa-agropecuario-forestal-2020-v2.png",
    cambio = "Se omiten los humedales (Registro Nacional de Humedales y cuerpos de agua REDD+).",
    etiqueta_clase_3 = NA
  ),
  list(
    version = 3, fecha = "octubre de 2025",
    archivo_tif = "mapa-agropecuario-forestal-2020-v3.tif",
    archivo_png = "mapa-agropecuario-forestal-2020-v3.png",
    cambio = "Se reincorporan los cuerpos de agua REDD+ (clase \"Cuerpo de agua\"). Versión publicada en el SNIT.",
    etiqueta_clase_3 = "Cuerpo de agua"
  ),
  list(
    version = 4, fecha = "setiembre de 2026",
    archivo_tif = "mapa-agropecuario-forestal-2020-v4.tif",
    archivo_png = "mapa-agropecuario-forestal-2020-v4.png",
    cambio = "Se omiten las capas de áreas silvestres protegidas y de Patrimonio Natural del Estado.",
    etiqueta_clase_3 = "Cuerpo de agua"
  )
)

# Clases, etiquetas y colores (qgis/colores.txt)
CLASES <- data.frame(
  codigo = 1:18,
  nombre = c(
    "Red vial", "Parque nacional, reserva biológica o monumento natural",
    "Cuerpo de agua", "Patrimonio natural del estado", "Caña", "Banano",
    "Café", "Cacao", "Pasto", "Palma", "Piña", "Cultivo", "Páramo",
    "Plantación forestal", "Cobertura forestal", "Suelo desnudo",
    "Zona urbana", "Sin información"
  ),
  color = c(
    "#f80000", "#afffaf", "#b4e6fa", "#cdcd64", "#ffaa00", "#f0f000",
    "#732600", "#ffd27d", "#ffffa6", "#ffa114", "#ff5000", "#becd00",
    "#64ff96", "#55ff00", "#266900", "#dcdcdc", "#f6d9df", "#ffffff"
  ),
  stringsAsFactors = FALSE
)

# Tamaño de la imagen: A4 horizontal a 300 dpi
ANCHO_PX <- 3507
ALTO_PX <- 2480
DPI <- 300

# Máximo de celdas del raster que se dibujan (remuestreo regular)
MAXCELL <- 8e6

# Colores de la plantilla
COLOR_MAR <- "#dfe6ea"
COLOR_PAIS_VECINO <- "#f0f0f0"
COLOR_CONTORNO_PAIS_VECINO <- "#a6a6a6"
COLOR_NOMBRE_PAIS_VECINO <- "#8c8c8c"
COLOR_TIERRA_SIN_DATO <- "#ffffff"
COLOR_CONTORNO <- "#4d4d4d"
COLOR_TEXTO <- "#222222"
COLOR_TEXTO_SECUNDARIO <- "#555555"

# Fecha de generación
FECHA_GENERACION <- format(Sys.Date(), "%Y-%m-%d")


# FUNCIONES

# Parte un texto en líneas de un ancho máximo aproximado (en caracteres)
partir_texto <- function(texto, ancho) {
  paste(strwrap(texto, width = ancho), collapse = "\n")
}

# Genera la imagen de una versión
generar_png <- function(v, costarica, paises_vecinos, directorio_salidas) {
  archivo_tif <- file.path(DIRECTORIO_SALIDAS, v$archivo_tif)
  archivo_png <- file.path(directorio_salidas, v$archivo_png)

  cat(sprintf("Versión %d: %s -> %s\n", v$version, v$archivo_tif, v$archivo_png))

  # Raster (sin categorías, para trabajar con los códigos)
  mapa <- rast(archivo_tif)
  if (is.factor(mapa)) levels(mapa) <- NULL

  # Clases presentes en la versión (según la tabla de frecuencias de una
  # muestra regular; las clases raras se conservan si están en el raster)
  presentes <- sort(unique(na.omit(as.vector(spatSample(mapa, 2e6, method = "regular", as.raster = FALSE)[, 1]))))
  clases <- CLASES[CLASES$codigo %in% presentes, ]
  if (!is.na(v$etiqueta_clase_3)) clases$nombre[clases$codigo == 3] <- v$etiqueta_clase_3
  cat(sprintf("  Clases presentes: %s\n", paste(clases$codigo, collapse = ", ")))

  # Dispositivo
  agg_png(archivo_png, width = ANCHO_PX, height = ALTO_PX, res = DPI, background = "white")
  on.exit(dev.off(), add = TRUE)

  # Composición: panel de texto y leyenda (izquierda) y mapa (derecha)
  layout(matrix(1:2, nrow = 1), widths = c(1.2, 2))

  # --- Panel izquierdo
  par(mar = c(1.2, 1.5, 1.2, 0.3), family = "sans", xpd = NA)
  plot.new()
  plot.window(xlim = c(0, 1), ylim = c(0, 1))

  y <- 0.97
  text(0, y, "Mapa agropecuario\ny forestal de\nCosta Rica 2020",
       adj = c(0, 1), cex = 1.95, font = 2, col = COLOR_TEXTO)
  y <- y - 0.155
  text(0, y, sprintf("Versión %d (%s)", v$version, v$fecha),
       adj = c(0, 1), cex = 1.4, font = 1, col = COLOR_TEXTO)
  y <- y - 0.05
  text(0, y, partir_texto(v$cambio, 48),
       adj = c(0, 1), cex = 0.9, col = COLOR_TEXTO_SECUNDARIO)
  y <- y - 0.045 - 0.027 * length(strsplit(partir_texto(v$cambio, 48), "\n")[[1]])

  text(0, y, "Clases", adj = c(0, 1), cex = 1.2, font = 2, col = COLOR_TEXTO)
  y <- y - 0.045

  # Leyenda: un renglón por clase, con cuadro de color y etiqueta. El alto
  # de los renglones se adapta al espacio disponible (hasta el pie) y a las
  # etiquetas de dos líneas.
  y_pie <- 0.10
  etiquetas <- vapply(clases$nombre, partir_texto, character(1), ancho = 42)
  lineas <- vapply(strsplit(etiquetas, "\n"), length, integer(1))
  unidades <- ifelse(lineas > 1, 1.9, 1)
  alto_renglon <- min(0.037, (y - y_pie) / sum(unidades))
  alto_cuadro <- min(0.026, alto_renglon * 0.7)
  ancho_cuadro <- 0.075
  y_i <- y
  for (i in seq_len(nrow(clases))) {
    alto_i <- alto_renglon * unidades[i]
    centro <- y_i - alto_i / 2
    rect(0, centro - alto_cuadro / 2, ancho_cuadro, centro + alto_cuadro / 2,
         col = clases$color[i], border = "#7a7a7a", lwd = 0.8)
    text(ancho_cuadro + 0.03, centro, etiquetas[i],
         adj = c(0, 0.5), cex = 0.95, col = COLOR_TEXTO)
    y_i <- y_i - alto_i
  }

  # Pie
  pie <- c(
    "CR05 / CRTM05 (EPSG:5367). Resolución: 10 m.",
    "Fuente: github.com/mapa-agropecuario-forestal/2020",
    sprintf("Imagen generada el %s", FECHA_GENERACION)
  )
  text(0, 0.0, paste(pie, collapse = "\n"), adj = c(0, 0), cex = 0.72,
       col = COLOR_TEXTO_SECUNDARIO)

  # --- Panel derecho: mapa
  par(mar = c(0.5, 0.5, 0.5, 0.5), xpd = FALSE)
  e <- ext(costarica)
  margen <- 12000
  plot(NA, xlim = c(xmin(e) - margen, xmax(e) + margen),
       ylim = c(ymin(e) - margen, ymax(e) + margen),
       asp = 1, axes = FALSE, xlab = "", ylab = "", xaxs = "i", yaxs = "i")
  usr <- par("usr")
  rect(usr[1], usr[3], usr[2], usr[4], col = COLOR_MAR, border = NA)
  if (!is.null(paises_vecinos)) {
    plot(paises_vecinos, col = COLOR_PAIS_VECINO, border = COLOR_CONTORNO_PAIS_VECINO,
         lwd = 0.9, add = TRUE)
    text(NOMBRES_PAISES_VECINOS$x, NOMBRES_PAISES_VECINOS$y, NOMBRES_PAISES_VECINOS$nombre,
         cex = 1.0, col = COLOR_NOMBRE_PAIS_VECINO, font = 2)
  }
  plot(costarica, col = COLOR_TIERRA_SIN_DATO, border = NA, add = TRUE)
  plot(mapa, col = clases$color, type = "classes", levels = clases$codigo,
       maxcell = MAXCELL, legend = FALSE, axes = FALSE, add = TRUE)
  plot(costarica, col = NA, border = COLOR_CONTORNO, lwd = 1.4, add = TRUE)

  # Barra de escala y norte
  sbar(50000, xy = c(usr[1] + 20000, usr[3] + 22000), type = "bar",
       divs = 2, below = "km", label = c(0, 25, 50), cex = 0.9, lwd = 1.5)
  north(xy = c(usr[1] + 110000, usr[3] + 42000), type = 1, d = 20000,
        label = "N", cex = 1.1)

  # Marco
  rect(usr[1], usr[3], usr[2], usr[4], col = NA, border = "#9a9a9a", lwd = 1)

  cat("  Finalizado\n")
}


# PROCESAMIENTO

argumentos <- commandArgs(trailingOnly = TRUE)
versiones_a_generar <- if (length(argumentos) >= 1) as.integer(argumentos[1]) else 1:4
directorio_salidas <- if (length(argumentos) >= 2) argumentos[2] else DIRECTORIO_SALIDAS

cat("Cargando el contorno de Costa Rica ...\n")
costarica <- vect(ARCHIVO_VECTORIAL_COSTARICA)
costarica <- project(costarica, "EPSG:5367")
# Mismo recorte que en rasterizacion.R (excluye la Isla del Coco)
costarica <- crop(costarica, ext(280000, 660000, 880000, 1250000))
cat("Finalizado\n\n")

cat("Cargando los países vecinos ...\n")
paises_vecinos <- NULL
if (file.exists(ARCHIVO_VECTORIAL_PAISES_VECINOS)) {
  paises_vecinos <- vect(ARCHIVO_VECTORIAL_PAISES_VECINOS)
  paises_vecinos <- project(paises_vecinos, "EPSG:5367")
  # Recorte a un entorno del área del mapa
  paises_vecinos <- crop(paises_vecinos, ext(230000, 710000, 830000, 1300000))
  cat("Finalizado\n\n")
} else {
  cat("  AVISO: no existe", ARCHIVO_VECTORIAL_PAISES_VECINOS,
      "; las imágenes se generan sin los países vecinos\n\n")
}

for (v in VERSIONES) {
  if (v$version %in% versiones_a_generar) {
    generar_png(v, costarica, paises_vecinos, directorio_salidas)
  }
}

cat("FIN\n")
