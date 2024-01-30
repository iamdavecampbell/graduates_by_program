Produce a shiny app to explore the number of graduates from baccalaureate programs from what Macleans lists as the top 15 Canadian universities from comprehensive and medical doctoral schools.  The number of graduates are split into categories using a hierarchical system.

File **0_data_prep_script.R** handles data download and pre-processing.  Data will be downloaded into (and later sourced from) a directory called **filecache**.
Data is publically available via [StatCan](https://www.statcan.gc.ca/en/statistical-programs/instrument/5017_Q1_V8) and updated annually in summer, so use the script to acquire the latest dataset.

The data prep file manipulates the 6.2GB stat can file and filters it down to ~ 7MB.   

View a working version of [the app](http://rshiny.math.carleton.ca:3838/users/davecampbell/graduates_by_program/)
