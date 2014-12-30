import csv
import os
import natsort
from os import listdir
from os.path import isfile, join

#########################################################################################
# extractData.py
#
# Mark Sutherland
# December 18, 2014
#
# Simple script to take the unprocessed .csv files from OpenFOAM/Paraview and trim them
# both in space and time. The spatial trimming is performed as a simple box by specifying
# the lower and upper bounds for x,y, and z. The temporal trimming is used for 
# implementing the desired loop interval by specifying the start and end times. 

#Ensure the exact selected times exsists, based on timestep save resolution. Also ensure 
#the only saved varaibles in the .csv files are p,Ux,Uy,Uz,x,y,z and in that exact order.  

fileName = "-----"          #.csv file names e.g. "730_6_0_1_"
dirPath = "csvFiles"        #Enter the directory where the csv files are 

LES_simWriteInterval=0.05   #Save interval of CFD simulation 
newStartTime=20.2           #Loop interval start time
LES_EndTime=28.9            #Loop interval end time	

lower_x_bound = -6          #Define the box to keep the wind data. Usually taken 0.5m
upper_x_bound = 24.5        #inward of the wake refinment to ensure good wind data 		
lower_y_bound = -6	
upper_y_bound = 6		
lower_z_bound = 0		
upper_z_bound = 21.5
#########################################################################################

#Setup the header of the csv file/database tables
newHeader = []
newHeader.append('p')
newHeader.append('Ux')
newHeader.append('Uy')
newHeader.append('Uz')
newHeader.append('x')
newHeader.append('y')
newHeader.append('z')

#Find the file numbers for the start and end loop inverval
timeStep=0
cutPoint =newStartTime/LES_simWriteInterval
lastTimeStep=LES_EndTime/LES_simWriteInterval
float(cutPoint)
float(lastTimeStep)

#Count the number of .csv files in the folder
onlyFiles = [f for f in listdir(dirPath) if isfile(join(dirPath, f))]
onlyFiles=natsort.natsorted(onlyFiles)

#Loop over all csv files for spatial and temportal trimming
for currentFile in onlyFiles:
    #print "Working on "+currentFile     #Debug message
    timeStep = currentFile.partition('.')[-1].rpartition('.')[0]
    inFilePath=dirPath + "/" + currentFile   
    
    #Keep the file if in loop interval range and keep velocity data
    #if in the defined box region
    if float(timeStep) >= cutPoint and float(timeStep) <= lastTimeStep:      
      inFile = open(inFilePath, "rb")
      reader = csv.reader(inFile)
      outFile = open(dirPath + "/" + fileName + timeStep + ".csv", "wb")
      writer = csv.writer(outFile)    
      rownum = 0
      for row in reader:
	if rownum == 0:
            row = newHeader
            writer.writerow(row)
           #print ', '.jioin(row)     #Debug message
        else:
            if (float(row[4]) >= lower_x_bound and float(row[4]) <= upper_x_bound) and \
            (float(row[5]) >= lower_y_bound and float(row[5]) <= upper_y_bound) and \
            (float(row[6]) >= lower_z_bound and float(row[6]) <= upper_z_bound):
               writer.writerow(row)
           #    print ', '.join(row)     #Debug message
        rownum += 1
      inFile.close()
      outFile.close()       
    os.system("rm %s"%inFilePath)  

#Recount the number of .csv files after temportal trimming 
numFiles= [f for f in listdir(dirPath) if isfile(join(dirPath, f))]
numFiles=natsort.natsorted(numFiles)

#Renumber the remaining .csv files starting at one 
count=1
for currentFile in numFiles:  
  os.rename(dirPath + "/"+currentFile,dirPath + "/"+fileName+str(count)+".csv") 
  count=count+1   

#Script end message 
print "Exraction Finished"
