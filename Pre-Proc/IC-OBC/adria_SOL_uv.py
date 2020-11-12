import numpy as np
import netCDF4 as nc
import os
import sys
from seaoverland import seaoverland

DATA_FILE = sys.argv[1]
DATA_VAR =["u","v"]
MASK_FILE = sys.argv[1]
MASK_VAR = "mask_rho"
ITERATIONS = 15
#DATA_FILE="prova.nc"

#os.system('cp '+ str(ORIG_FILE)+' '+str(DATA_FILE))

def computeSeaOverLand(dataFile, dataVarName, maskFile, maskVarName, iterations):
    """
    Open a dataset and apply SOL to a variable using the provided mask file/variable
    :param dataFile: the file containing the data to elaborate
    :param dataVarName: the name of the relevant variable within dataFile
    :param maskFile: the file containing the mask to use
    :param maskVarName: the name of the relevant mask variable within maskFile
    :param iterations: number of iteration of SOL to apply
    :return:
    """
    ds = nc.Dataset(filename=dataFile)
    dataVar = ds.variables[dataVarName]
    data = dataVar[:]
    ds = nc.Dataset(filename=maskFile)
    maskVar = ds.variables[maskVarName]
    mask = maskVar[:]
    # mask needs to be true if the underlie data needs to be hidden
    mask = mask[:] < 0.5  # we mask data for cells covering at least 50% of land
    mask = np.array(np.broadcast_to(mask, data.shape))  # apply mask to each layer of data
    data = np.ma.array(data=data, mask=mask)

    #print(type(data.mask))

    # flatten every non lat, lon dimension
    oldShape = data.shape
    flattenShape = (-1,) + oldShape[-2:]
    data = data.reshape(flattenShape)

    for layer in data:
        seaoverland(layer, iterations)

    # revert data to its dimensions
    data = data.reshape(oldShape)


    return data


if __name__ == '__main__':
    for var in DATA_VAR:
        data = computeSeaOverLand(DATA_FILE, var, MASK_FILE, MASK_VAR, ITERATIONS)

        # overwrite Netcdf data
        dset = nc.Dataset(DATA_FILE,'r+')
        dset[var][:] = data
        dset.close()
	

#    from matplotlib import pyplot as plt

#    plt.imshow(data[0], origin="bottom")
#    plt.show()
