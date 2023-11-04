#! /usr/bin/python

import geopandas
import matplotlib.pyplot as plt

geopandas.options.io_engine = "pyogrio"

huc2 = geopandas.read_file("~/Documents/WBD/WBD_National_GPKG.gpkg", layer="WBDHU12")

#huc2["geometry"].bounds

ax = huc2.plot("geometry")
plt.show()

#help(huc2)
#print(huc2)
