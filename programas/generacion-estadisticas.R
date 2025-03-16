#
# GENERACIÓN DE ESTADÍSTICAS
#


# PAQUETES
library(here)
library(dplyr)
library(readr)
library(terra)


# PARÁMETROS GENERALES

# Archivo raster de capa de uso agropecuario forestal reclasificado comprimido
ARCHIVO_RASTER_USO_AGROPECUARIO_FORESTAL_RECLASIFICADO <-
  here("salidas", "mapa-agropecuario-forestal-2020.tif")

# Archivo CSV con estadísticas
ARCHIVO_CSV_ESTADISTICAS <-
  here("salidas", "estadisticas.csv")


# PROCESAMIENTO

# Lectura del archivo raster de capa de uso agropecuario forestal
agropecuario_forestal_terra_reclasificado <- 
  rast(ARCHIVO_RASTER_USO_AGROPECUARIO_FORESTAL_RECLASIFICADO)

cat("Generando estadísticas ...\n")
estadisticas <- freq(agropecuario_forestal_terra_reclasificado)

# Adición de columna de etiqueta de las clases
estadisticas <- estadisticas |> mutate(
  nombre_clase = case_when(
    value == 1 ~ "Red vial",
    value == 2 ~ "Parque nacional, reserva biológica o monumento natural",
    value == 3 ~ "Humedal",
    value == 4 ~ "Patrimonio natural del estado",
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