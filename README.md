# shytools
pre/post processing tools for SHYFEM-model

##  prerequisites
 The main routines of **pre-processing** are in *Bash* but they call *Ncl* and *Python3* external routines.  
 **Utility** and **post-processing** routines are in *Python3*  
 
| python packages required |
|--------------------------|
|Datetime                  |
|NetCDF4                   |
|argparse                  |
|Cmocean                   |
|Ngl                       |
|numpy                     |
|Sys                       |
|pandas                    | 
|matplotlib                |
|xarray                    |
|Math                      |
|

> **TO DO** make a virtual environment **shy_env** with all these packages.

## Structure
The directory are organized as follows:
 ```mermaid
 graph LR
 A[ShyTools] -->B[Pre-Proc]
 A --miscellaneous--> C[Utility]
 A --visualization --> D[Post-Proc] 
 B --meteo forcing--> E[SBC]
 B -- IC & open boundary--> F[IC-OBC]
 ```


## Pre-Processing

### 1.  Surface Boundary Conditions (SBC)   
the directory SBC contains procedure to generate SBC from
Cosmo2I model output.
  1. The main routine is **extrctc_frc.sh**  
   It downloads data from arkimet in a grib format (analysis or forecast) [**_download_cosmo_analysis.sh_** ; **_download_cosmo_forecast.sh_** ]
          Data are converted in NetCDF
          It can apply SeaOverLand procedure (not useful for small domains) 
           [ **_SOL_cosmo.py_** ; **_seaoverland.py_** ]
           rotates the wind vectors  [ **_rot_wnd_vel_SOL.ncl_** ]
          do some math and rename variables in a Shyfem fashion format
          
        **OUTPUT**:  *wp.dat* ; *tc.dat*

        - **wp.dat**: contains Wind components at 10 m (u,v) [m/s] and Pressure [Pa] in FEM shyfem format.
         - **tc.dat**: contains Air Temperature [°C or K], Dewpoint Temperature [°C or K], Total Cloud Cover [0-1].
            the first variable in *tc.dat* is indicated as *solar radiation* but is only a fictitious variable that is not used. <br>
These are the variable necessary to run shyfem using the MFS Bulk formulae for the parameterization of the air-sea interaction.

        **pre_proc_meteo.job** launch the routine on Maialinux:  
              here you decide initial and final dates and output folder

> **TO DO**: add a crop of the file in an intelligent way. update dates generation in a more simple way. complete restyling of the routines.
  2. the routine **_extrct_prcrpt.sh_** is used to generate precitpitation forcing in FEM shyfem format from COSMO-2I analysis. It should be revised  <br>
  **OUTPUT**:  *prc.fem*
      - **prc.fem**: contains precipitation [mm/day] in shyfem FEM format
     
      **pre_proc_piogia.job** launch the routine on Maialinux:  
      here you decide initial and final dates and output folder
### 2. Initial Conditions (IC) and Open Boundary Conditions (OBC)
   **INPUT**: list of open boundary nodes coordinate in counterclockwise direction

   Directory **IC-OBC** contains procedure for the generation of Initial and Boundary condtions. <br>
  1. The main routine is **_extrct_bnd.sh_**.
     It takes data from the local Maialinux archive of AdriaRoms (soon Adriac) and convert it into initial and boundary conditions in shyfem FEM format. 
      It needs an ASCII file with two columns where longitude and latitude are listed for each open boundary node counterclockwise.
      An example is provided in the file *lon_lat_bound.txt* for the GOLFEM domain.
       NetCDF data are cropped and current velocity componentes are rotated [ **_rotate_uv.ncl_** ]
       SeaOverLand procedure is applied to cover the domain between father model and the boundary. [ **_adria_SOL_uv.py_** ; **_adria_SOL_rho.py_** ; **_seaoverland.py_** ]
       This procedure is necessary to provide the initial conditions for the full domain and for open boundary nodes close to the land.  
  
  **OUTPUT**:  IC [ *boundin.fem* ; *tempin.fem* ; *saltin.fem* ; *uvin3d.fem* ] 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp; &nbsp;&nbsp; OBC [ *boundn.fem* ; *tempn.fem* ; *saltn.fem* ; *uv3d.fem* ]  
   -  **boundin.fem** : intial conditions for the sea level [m]
   - **tempin.fem** : intial conditions for the temperature [°C or K]
   - **saltin.fem** : intial conditions for the salinity [psu]
   - **uvin3d.fem** : intial conditions for the current velocity [m/s]

   - **boundn.fem** : boundary condition for the sea level [m]
  - **tempn.fem** : boundary condition for the temperature [°C or K]
   - **saltn.fem** : boundary condition for the Salinity [psu]
   - **uv3d.fem** : boundary condition for current velocity [m/s]
  
   **_pre_proc_mare.job_**: launch the routine on Maialinux: 
    here you decide initial and final dates and output folder
>**TO DO**: remove the hardcoded crop. (instead use CDO sellonlatbox???? providing lat lon limits from outside). Update dates generation in simpler way. Complete restyling of the routines.

## Post-Processing
The directory **_Post-Proc_** contains some *Python3* tool for the visualization of unstructured and regular shyfem NetCDF output.

1. Visualization of Unstructured NetCDF shyfem file for Temperature, Salinity and Sea level.
   **_ShyNCplot.py_**
   You can invoke help and see all the options with: 
   > python3 ShyNCplot.py -h

2. Visualization of Regular NetCDF shyfem file for Temperature, Salinity, Sea level and current velocity.
   **_ShyRegPlot.py_**
   You can invoke help and see all the option with: 
      > python3 ShyRegPlot.py -h

3) Visualization of a time series in Shyfem format.
   "PlotTS.py"  **!! there is something to adjust here**
   you can use it with the following command: 
   > python3 plotTS.py tsfile.txt  
   
   where *tsfile.txt* is an ASCII file with two columns and *nt* rows with the format:
   | dates      | values |
   |-----------|---------|
   |%Y-%m-%d::%H:%M:%S | value|   

## Utility

 This is a miscellaneus of tools for multiple purpose.

1) extract time series from the NetCDF unstructured file from the node closer to the indicated coordinates and write it in the shyfem time series format. (see above).
values can be on multiple column. Each column is the value of the variable in the vertical layers starting from the surface layers.
   **_extract_node_ts.py_**
   You can invoke help and see all the option with 
   > python3 extract_node_ts.py  -h

2) read the inf file (it contains stability information and volume integrated variables) and plot
   basin average Temperature, Salinity and volume
   **_inf2ts.py_**
   Tu use this you need the .inf file (an optional output shyfem file)
   usage:
   > python3 inf2ts.py outfile.inf 




