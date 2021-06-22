#!/lhome/mare_exp/anaconda3/envs/shypy/bin/python
#-------------------------------------------
#---- read and plot unstructured data ------
#-------------------------------------------

from datetime import datetime
from netCDF4 import Dataset,num2date
import argparse
import cmocean
import Ngl
#from cftime import utime
import sys
import numpy as np
import pandas as pd

#------- create the parser --------------
parser = argparse.ArgumentParser(description='plot unstructured Netcdf file')

#------- add argument for the parser -------------
parser.add_argument('-i','--inp',type=str, help='input NetCDF file')
parser.add_argument('-tmin',type=str, help='starting time Format: Y-m-d::H:M')
parser.add_argument('-tmax',type=str, help='end time Format: Y-m-d::H:M')
parser.add_argument('-var',type=str,help='variable name')
parser.add_argument('-name',type=str,help='title of the plot',default=None)
parser.add_argument('-l','--layer',type=int,help='choose the layer to plot',default=0)
parser.add_argument('-minv',type=float, help='choose minimum value to display')
parser.add_argument('-maxv',type=float, help='choose maximum value to display')
parser.add_argument('-spac',type=float, help='choose the spacing for the plot isolines')
parser.add_argument('-last',action='store_true', help='plot variable in last layer of each element')
parser.add_argument('-diff',action='store_true', help='plot a difference')
parser.add_argument('-V','--version',action='version',help='print the version',version='shyNCplot 1.1 (unstructured)')

#--------- collect info from command line ---------------#
args=parser.parse_args()

#-------- read Netcdf file -------------#
fname = args.inp
fin = Dataset(fname, mode='r')

#------ list dimensions name----------------#
lonname = 'longitude'
latname = 'latitude'
timename= 'time'
levname = 'level'
el_index= 'element_index'
varname = args.var

#----------- read variables from Netcdf -------#
# coordinate
lon = fin.variables[lonname][:]
lat = fin.variables[latname][:]
dept= fin.variables[levname][:]
el_in=fin.variables[el_index][:]
#variables

if varname == 'velocity':
  var1 = fin.variables['u_velocity'][:]
  var2 = fin.variables['v_velocity'][:]
  #--------- compute speed --------------#
  var = np.sqrt(var1**2 + var2**2)
  #------------ variable units -------------#
  var_unit = fin.variables['u_velocity'].units
else:
  var = fin.variables[varname][:]
  #------------ variable units -------------#
  var_unit = fin.variables[varname].units

#-------- 0 values to nan -----------#
if args.last:
  var = np.where(var == 0,np.nan,var)
else:
  var = np.where(var == 0,1.e20,var)

#------------- choose layer -----------#
lev = args.layer

#---------- choose min, max and spacing values for the plot ------------#
minval = args.minv
maxval = args.maxv
spacing= args.spac

#---------------- elaborate time variable -----------------#
time = fin.variables[timename][:]
t_unit = fin.variables[timename].units
t_cal = fin.variables[timename].calendar
tmin= datetime.strptime(args.tmin,'%Y-%m-%d::%H:%M') 
tmax= datetime.strptime(args.tmax,'%Y-%m-%d::%H:%M')

#------------ choose the right colorbar ------------- #
if varname == 'temperature':
  cmap = "cmocean_thermal"
elif varname == 'salinity':
  cmap = "cmocean_haline"
  clev = [ 5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38]
elif varname == 'total_depth':
  cmap = "cmocean_deep"
elif varname == 'water_level':
  cmap = "cmocean_balance"
elif varname == 'velocity':
   cmap = "WhiteBlueGreenYellowRed"

if args.diff:
   cmap = "cmocean_deep"

#----------- close Netcdf reading ------------- #
fin.close()

#------------- simulation name --------------#
name_exp= args.name

#------------- yearly mean ------------ #
#ym = ['2010','2011','2012','2013','2014','2015','2016','2017','2018','2019']
ym=['mean']
#ym=['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC']

#------------------ time in UTC (maybe need to convert in local time) ----------------------#
tvalue = num2date(time,units=t_unit,calendar=t_cal)
str_time = [i.strftime("%Y-%m-%d::%H:%M") for i in tvalue]
#print(str_time)

