#=====================================#
#----- extract node data -------------#
#=====================================#

from netCDF4 import MFDataset,Dataset,num2date
import argparse 
import numpy as np
from numpy import sin, cos, arccos, sqrt, dot, arcsin, arctan, tan
from math import pi
import pandas as pd

#---------- some definitions ---------------
R = 6371000.0 # radius of the earth in meters
rad = pi / 180.0 # degrees to radians conversion

#---------- define a distance measure ------------#
def distance(lon1,lat1,lon2,lat2):
    lon1, lat1, lon2, lat2 = lon1*rad, lat1*rad, lon2*rad, lat2*rad
    """
    Great circle distance using Haversine forumla (numerically better conditioned)
    """
    dlon2 = (lon2 - lon1) / 2
    dlat2 = (lat2 - lat1) / 2
    under_sqrt = sin(dlat2)**2 + cos(lat1)*cos(lat2)*sin(dlon2)**2
    return 2*R*arcsin(sqrt(under_sqrt))

#------- create the parser --------------
parser = argparse.ArgumentParser(description='extract Shyfem format time series from unstructured Netcdf')

#--------------- default coordinate and dimension (ShyNCfile) ----------------------
def_c=["longitude", "latitude", "level"]
def_d=["node"]

# Porto Garibaldi station
def_lon=12.24945
def_lat=44.67667

#------- add argument for the parser -------------
parser.add_argument('-i','--input',nargs='*',type=str, help='input NetCDF unstructured files')
parser.add_argument('-c','--coord',nargs=3,type=str, help='coordinates variable name (lon, lat, z)',default=def_c)
parser.add_argument('-d','--dims',nargs=2,type=str, help='dimensions name (nodes)',default=def_d)
parser.add_argument('-lon',type=float,help='insert longitude of the point',default=def_lon)
parser.add_argument('-lat',type=float,help='insert latitude of the point',default=def_lat)
parser.add_argument('-v','--var',type=str, help='choose variable to extract from NC file',default="water_level")
parser.add_argument('-p','--print',action='store_true', help='print idexes and lon lat of NC file and distance from the point')
parser.add_argument('-V','--versione',action='version',help='print the version',version='NC2ts (unstructured) 1.0')

#--------- collect info from command line ---------------
args=parser.parse_args()

#-------- collect coordinate of the point to find ------------#
lon1 = args.lon
lat1 = args.lat

#------- read NetCDF data -----------#
fin = MFDataset(args.input)

#------ list dimensions name----------------#
lonname = 'longitude'
latname = 'latitude'
varname = args.var
timename= 'time'
levname = 'level'
el_index= 'element_index'

#----- assign coordinate variables -----------#
lat = fin.variables[latname][:]
lon = fin.variables[lonname][:]

#-------- assign time viariable and attributes ------#
time= fin.variables[timename][:]
units=fin.variables[timename].units
calnd=fin.variables[timename].calendar

#----------- generates dates -----------------------------#
dates = num2date(time[:], units=units, calendar=calnd)
#print(dates)
#----------------- convert to cftime to datetime object (readable by pandas) ------- #
dates= dates.astype('datetime64[ns]')
#print(dates)

#---------- assign variable -------------#
var = fin.variables[varname][:]

#-------- compute distance betweene grid points and your location  ------------
c = distance(lon,lat,lon1,lat1)

#----------- get the sorted indexes ------------------#
ind=np.argsort(c,axis=0)

# ------------- find the closest index for NetCDF -------------#
nloc=ind[0]

#----- decomment to check lat and lon of the point -------- #
if args.print:
  print(lon[nloc]," ",lat[nloc]," ",nloc)

#------------ take time series of the variable at location ----------#
if varname == 'water_level':
  ts = var[:,nloc]
  #----------- convert to pandas ---------------- #
  ts = pd.Series(ts,index=dates)
else:
  ts = var[:,nloc,:]
  #----------- convert to pandas ---------------- #
  ts = pd.DataFrame(ts,index=dates)

#---------- replace 0s to NaN (It is bad I know) --------#
ts = ts.replace(0.0,np.nan)
print(ts)

#--------- save to text file -------------- #
ts.to_csv(varname+'_ts.txt',sep=' ',header=None, date_format='%Y-%m-%d::%H:%M:%S')

