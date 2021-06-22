#!/lhome/mare_exp/anaconda3/envs/shypy/bin/python                                               

#------------------------------------------------------------
#---- read, make difference and plot unstructured data ------
#------------------------------------------------------------

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
parser = argparse.ArgumentParser(description='plot differences of unstructured Netcdf file')

#------- add argument for the parser -------------
parser.add_argument('-i1','--inp1',type=str, help='input NetCDF file')
parser.add_argument('-i2','--inp2',type=str, help='input NetCDF file')
parser.add_argument('-tmin',type=str, help='starting time Format: Y-m-d::H:M')
parser.add_argument('-tmax',type=str, help='end time Format: Y-m-d::H:M')
parser.add_argument('-var',type=str,help='variable name')
parser.add_argument('-name',type=str,help='title of the plot',default=None)
parser.add_argument('-l','--layer',type=int,help='choose the layer to plot',default=0)
parser.add_argument('-minv',type=float, help='choose minimum value to display')
parser.add_argument('-maxv',type=float, help='choose maximum value to display')
parser.add_argument('-spac',type=float, help='choose the spacing for the plot isolines')
parser.add_argument('-last',action='store_true', help='plot variable in last layer of each element')
parser.add_argument('-V','--version',action='version',help='print the version',version='shyNCdiff 1.1 (unstructured)')

#--------- collect info from command line ---------------#
args=parser.parse_args()

#-------- read Netcdf-1 file -------------#
fname = args.inp1
fin = Dataset(fname, mode='r')

#-------- read Netcdf-2 file -------------#
fname2 = args.inp2
fin2 = Dataset(fname2, mode='r')

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

# read variables and make difference ----------#
if varname == 'velocity':
  #--------- file 1 -------------------#
  var1_u = fin.variables['u_velocity'][:]
  var1_v = fin.variables['v_velocity'][:]
  var1 = np.sqrt(var1_u**2+var1_v**2)
  #-------- 0 values to nan -----------#
  var1 = np.where(var1 == 0,np.nan,var1)
  #--------- file 2 -------------------#  
  var2_u = fin2.variables['u_velocity'][:]
  var2_v = fin2.variables['v_velocity'][:]
  var2 = np.sqrt(var2_u**2+var2_v**2)
  #-------- 0 values to nan -----------#
  var2 = np.where(var2 == 0,np.nan,var2)
  #-------- final var ----------------#
  var = var1-var2
  #------------ variable units -------------#
  var_unit = fin.variables['u_velocity'].units
else:
  #-------- var 1 --------------------#
  var1 = fin.variables[varname][:]
  #-------- 0 values to nan -----------#
  var1 = np.where(var1 == 0,np.nan,var1)
  #------------ var 2 ----------------#
  var2 = fin2.variables[varname][:]
  #-------- 0 values to nan -----------#
  var2 = np.where(var2 == 0,np.nan,var2)
  #------- final var ------------------#
  var = var1-var2
  #------------ variable units -------------#
  var_unit = fin.variables[varname].units

#-------- change Nan values if necessary ---------#
if not args.last:
  np.nan_to_num(var,copy=False,nan=1.e20)

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
cmap = "cmocean_balance"

#----------- close Netcdf reading ------------- #
fin.close()

#------------- simulation name --------------#
name_exp= args.name

#------------- yearly mean ------------ #
#ym = ['2010','2011','2012','2013','2014','2015','2016','2017','2018','2019']
#ym=['mean']
ym=['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC']

#------------------ time in UTC (maybe need to convert in local time) ----------------------#
tvalue = num2date(time,units=t_unit,calendar=t_cal)
str_time = [i.strftime("%Y-%m-%d::%H:%M") for i in tvalue]
#print(str_time)

# ------- compute root mean square error time series #
rmse = np.zeros(len(tvalue),float)
rmse = np.sqrt(np.sum(var**2,axis=1)/(len(var[0,:])))
print(rmse)

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

    ##################### file names ###################
    wks_type='png'
    if i < 10:
        wks = Ngl.open_wks(wks_type,name_exp+"_"+varname+'_00'+str(i))
    elif i < 100:
        wks = Ngl.open_wks(wks_type,name_exp+"_"+varname+'_0'+str(i))
    elif i >= 100:
        wks = Ngl.open_wks(wks_type,name_exp+"_"+varname+'_'+str(i))

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
    res.cnLevelSelectionMode        ="ManualLevels"
    #res.cnLevelSelectionMode        ="AutomaticLevels"
    res.cnMinLevelValF              =minval
    res.cnMaxLevelValF              =maxval
    res.cnLevelSpacingF             =spacing
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
    if not args.last:
      res.tiMainString        = name_exp+" "+varname+" difference "+str_time[i]+" depth = "+str(dept[lev])+" m"
      # res.tiMainString        = name_exp+" "+varname+" difference "+ym[i]+" depth = "+str(dept[lev])+" m" 
    else:
      res.tiMainString        = name_exp+" "+varname+" difference "+str_time[i]+" bottom"
      # res.tiMainString        = name_exp+" "+varname+" difference "+ym[i]+" bottom"
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
    res.lbAutoManage	   = False
    res.lbTitleString      = varname+" difference ("+var_unit+")"
    res.lbTitlePosition    = "Bottom"
    res.lbTitleOffsetF   = -0.1
    res.lbLabelFontHeightF = 0.015
    res.lbTitleFontHeightF = 0.015
#    res.lbLabelFontHeightF = 0.008
#    res.lbTitleFontHeightF = 0.008
    res.lbLabelAutoStride    = True
    res.pmLabelBarSide   = "Bottom"
    res.lbBoxEndCapStyle = "TriangleBothEnds"
#   res.pmLabelBarOrthogonalPosF=-0.03
#   res.pmLabelBarParallelPosF  =0.4

    ################################ make plot ############################
    if  varname == 'water_level':

        plot = Ngl.contour_map(wks,var[i][:],res)
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

