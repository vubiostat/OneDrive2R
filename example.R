library(Microsoft365R)
library(readxl)

od <- get_business_onedrive(auth_type="device_code")

load_shared_dataframe <- function(od, path)
{
   items <- as.list(strsplit(path, "/")[[1]])
   shared_files <- od$do_operation("sharedWithMe", options=list(allowexternal="true"))
 
   objs <- lapply(shared_files$value, function(obj) obj$remoteItem)
   directory_depths <- items[-c(1, length(items))]

   matching_folder <- objs[[which(unlist(lapply(objs, function(obj) {
     if(is.null(obj$name)) {FALSE} else {obj$name %in% items[1]}
   })))]]
   
   result <- ms_drive_item$new(od$token, od$tenant, matching_folder)
   
   for (d in directory_depths) {
     result <- result$get_item(d)
   }
  
   type = "df"
  
   if(grepl(".rds", items[length(items)])) {
     type = "rds"
   }
   
   if(grepl(".RData", items[length(items)])) {
     type = "rdata"
   }
   
   if(grepl(".xlsx", items[length(items)])) {
     type = "xlsx"
   }
   
   if(grepl(".xls", items[length(items)])) {
     type = "xls"
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
   } else if(type == "xlsx") {
     infile <- paste0(tempfile(), ".xlsx")
     on.exit(unlink(infile))
     result <- result$download(dest=infile)
     result <- readxl::read_excel(infile)
   } else if(type == "xls") {
     infile <- paste0(tempfile(), ".xls")
     on.exit(unlink(infile))
     result <- result$download(dest=infile)
     result <- readxl::read_excel(infile)
   }
}
 
x <- load_shared_dataframe(od, 'my_shared_excel_file.rdata')

x
