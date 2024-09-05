# OneDrive2R

Load data directly from OneDrive to R

_Why would I want to do this when OneDrive copies data locally?_

Having confidential data containing PHI/PII on a portable computing device is a huge risk. OneDrive by default maps data to the local drive. OneDrive at our institution is approved for storing PHI/PII, so it makes sense to have an R script to just load shared data directly into memory.

The attached R script is example code to do just that. Read directly form OneDrive and load data into memory _without_ writing to disk what could potentially be sensitive and preferred not to be stored. 
