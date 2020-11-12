;============================================================================================
;================ rotate wind velocity and mask all the varialbes ===========================
;============================================================================================

;===================== read variables from shell =================
path=getenv("path_out")
f_subfx=getenv("f_ncl_in")

fout=addfile(path+f_subfx,"w")

;==================== read variables from NetCDF ===============
U=fout->U10M
V=fout->V10M
angle=fout->g10_rot_3
lat=fout->lat
lon=fout->lon
time=fout->time

ntime=dimsizes(time)
nx=dimsizes(lon(0,:))
ny=dimsizes(lat(:,0))

U_out=new((/ntime,ny,nx/),float,1.e20)
V_out=new((/ntime,ny,nx/),float,1.e20)

;===================== rotate wind velocity variables ===============
do it=0,ntime-1
	U_out(it,0:ny-1,0:nx-1)=sin(angle(0:ny-1,0:nx-1))*V(it,0:ny-1,0:nx-1)+cos(angle(0:ny-1,0:nx-1))*U(it,0:ny-1,0:nx-1)
	V_out(it,0:ny-1,0:nx-1)=cos(angle(0:ny-1,0:nx-1))*V(it,0:ny-1,0:nx-1)-sin(angle(0:ny-1,0:nx-1))*U(it,0:ny-1,0:nx-1)
end do

copy_VarMeta(U,U_out)
copy_VarMeta(V,V_out)

;==================== write data on netcdf ======================
fout->U10M=U_out
fout->V10M=V_out



