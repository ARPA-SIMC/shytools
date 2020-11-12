# shytools
pre/post processing tools for SHYFEM-model

################################################################################
##################### PRE-PROCESSING ########################################### 
################################################################################
The directory "Pre-Proc" contains procedures to generate shyfem 
Surface Boundary Condition (SBC) and Open Boundary Conditions (OBC)

	1) Surface Boundary Conditions (SBC)

           the directory SBC contains procedure to generate SBC from 
	   Cosmo2I model output.

           1.1)
	      The main routine is "extrctc_frc.sh".
	      It downloads data from arkimet in a grib format (analysis or forecast) [ download_cosmo_analysis.sh ; download_cosmo_forecast.sh ]
	      Data are converted in NetCDF 
	      It can apply SeaOverLand procedure (not useful for small domains) [ SOL_cosmo.py ; seaoverland.py ]
              rotates the wind vectors  [ rot_wnd_vel_SOL.ncl ]	
	      do some math and rename variables in a Shyfem fashion format 

	      OUTPUT: wp.dat ; tc.dat 

	            "wp.dat": contains Wind components at 10 m (u,v) [m/s] and Pressure [Pa] in FEM shyfem format
	            "tc.dat": contains Air Temperature [°C or K], Dewpoint Temperature [°C or K], Total Cloud Cover [0-1]
	                     the first variable in "tc.dat" is indicated as "solar radiation" but is only a fictitious variable that is not used

		    These are the variable necessary to run shyfem using the MFS Bulk formulae for the parameterization of the air-sea interaction

              "pre_proc_meteo.job" launch the routine on Maialinux: here you decide initial and final dates and output folder        
	
	      TO DO: add a crop of the file in an intelligent way. update dates generation in a more simple way.	
		

	  1.2) 
	      the routine "extrct_prcrpt.sh" is used to generate precitpitation forcing in FEM shyfem format from COSMO2I analysis.
	      It should be revised
	      
  	      OUTPUT: prc.fem
		     
 		       "prc.fem": contains precipitation [mm/day] in shyfem FEM formato

	      "pre_proc_piogia.job" launch the routine on Maialinux: here you decide initial and final dates and output folder
	
	2) Initial Conditions (IC) and Open Boundary Conditions (OBC) 

	   INPUT: list of open boundary node coordinate in counterclockwise
	
           Directory IC-OBC contains procedure for Initial and Boundary condtions
	   Takes data from the local Maialinux archive of AdriaRoms (soon Adriac) and convert data in IC and boundary conditions
	   shyfem FEM format. The main routine is "extrct_bnd.sh".
	   It needs an ASCII file with two columns where longitude and latitude are listed for each open boundary node counterclockwise.
	   An example is provided in the file "lon_lat_bound.txt" for the GOLFEM domain.
	   NetCDF data are cropped and current velocity componentes are rotated [ rotate_uv.ncl ]
	   SeaOverLand procedure is applied to cover the domain between father model and the boundary. [ adria_SOL_uv.py ; adria_SOL_rho.py ; seaoverland.py ]
	   This procedure is necessary to provide the Initial Conditions for the full domain and for Open boundary nodes close to the land.
 
	   OUTPUT: IC [ boundin.fem ; tempin.fem ; saltin.fem ; uvin3d.fem ]
		  OBC [ boundn.fem ; tempn.fem ; saltn.fem ; uv3d.fem ]

		  "boundin.fem": intial conditions for the sea level [m]
		  "tempin.fem" : intial conditions for the temperature [°C or K]
		  "tempin.fem" : intial conditions for the salinity [psu]
		  "uvin3d.fem" : intial conditions for the current velocity [m/s]

		  "boundn.fem": boundary condition for the sea level [m]
		  "tempn.fem": boundary condition for the temperature [°C or K]
		  "saltn.fem": boundary condition for the Salinity [psu]
		  "uv3d.fem": boundary condition for current velocity [m/s]
	
	   "pre_proc_mare.job": launch the routine on Maialinux: here you decide initial and final dates and output folder

	   TO DO: remove the hardcoded crop. (instead use CDO sellonlatbox???? providing lat lon limits from outside). Update dates generation in simpler way

=========== the parts described below uses python3 =====================

Python packages needed:
================================
Datetime
NetCDF4
argparse
cmocean
Ngl
Numpy
sys
pandas
matplotlib
xarray
Math
================================

I think the best way is to make a virtual environemnt named "shy_env"


#######################################################################
################## POST-PROCESSING ####################################
#######################################################################

The directory "Post-Proc" contains some Python tool for the visualization of unstructured and regular shyfem NetCDF output

1) Visualization of Unstructured NetCDF shyfem file for Temperature, Salinity and Sea level.
   "ShyNCplot.py" 
   You can invoke help with "python3 ShyNCplot.py -h"

2) Visualization of Regular NetCDF shyfem file for Temperature, Salinity, Sea level and current velocity.
   "ShyRegPlot.py"
   You can invoke help with "python3 ShyRegPlot.py -h"

3) Visualization of a time series in Shyfem format.
   "PlotTS.py" !! there is something to adjust
   you can use it doing "python3 plotTS.py tsfile.txt"
   where "tsfile.txt" has the format:
==========================================
	%Y-%m-%d::%H:%M:%S value
	%Y-%m-%d::%H:%M:%S value
	%Y-%m-%d::%H:%M:%S value
	.
	.
	.
==========================================   

#######################################################################
###################### Utility ########################################
#######################################################################

This is a miscellaneus of tools for multiple purpose.

1) extract time series from the NetCDF unstructured file from the node closer to the indicated coordinates
   and write it in the shyfem time series format. (see above).
   values can be on multiple column. Each column is the value of the variable in the different layers
   "extract_node_ts.py"
   You can invoke help with "python3 extract_node_ts.py -h"

2) read the inf file (it contains stability information and volume integrated variables) and plot 
   basin average Temperature, Salinity and volume 
   "inf2ts.py"
