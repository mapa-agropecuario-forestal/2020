# Unión de los archivos de plantaciones forestales
# Ejecución: bash union-capas-plantacion-forestal.sh

# Debe utilizarse una versión de GDAL mayor o igual a 3.5. Puede crearse con un ambiente conda. Por ejemplo:
# conda create -n gdal -c conda-forge gdal

# Unión de los archivos
ogr2ogr \
  ../datos/originales/vectoriales/plantacion-forestal-2008-2020.gpkg \
  ../datos/originales/vectoriales/plantacion-forestal/Fonafifo_Reforestacion_2008.shp \
  -makevalid \
  -skipfailures \
  -overwrite \
  -nln plantacion-forestal-2008-2020 \
  -nlt MULTIPOLYGON
ogr2ogr -update -append \
  ../datos/originales/vectoriales/plantacion-forestal-2008-2020.gpkg \
  ../datos/originales/vectoriales/plantacion-forestal/Fonafifo_Reforestacion_2009.shp \
  -makevalid \
  -skipfailures \
  -nln plantacion-forestal-2008-2020 \
  -nlt MULTIPOLYGON
ogr2ogr -update -append \
  ../datos/originales/vectoriales/plantacion-forestal-2008-2020.gpkg \
  ../datos/originales/vectoriales/plantacion-forestal/Fonafifo_Reforestacion_2010.shp \
  -makevalid \
  -skipfailures \
  -nln plantacion-forestal-2008-2020 \
  -nlt MULTIPOLYGON
ogr2ogr -update -append \
  ../datos/originales/vectoriales/plantacion-forestal-2008-2020.gpkg \
  ../datos/originales/vectoriales/plantacion-forestal/Fonafifo_Reforestacion_2011.shp \
  -makevalid \
  -skipfailures \
  -nln plantacion-forestal-2008-2020 \
  -nlt MULTIPOLYGON
ogr2ogr -update -append \
  ../datos/originales/vectoriales/plantacion-forestal-2008-2020.gpkg \
  ../datos/originales/vectoriales/plantacion-forestal/Fonafifo_Reforestacion_2012.shp \
  -makevalid \
  -skipfailures \
  -nln plantacion-forestal-2008-2020 \
  -nlt MULTIPOLYGON
ogr2ogr -update -append \
  ../datos/originales/vectoriales/plantacion-forestal-2008-2020.gpkg \
  ../datos/originales/vectoriales/plantacion-forestal/Fonafifo_Reforestacion_2013.shp \
  -makevalid \
  -skipfailures \
  -nln plantacion-forestal-2008-2020 \
  -nlt MULTIPOLYGON
ogr2ogr -update -append \
  ../datos/originales/vectoriales/plantacion-forestal-2008-2020.gpkg \
  ../datos/originales/vectoriales/plantacion-forestal/Fonafifo_Reforestacion_2014.shp \
  -makevalid \
  -skipfailures \
  -nln plantacion-forestal-2008-2020 \
  -nlt MULTIPOLYGON
ogr2ogr -update -append \
  ../datos/originales/vectoriales/plantacion-forestal-2008-2020.gpkg \
  ../datos/originales/vectoriales/plantacion-forestal/Fonafifo_Reforestacion_2015.shp \
  -makevalid \
  -skipfailures \
  -nln plantacion-forestal-2008-2020 \
  -nlt MULTIPOLYGON
ogr2ogr -update -append \
  ../datos/originales/vectoriales/plantacion-forestal-2008-2020.gpkg \
  ../datos/originales/vectoriales/plantacion-forestal/Fonafifo_Reforestacion_2016.shp \
  -makevalid \
  -skipfailures \
  -nln plantacion-forestal-2008-2020 \
  -nlt MULTIPOLYGON
ogr2ogr -update -append \
  ../datos/originales/vectoriales/plantacion-forestal-2008-2020.gpkg \
  ../datos/originales/vectoriales/plantacion-forestal/Fonafifo_Reforestacion_2017.shp \
  -makevalid \
  -skipfailures \
  -nln plantacion-forestal-2008-2020 \
  -nlt MULTIPOLYGON
ogr2ogr -update -append \
  ../datos/originales/vectoriales/plantacion-forestal-2008-2020.gpkg \
  ../datos/originales/vectoriales/plantacion-forestal/Fonafifo_Reforestacion_2018.shp \
  -makevalid \
  -skipfailures \
  -nln plantacion-forestal-2008-2020 \
  -nlt MULTIPOLYGON
ogr2ogr -update -append \
  ../datos/originales/vectoriales/plantacion-forestal-2008-2020.gpkg \
  ../datos/originales/vectoriales/plantacion-forestal/Fonafifo_Reforestacion_2019.shp \
  -makevalid \
  -skipfailures \
  -nln plantacion-forestal-2008-2020 \
  -nlt MULTIPOLYGON
ogr2ogr -update -append \
  ../datos/originales/vectoriales/plantacion-forestal-2008-2020.gpkg \
  ../datos/originales/vectoriales/plantacion-forestal/Fonafifo_Reforestacion_2020.shp \
  -makevalid \
  -skipfailures \
  -nln plantacion-forestal-2008-2020 \
  -nlt MULTIPOLYGON

