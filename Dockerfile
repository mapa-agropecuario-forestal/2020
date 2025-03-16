# Imagen base con paquetes geoespaciales
FROM rocker/geospatial:4.4.3

# Clave para ingresar a RStudio Server
ENV PASSWORD=agropecuario

# Puerto de RStudio Server
EXPOSE 8787

# Instalación del paquete here de R, versión 1.0.1
RUN R -e "devtools::install_version('here', version = '1.0.1', repos = 'http://cran.us.r-project.org')"

# Instalación del paquete DT de R, versión 0.33
RUN R -e "devtools::install_version('DT', version = '0.33', repos = 'http://cran.us.r-project.org')"

# Instalación del paquete plotly de R, versión 4.10.4
RUN R -e "devtools::install_version('plotly', version = '4.10.4', repos = 'http://cran.us.r-project.org')"
