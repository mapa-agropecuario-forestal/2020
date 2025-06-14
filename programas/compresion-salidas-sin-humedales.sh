# En creacion-ambiente-gdal.sh se crea un ambiente conda con los programas de gdal
# Puede activarse con: conda activate gdal

gdal_translate -co compress=zstd -co zstd_level=9 \
  ../salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado-sin-humedales.tif \
  ../salidas/mapa-agropecuario-forestal-2020-sin-humedales.tif
rm ../salidas/mapa-agropecuario-forestal-2020-inicial-sin-humedales.tif
rm ../salidas/mapa-agropecuario-forestal-2020-inicial-reclasificado-sin-humedales.tif
