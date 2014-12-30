#!/bin/bash

#########################################################################################
# csvImport.sh
#
# Mark Sutherland
# December 18, 2014
#
# Simple script to take the processed .csv files from the trimming script and upload 
# them to a MySQL database. The database must exist on the prior to upload and script
# must be run locally on the server. 

#Ensure the variables below are filled.

#Define database connectivity
_db="-----"            #Enter database name
_db_user="-----"       #Enter user name
_db_password="-----"   #Enter password

#Define directory containing CSV files
_csv_directory="./csvFiles"    #Enter the directory where the csv files are
_csv_BaseName="-----"          #Enter csv base name, e.g. _csv_BaseName="730_6_0_1_*.csv"
#########################################################################################

#Go into directory
cd $_csv_directory

#Get a list of CSV files in directory
_csv_files=`ls -1 $_csv_BaseName`

#Loop through csv files
for _csv_file in ${_csv_files[@]}
do
    
  #Remove file extension
  _csv_file_extensionless=`echo $_csv_file | sed 's/\(.*\)\..*/\1/'`
  
  #Define table name
  _table_name="${_csv_file_extensionless}"
  
  #Make new table if it does not exist 	
    #Note: Not the best way to do this, the previous method tried to loop over the actual 
    #headings in the file. Too much of pain, just change the variable and type if needed 	
	
  mysql -u $_db_user -p$_db_password $_db << eof
   CREATE TABLE IF NOT EXISTS \`$_table_name\` (
     p FLOAT, Ux FLOAT, Uy FLOAT, Uz FLOAT, x FLOAT, y FLOAT, z FLOAT	
    ) ENGINE=MyISAM DEFAULT CHARSET=latin1 
eof
  
 #Import csv into mysql
  mysqlimport --fields-enclosed-by='"' --fields-terminated-by=',' --ignore-lines=1 --local -u $_db_user -p$_db_password $_db $_csv_file
   
done
exit
