#!/bin/sh
cd ${0%/*} || exit 1  

#########################################################################################
# LESrun.sh
#
# Mark Sutherland
# December 18, 2014
#
# Script to run the cleaning, meshing, mapping, and running of the LES case 
#########################################################################################

#Run the LES meshing section which includes directory clean up
if [ $DOLES_MESH -eq 1 ]; then
  #Clean up the logs from last run if you need to do a full restart
  rm -rf logs 
  rm -rf constant/polyMesh
  rm -rf constant/triSurface
  rm -r 0
  rm -r 0.org
  rm -rf processor* 										
  rm -rf constant/extendedFeatureEdgeMesh 							
  rm -rf system/mapFieldsDict
  rm -rf postProcessing/forceCoeffs
  rm -rf postProcessing/forces
  echo "----------Cleaned Last Run----------\n"
  sleep 1  

  #Copy files from Setup folder
  mkdir logs
  mkdir 0
  mkdir ./constant/triSurface
  cp -r polyMesh.org constant/polyMesh
  cp ../Setup/*.stl ./constant/triSurface
  cp ../Setup/surfaceFeatureExtractDict ./system
  cp ../Setup/snappyHexMeshDict ./system
  cp -r ../Setup/0.org_LES ./0.org  
  cp -r polyMesh.org constant/polyMesh
  cp ../Setup/mapFieldsDict ./system
  cp ../Setup/controlDict_LES ./system/controlDict 
  cp ../Setup/decomposeParDict.ptscotch ./system/decomposeParDict.ptscotch
  cp ../Setup/decomposeParDict.scotch ./system/decomposeParDict.scotch

  #Run blockMesh to make general background mesh 
  blockMesh | tee log_blockMesh
  mv -i log_blockMesh logs
  echo "----------blockMesh Done----------\n"
  sleep 1

  #Move the blockMesh around to center it about the .stl body if needed
  transformPoints -translate '(0 0 0)' | tee log_transformPoints
  mv -i log_transformPoints logs
  sleep 1

  #This is very important, it extracts the edges of the stl file to allow sHM to snap to them
  surfaceFeatureExtract | tee log_surfaceFeatureExtract
  mv -i log_surfaceFeatureExtract logs
  sleep 1

  #We need to copy over some files to allow for auto processor splitting
  cp system/decomposeParDict.scotch system/decomposeParDict

  #Lets breakup the domain to allow for parallel processing
  decomposePar | tee log_decomposePar
  mv -i log_decomposePar logs
  echo "----------decomposePar Done----------\n"
  sleep 1

  #Again copy come files over, difference bettwen scotch and ptscotch
  cp system/decomposeParDict.ptscotch system/decomposeParDict

  #Now the actual fun part, lets run sHM to carve out our stl from the blockMesh
  mpirun -np $CORENUM snappyHexMesh -overwrite -parallel | tee log_snappyHexMesh
  mv -i log_snappyHexMesh logs
  echo "----------snappyHexMesh Done----------\n"
  sleep 2

  # For parallel running
  ls -d processor* | xargs -i rm -rf ./{}/0 $1
  ls -d processor* | xargs -i cp -r 0.org/ ./{}/0/ $1

  #Run renumberMesh to clean a few things up
  mpirun -np $CORENUM renumberMesh -parallel -overwrite -latestTime | tee log_renumberMesh
  mv -i log_renumberMesh logs
  echo "----------renumberMesh Done----------\n"

  #Run checkMesh to ensure accetable quality mesh
  mpirun -np $CORENUM checkMesh -parallel -latestTime | tee log_checkMesh
  mv -i log_checkMesh logs
  echo "----------checkMesh Done----------\n"
  sleep 1

  #Run patchSummary to check all boundary patches are correct
  mpirun -np $CORENUM patchSummary -parallel -latestTime | tee log_patchSummary
  mv -i log_patchSummary logs
  echo "----------patchSummary Done----------\n"
  sleep 1
fi

#Map the final RANS results as the intial conditions and run the LES solver. Only a log file is 
#generated for the pisoFoam case. Follow the simulation with tail -f log_simpleFoam and 
#ctl+C to stop following
if [ $DOLES -eq 1 ]; then 
  mapFields ../RANS_run -consistent -sourceTime 'latestTime' -parallelTarget  > log_mapFields & 
  PID4=$!        
  wait $PID4
  mv -i log_mapFields logs
   
  #Run LES!
  mpirun -np $CORENUM pisoFoam -parallel > log_pisoFoam & 
  PID1=$!       #Save the process PID number
  wait $PID1    #Wait for this PID to finish
  mv -i log_pisoFoam logs
fi

#Reconstruct the mesh and any new parallel simulation results if flag is true.
if [ $RECON -eq 1 ]; then
  reconstructParMesh -mergeTol 1e-06 -constant | tee log_reconstructParMesh
  PID2=$!
  wait $PID2
  mv -i log_reconstructParMesh logs
  
  reconstructPar -newTimes | tee log_reconstructPar
  PID3=$!
  wait $PID3
  mv -i log_reconstructPar logs
  echo "----------reconstructPar Done----------\n"
fi
