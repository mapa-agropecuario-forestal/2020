#
# GENERACIÓN DEL ARCHIVO PNG DEL MAPA (VERSIÓN 4)
#
# Produce la imagen estática del mapa para el README y para consulta
# rápida. En las versiones 1 a 3 el PNG se exportó manualmente desde QGIS;
# aquí se genera con código para que sea reproducible. La paleta y las
# etiquetas son las de qgis/colores.txt (Corine CR), sin las clases 2 (ASP)
# y 4 (PNE), que se omiten en la versión 4.
#


# PAQUETES
library(here)
library(terra)


# PARÁMETROS GENERALES

# Archivo raster de capa de uso agropecuario forestal (comprimida)
ARCHIVO_RASTER_USO_AGROPECUARIO_FORESTAL <-
  here("salidas", "mapa-agropecuario-forestal-2020-v4.tif")

# Archivo PNG
ARCHIVO_PNG <-
  here("salidas", "mapa-agropecuario-forestal-2020-v4.png")

# Clases, etiquetas y colores (qgis/colores.txt)
clases <- data.frame(
  codigo = c(1, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18),
  nombre = c(
    "Red vial",
    # "Parque nacional, reserva biológica o monumento natural", (se omite en v4)
    "Cuerpo de agua",
    # "Patrimonio natural del estado", (se omite en v4)
    "Caña", "Banano", "Café", "Cacao", "Pasto", "Palma", "Piña", "Cultivo",
    "Páramo", "Plantación forestal", "Cobertura forestal", "Suelo desnudo",
    "Zona urbana", "Sin información"
  ),
  color = c(
    "#f80000",
    # "#afffaf", (se omite en v4)
    "#b4e6fa",
    # "#cdcd64", (se omite en v4)
    "#ffaa00", "#f0f000", "#732600", "#ffd27d", "#ffffa6", "#ffa114",
    "#ff5000", "#becd00", "#64ff96", "#55ff00", "#266900", "#dcdcdc",
    "#f6d9df", "#ffffff"
  )
)


# PROCESAMIENTO

cat("Generando archivo PNG ...\n")

# Lectura del raster (sin categorías, para trabajar con los códigos)
agropecuario_forestal_terra <- rast(ARCHIVO_RASTER_USO_AGROPECUARIO_FORESTAL)
if (is.factor(agropecuario_forestal_terra)) {
  levels(agropecuario_forestal_terra) <- NULL
}

# Asignación de categorías para la leyenda
levels(agropecuario_forestal_terra) <-
  data.frame(codigo = clases$codigo, clase = paste(clases$codigo, clases$nombre, sep = " - "))

png(ARCHIVO_PNG, width = 2400, height = 1700, res = 150)
plot(
  agropecuario_forestal_terra,
  col = clases$color,
  maxcell = 4e6,
  mar = c(2, 2, 2, 12),
  main = "Mapa agropecuario y forestal de Costa Rica 2020 (versión 4)"
)
dev.off()

cat("Finalizado\n\n")

cat("FIN\n")