############################### start plot procedures ##################
for i in range(len(tvalue)):

    tnow = datetime.strptime(str_time[i],"%Y-%m-%d::%H:%M")
    #print tnow
    ######################### check datatime ########################
    if tnow < tmin:
        continue
    elif tnow > tmax:
        break

    if args.last:
      #----------- extract the index of the variable at the bottom layer of each elements ---#
      v=pd.DataFrame(var[i].T).apply(pd.Series.last_valid_index) 
      vart=np.zeros(len(v),float)
      for ll in range(len(v)):
        vart[ll]=var[i,ll,v[ll]]
      print(var[i])
      print(vart)


    ##################### file names ###################
    wks_type='png'
    if i < 10:
        wks = Ngl.open_wks(wks_type,varname+'_00'+str(i))
    elif i < 100:
        wks = Ngl.open_wks(wks_type,varname+'_0'+str(i))
    elif i >= 100:
        wks = Ngl.open_wks(wks_type,varname+'_'+str(i))

    ########################## set background and Foreground colors ##############
    #back                            =Ngl.Resources()
    #back.wkForegroundColor          =(0.,0.,0.)
    #back.wkBackgroundColor          =(0.5,0.5,0.5)
    #Ngl.set_values(wks,back)

    ########################## set memory maximum #####################
    ws_id = Ngl.get_workspace_id()
    mem = Ngl.Resources()
    mem.wsMaximumSize   = 300000000
    Ngl.set_values(ws_id,mem)

    ##################### define colormap ###################
    Ngl.define_colormap(wks,cmap)

   ########################## set plot resources ###########
    res                             = Ngl.Resources()

    res.cnFillOn                    = True
    res.cnFillMode                  ='AreaFill'
    res.cnLinesOn                   =False
    if varname != 'salinity':
      res.cnLevelSelectionMode        ="ManualLevels"
      res.cnMinLevelValF              =minval
      res.cnMaxLevelValF              =maxval
      res.cnLevelSpacingF             =spacing
    else:
      res.cnLevelSelectionMode        ="ExplicitLevels"
      res.cnLevels                    = clev
    res.cnLineLabelsOn              = False     #turn off the line labels
    #res.cnLineLabelFontHeightF      = 0.005
    res.cnLineLabelDensityF         = 1
    res.cnLineLabelFontAspectF      = 1         #shape of the line label. > 1 :thinner characters. < 1 :wider
    res.cnLineLabelInterval         = 1
    res.cnInfoLabelOn               = False     #turn off "CONTOUR FROM X TO X BY X" legend.
    res.cnLabelMasking              = True      #mask lines where label appear
    res.cnConstFEnableFill          = True      #allow constant values (1=sig) to fill
    res.cnConstFLabelOn             = False
    res.cnSpanFillPalette           = True
    res.cnInfoLabelFontHeightF      = 18

    ################# map attributes #################
    res.mpFillOn              = True           #turn on gray fill for continental background
    res.mpFillDrawOrder       = "PreDraw"       #draw area fill first
    res.mpDataBaseVersion     = "HighRes"       #use GMT coastline
    res.mpOutlineBoundarySets = "AllBoundaries" #turn on country boundaries (all the boundaries database in use)
    res.mpOutlineOn           = True            #turn on continental outlines
    res.mpGeophysicalLineThicknessF = 1.0       #thickness of outlines
    res.mpGeophysicalLineColor= "Black"         #color of cont. outlines
    res.mpOutlineDrawOrder    = "Draw"          #draw continental outline last
    res.mpLandFillColor       = "gray"
    res.mpOceanFillColor      = "white"
    res.mpInlandWaterFillColor= "gray"

    ################# Map attributes (lat/lon grid lines) ############### 
    res.mpGridAndLimbOn       = False           #turn on lat/lon lines
    res.mpGridLineDashPattern = 2               #... with xxxx lines
    res.mpGridLineColor       = "black"         #color of the lines
    res.mpGridLatSpacingF     = 10              #space (in degree) between 2 lines
    res.mpGridLonSpacingF     = 10              #idem
    res.mpGridLineThicknessF  = 2.0             #thickness of the lines
    res.mpGridAndLimbDrawOrder= "PostDraw"      #draw lat/lon lines last
    res.mpLabelFontHeightF    = 0.005           #label font size

    ################# Map attributes (window) ########################
    res.mpLimitMode = "LatLon"    # Zoom in on the plot area.

    # complete domain
    res.mpMinLatF   =min(lat)-0.2  #minlat # 30.0 ;minLatF(0)
    res.mpMaxLatF   =max(lat)+0.2  #maxlat # 46.0
    res.mpMinLonF   =min(lon)-0.2  #minlon # -18.5
    res.mpMaxLonF   =max(lon)+0.2  #maxlon # 37.0 ;maxLonF(0)
    # Bellocchio
    #res.mpMinLatF   =44.49-0.02  #minlat # 30.0 ;minLatF(0)
    #res.mpMaxLatF   =44.71+0.02  #maxlat # 46.0
    #res.mpMinLonF   =12.22-0.02  #minlon # -18.5
    #res.mpMaxLonF   =12.37+0.02  #maxlon # 37.0 ;maxLonF(0)

    res.nglDraw         = False
    res.nglFrame        = False
    res.nglMaximize     = True
    res.nglSpreadColors = True
    res.nglPaperOrientation = "landscape"

    res.tiMainFont        = 0
    res.tiMainPosition    = "Center"
    res.tiMainFontHeightF = 0.012
    res.tiMainOffsetYF    = 0.0
#    res.tiMainString        = name_exp+" "+varname+" "+str_time[i]+" depth = "+str(dept[lev])+" m"
    res.tiMainString        = name_exp+" "+varname+" "+ym[i]+" depth = "+str(dept[lev])+" m"
    res.tiMainFontThicknessF=5.

    res.sfXArray            = lon
    res.sfYArray            = lat
#   res.sfDataArray         =var[i,:,lev]

    res.sfElementNodes  = el_in
    res.sfMissingValueV = 1.e20
    res.sfFirstNodeIndex    =1

    res.lbLabelBarOn       = True
    res.lbLabelsOn         = True
    res.lbOrientation       ='horizontal'
    res.lbTitleString      = varname+" ("+var_unit+")"
#    res.lbTitleString      = "Sea level"+" ("+var_unit+")"
    res.lbTitlePosition    = "Bottom"
    res.lbTitleOffsetF   = -0.1
    res.lbLabelFontHeightF = 0.015
    res.lbTitleFontHeightF = 0.015
    res.lbLabelAutoStride    = True
    res.pmLabelBarSide   = "Bottom"
    res.lbBoxEndCapStyle = "TriangleBothEnds"
#   res.pmLabelBarOrthogonalPosF=-0.03
#   res.pmLabelBarParallelPosF  =0.4

    ################################ make plot ############################
    if  varname == 'water_level':

        plot = Ngl.contour_map(wks,var[i][:]+0.177,res)
    else:
        if args.last:
          plot = Ngl.contour_map(wks,vart,res)
        else:
          plot = Ngl.contour_map(wks,var[i,:,lev],res)


    ###################### draw plot and change frame ##################
    Ngl.draw(plot.base)
    Ngl.frame(wks)
    Ngl.destroy(wks)

Ngl.end()

