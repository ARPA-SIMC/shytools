;========================================================================
;============== interpolate and rotate u and v on rho-grid ==============
;========================================================================

;path_in="/fs/scratch/mare_exp/jacopo/ADRIAROMS/cut_nc_2018/20180101/"
;f_subfx="20171231_adriaroms_his_2km.nc"
;f_tmp_uv="rot_vel.nc"

;=========================== read variable from the shell ===================
path_in=getenv("path_out")
f_subfx=getenv("f_ncl_in")
f_tmp_uv=getenv("f_uv_in")

;print (path_in)

fout=addfile(path_in+f_subfx,"r")

;========================= choose window ==================================
minlat=44.1
maxlat=45.4
minlon=12.
maxlon=13.

;========================= read variables from NetCDF =====================
u_in=fout->u
v_in=fout->v
angle=fout->angle
time=fout->ocean_time
lon_rho=fout->lon_rho
lat_rho=fout->lat_rho
lev=fout->s_rho
mask_rho=fout->mask_rho

ntime=dimsizes(time)
nz=dimsizes(lev)
nx_rho=dimsizes(lon_rho(0,:))
ny_rho=dimsizes(lat_rho(:,0))

;print ("nx_u= "+nx_u)
;print ("ny_u= "+ny_u)
;print ("nx_v= "+nx_v)
;print ("ny_v= "+ny_v)
;print ("nx_rho= "+nx_rho)
;print ("ny_rho= "+ny_rho)

;======================= extrapolate data to fill missing values =========
guess     = 1                ; use zonal means
is_cyclic = True             ; cyclic [global]
nscan     = 500             ; usually much less than this
eps       = 1.e-2            ; variable dependent
relc      = 0.6              ; relaxation coefficient
opt       = 0   

;poisson_grid_fill(u_in, is_cyclic, guess, nscan, eps, relc, opt)
;poisson_grid_fill(v_in, is_cyclic, guess, nscan, eps, relc, opt)

u_rho=new((/ntime,nz,ny_rho,nx_rho/),float,1.e37)
v_rho=new((/ntime,nz,ny_rho,nx_rho/),float,1.e37)

;========================= interpolate u data on rho-grid =============================	
do ix=0,nx_rho-2
	u_rho(:,:,0:ny_rho-1,ix)=(u_in(:,:,0:ny_rho-1,ix)+u_in(:,:,0:ny_rho-1,ix+1))/2
end do

;======================== interpolate v data on rho-grid =============================
do iy=0,ny_rho-2
	v_rho(:,:,iy,0:nx_rho-1)=(v_in(:,:,iy,0:nx_rho-1)+v_in(:,:,iy+1,0:nx_rho-1))/2
end do

u_out=new((/ntime,nz,ny_rho,nx_rho/),float,1.e37)
v_out=new((/ntime,nz,ny_rho,nx_rho/),float,1.e37)

;============================ write description for velocity variables ===========
u_out!0 = "ocean_time"
u_out!1 = "s_rho"
u_out!2 = "lat_rho"
u_out!3 = "lon_rho"
u_out@long_name = "u-momentum component"
u_out@units = "meter second-1"
u_out@field = "u-velocity, scalar, series"
u_out@_FillValue= 1.e37

v_out!0 = "ocean_time"
v_out!1 = "s_rho"
v_out!2 = "lat_rho"
v_out!3 = "lon_rho"
v_out@long_name = "v-momentum component"
v_out@units = "meter second-1"
v_out@field = "v-velocity, scalar, series"
v_out@_FillValue= 1.e37

;============================ rotate velocity data =================================
do it=0,ntime-1
	do iz=0,nz-1
		u_out(it,iz,0:ny_rho-1,0:nx_rho-1)=where(mask_rho(0:ny_rho-1,0:nx_rho-1) .eq. 1,tofloat(u_rho(it,iz,0:ny_rho-1,0:nx_rho-1)*cos(angle(0:ny_rho-1,0:nx_rho-1))-v_rho(it,iz,0:ny_rho-1,0:nx_rho-1)*sin(angle(0:ny_rho-1,0:nx_rho-1))),u_out@_FillValue)
		v_out(it,iz,0:ny_rho-1,0:nx_rho-1)=where(mask_rho(0:ny_rho-1,0:nx_rho-1) .eq. 1,tofloat(v_rho(it,iz,0:ny_rho-1,0:nx_rho-1)*cos(angle(0:ny_rho-1,0:nx_rho-1))+u_rho(it,iz,0:ny_rho-1,0:nx_rho-1)*sin(angle(0:ny_rho-1,0:nx_rho-1))),v_out@_FillValue)
	end do
end do

;print("u_max= "+max(u_out)+"   v_max= "+max(v_out))

;============================ put data on NetCDF ==================================
system("rm -f "+path_in+f_tmp_uv)
f_out=addfile(path_in+f_tmp_uv,"c")
f_out->u=u_out
f_out->v=v_out
f_out->lat_rho=lat_rho
f_out->lon_rho=lon_rho
f_out->s_rho=lev
f_out->ocean_time=time
f_out->mask_rho=mask_rho
