#
# GENERACIÓN DE ESTADÍSTICAS SIN HUMEDALES, PNE NI ASP (VERSIÓN 4)
#


# PAQUETES
library(here)
library(dplyr)
library(readr)
library(terra)


# PARÁMETROS GENERALES

# Archivo raster de capa de uso agropecuario forestal reclasificado comprimido
ARCHIVO_RASTER_USO_AGROPECUARIO_FORESTAL_RECLASIFICADO <-
  here("salidas", "mapa-agropecuario-forestal-2020-v4.tif")

# Archivo CSV con estadísticas
ARCHIVO_CSV_ESTADISTICAS <-
  here("salidas", "estadisticas-v4.csv")


# PROCESAMIENTO

# Lectura del archivo raster de capa de uso agropecuario forestal sin humedales, PNE ni ASP
agropecuario_forestal_terra_reclasificado <- 
  rast(ARCHIVO_RASTER_USO_AGROPECUARIO_FORESTAL_RECLASIFICADO)

# Si el archivo tiene una tabla de atributos (.vat.dbf) asociada, terra lo
# lee como raster categórico y freq() devuelve etiquetas en lugar de códigos
# (así quedó estadisticas-v3.csv, con los nombres en la columna codigo_clase).
# Se eliminan las categorías para trabajar con los códigos numéricos.
if (is.factor(agropecuario_forestal_terra_reclasificado)) {
  levels(agropecuario_forestal_terra_reclasificado) <- NULL
}

cat("Generando estadísticas ...\n")
estadisticas <- freq(agropecuario_forestal_terra_reclasificado)

# Adición de columna de etiqueta de las clases
estadisticas <- estadisticas |> mutate(
  nombre_clase = case_when(
    value == 1 ~ "Red vial",
    # value == 2 ~ "Parque nacional, reserva biológica o monumento natural", (se omite en v4)
    value == 3 ~ "Cuerpo de agua",
    # value == 4 ~ "Patrimonio natural del estado", (se omite en v4)
    value == 5 ~ "Caña",
    value == 6 ~ "Banano",
    value == 7 ~ "Café",
    value == 8 ~ "Cacao",
    value == 9 ~ "Pasto",
    value == 10 ~ "Palma",
    value == 11 ~ "Piña",
    value == 12 ~ "Cultivo",
    value == 13 ~ "Páramo",
    value == 14 ~ "Plantación forestal",
    value == 15 ~ "Cobertura forestal",
    value == 16 ~ "Suelo desnudo",
    value == 17 ~ "Zona urbana",
    value == 18 ~ "Sin información"
  )
)

# Borrado de la columna "layer"
estadisticas <- estadisticas |>
  select(
    codigo_clase = value,
    nombre_clase,
    celdas = count
  )

# Adición de columnas de m2, ha y km2
estadisticas <- estadisticas |>
  mutate(
    m2 = celdas * 100,
    ha = m2 / 10000,
    km2 = m2 / 1000000
  )

# Conteo del total de celdas
total_celdas <- sum(estadisticas$celdas)

# Adición de columna de proporción
estadisticas <- estadisticas |>
  mutate(
    proporcion = celdas / total_celdas
  )

# Despliegue del resultado
print(estadisticas)

# Almacenamiento del resultado
write_csv(estadisticas, ARCHIVO_CSV_ESTADISTICAS)

cat("Finalizado\n\n")

cat("FIN\n")