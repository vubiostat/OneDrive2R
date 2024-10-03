library(Microsoft365R)
library(readxl)

od <- get_business_onedrive(auth_type="device_code")
 
load_shared_dataframe <- function(od, path)
{
   items <- as.list(strsplit(path, "/")[[1]])
   shared_files <- od$do_operation("sharedWithMe", options=list(allowexternal="true"))
 
   objs <- lapply(shared_files$value, function(obj) obj$remoteItem)
   directory_depths <- items[-c(1, length(items))]

   matching_folder <- objs[[which(unlist(lapply(objs, function(obj) obj$name %in% items[1])))]]
   
   result <- ms_drive_item$new(od$token, od$tenant, matching_folder)
   
   for (d in directory_depths) {
     result <- result$get_item(d)
   }
  
   type = "df"
  
   if(grepl("rds", items[length(items)])) {
     type = "rds"
   }
   
   if(grepl("RData", items[length(items)])) {
     type = "rdata"
   }
   
   if(type == "df") {
     if(length(directory_depths) > 0) {
       result <- result$get_item(items[length(items)])$load_dataframe()
     } else {
       result <- result$load_dataframe()
     }
   } else if(type == "rds") {
     if(length(directory_depths) > 0) {
       result <- result$get_item(items[length(items)])$load_rds()
     } else {
       result <- result$load_rds()
     }
   } else if(type == "rdata") {
     if(length(directory_depths) > 0) {
       result <- result$get_item(items[length(items)])$load_rdata()
     } else {
       result <- result$load_rdata()
     }
   }
}
 
x <- load_shared_dataframe(od, 'parentfolder/subfolder/item.csv')

x
