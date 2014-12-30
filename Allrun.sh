#!/bin/sh
cd ${0%/*} || exit 1 

#########################################################################################
# Allrun.sh
#
# Mark Sutherland
# December 18, 2014
#
# Overarching script to run a standard OpenFOAM LES. Will run a parallel
# steady k-w SST RANS CFD simulation, map the final results, and run a parallel
# large-eddy CFD simulation. 

#Ensure variables below are set, the standard working directory files are present, such
#as the geometry .stl file, and all variables in Setup/caseSetup are set. 

CORENUM=16        #Number of parallel cores (must be local, non-network)
DORANS_MESH=1     #Do the RANS case meshing
DORANS=1          #Run the potential and k-e sims after meshing
DOMAP=1           #Reconstruct the RANS results and map after LES meshing 
DOLES_MESH=1	  #Do the LES case meshing
DOLES=1           #Run the LES sim after meshing and mapping
RECON=0           #Reconstruct LES results (not required for .csv generation)
#########################################################################################

#Export the variables so the RANS and LES run scripts can use them 
export CORENUM DORANS_MESH DORANS DOMAP DOLES_MESH DOLES RECON

#Do the RANS steady-state case
cd RANS_run
chmod +x RANSrun
./RANSrun
cd ..

#Do the LES case
cd LES_run
chmod +x LESrun
./LESrun
cd ..
