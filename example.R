library(Microsoft365R)
 
od <- get_business_onedrive(auth_type="device_code")
 
load_shared_dataframe <- function(od, path)
{
   items <- as.list(strsplit(path, "/")[[1]])
   shared_files <- od$do_operation("sharedWithMe", options=list(allowexternal="true"))
 
   objs <- lapply(shared_files$value, function(obj) obj$remoteItem)
  
   matching_folder <- objs[[which(unlist(lapply(objs, function(obj) obj$name %in% items[1])))]]
  
   directory_depths <- items[-c(1, length(items))]
  
   result <- ms_drive_item$new(od$token, od$tenant, matching_folder)
 
   for (d in directory_depths) {
     result <- result$get_item(d)
   }
  
   type = "df"
  
   if("rds" %in% items[length(items)]) {
     type = "rds"
   }
 
   if(type == "df") {
     result <- result$get_item(items[length(items)])$load_dataframe()
   } else if(type == "rds") {
     result <- result$get_item(items[length(items)])$load_rds()
   } else if(type == "rdata") {
     result <- result$get_item(items[length(items)])$load_rdata()
   }
}
 
x <- load_shared_dataframe(od, 'parentfolder/subfolder/item.csv')
x
