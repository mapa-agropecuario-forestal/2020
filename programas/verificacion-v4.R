#
# VERIFICACIÓN DE LA VERSIÓN 4 DEL MAPA
#
# Comprueba que la versión 4 (sin ASP ni PNE) es idéntica a la versión 3 en
# todas las celdas donde la versión 3 no tenía las clases 2 (ASP) ni 4
# (PNE), y reporta a qué clases pasaron las celdas que en la versión 3
# tenían esas dos clases. También muestrea el mapa en algunos puntos de
# control ubicados en las clases omitidas.
#
# Salidas (en salidas/):
#   - transicion-v3-v4.csv: matriz de transición de clases v3 -> v4 (celdas)
#


# PAQUETES
library(here)
library(dplyr)
library(readr)
library(terra)


# PARÁMETROS GENERALES

ARCHIVO_RASTER_V3 <- here("salidas", "mapa-agropecuario-forestal-2020-v3.tif")
ARCHIVO_RASTER_V4 <- here("salidas", "mapa-agropecuario-forestal-2020-v4.tif")
ARCHIVO_CSV_TRANSICION <- here("salidas", "transicion-v3-v4.csv")

# Clases omitidas en la versión 4
CLASES_OMITIDAS <- c(2, 4)

# Puntos de control (CRTM05, EPSG:5367)
SITIOS <- data.frame(
  sitio = c("Punto 1 (PNE, Tronadora)", "Punto 2 (PNE, Guanacaste)", "Punto 3 (ASP, Chirripó)"),
  x = c(410409.67, 350256.99, 559801.19),
  y = c(1152529.08, 1202468.42, 1037045.89)
)


# PROCESAMIENTO

cat("1/3 Comparando grillas ...\n")

v3 <- rast(ARCHIVO_RASTER_V3)
v4 <- rast(ARCHIVO_RASTER_V4)
if (is.factor(v3)) levels(v3) <- NULL
if (is.factor(v4)) levels(v4) <- NULL

cat(sprintf("  Misma geometría (dimensiones, extensión, resolución, CRS): %s\n",
            compareGeom(v3, v4, stopOnError = FALSE)))
cat(sprintf("  Dimensiones: %d x %d; resolución: %s\n",
            nrow(v4), ncol(v4), paste(round(res(v4), 4), collapse = " x ")))

cat("Finalizado\n\n")


cat("2/3 Calculando la matriz de transición v3 -> v4 ...\n")

transicion <- crosstab(c(v3, v4), long = TRUE, useNA = TRUE)
names(transicion) <- c("clase_v3", "clase_v4", "celdas")
transicion <- transicion |>
  mutate(
    clase_v3 = as.integer(as.character(clase_v3)),
    clase_v4 = as.integer(as.character(clase_v4))
  ) |>
  arrange(clase_v3, clase_v4)
write_csv(transicion, ARCHIVO_CSV_TRANSICION)

# Clases presentes en v4
cat(sprintf("  Clases en v4: %s\n",
            paste(sort(unique(na.omit(transicion$clase_v4))), collapse = ", ")))
cat(sprintf("  ¿Alguna celda con clase 2 o 4 en v4?: %s\n",
            any(transicion$clase_v4 %in% CLASES_OMITIDAS)))

# Celdas donde v3 no era 2 ni 4 y v4 difiere de v3
diferencias <- transicion |>
  filter(!(clase_v3 %in% CLASES_OMITIDAS), !(is.na(clase_v3) & is.na(clase_v4))) |>
  filter(is.na(clase_v3) != is.na(clase_v4) | clase_v3 != clase_v4)
cat(sprintf("  Celdas que cambiaron fuera de las clases 2 y 4: %d (se espera 0)\n",
            sum(diferencias$celdas)))

# Total de celdas con dato
cat(sprintf("  Celdas con dato: v3 = %d; v4 = %d\n",
            sum(transicion$celdas[!is.na(transicion$clase_v3)]),
            sum(transicion$celdas[!is.na(transicion$clase_v4)])))

# Destino de las celdas de las clases 2 y 4
cat("\n  Destino en v4 de las celdas de las clases 2 y 4 de v3:\n")
transicion |>
  filter(clase_v3 %in% CLASES_OMITIDAS) |>
  group_by(clase_v3) |>
  mutate(proporcion = round(celdas / sum(celdas), 4), ha = celdas / 100) |>
  ungroup() |>
  arrange(clase_v3, desc(celdas)) |>
  as.data.frame() |>
  print()

cat("Finalizado\n\n")


cat("3/3 Muestreando los puntos de control ...\n")

valores <- data.frame(
  SITIOS,
  v3 = extract(v3, as.matrix(SITIOS[, c("x", "y")]))[, 1],
  v4 = extract(v4, as.matrix(SITIOS[, c("x", "y")]))[, 1]
)
print(valores)

cat("Finalizado\n\n")

cat("FIN\n")
