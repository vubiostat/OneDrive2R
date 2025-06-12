library(Microsoft365R)
library(readxl)

# Example authentication
# auth <- get_business_onedrive(auth_type="device_code")

shared <- function(auth)
{
  shared_objs <- auth$do_operation("sharedWithMe",
                                    options=list(allowexternal="true"))
  objs <- lapply(shared_objs$value, function(obj) obj$remoteItem)
  names(objs)  <- sapply(objs, function(o) o$name)

  objs
}

one_drive_2_R <- function(auth, path, use.readr=FALSE, FUN=NULL, ...)
{
  items        <- strsplit(path, "/")[[1]]
  subdirs      <- items[-c(1, length(items))]
  objs         <- shared(auth)
  filename     <- items[length(items)]

  if(is.null(objs[[items[1]]]))
    stop(paste("Requested top level of path must be shared name. Check: `names(shared(auth))`"))

  item <- ms_drive_item$new(auth$token, auth$tenant, objs[[items[1]]])

  # Go down any sub directories
  for (d in subdirs) item <- item$get_item(d)
  # If the length of items is greater than 1, still need to get the final item
  if(length(items) > 1) item <- item$get_item(filename)

  type <- if(grepl(".rds$",   filename)) "rds"   else
          if(grepl(".RData$", filename)) "rdata" else
          if(grepl(".xlsx$",  filename)) "xlsx"  else
          if(grepl(".xls$",   filename)) "xls"   else
                                         "df"

  if(grepl(".csv$", filename) && !use.readr) type <- "csv"

  # Do the final load and return result
  if(is.null(FUN) && type == "df")    item$load_dataframe(...) else
  if(is.null(FUN) && type == "rds")   item$load_rds()          else
  if(is.null(FUN) && type == "rdata") item$load_rdata()        else
  {
    # Microsoft365R does not handle these data types
    # Unfortunately must download.
    # Utilize a tmp file that is immediately deleted.
    infile <- paste0(tempfile(), type)
    on.exit(unlink(infile))  # This is the auto delete
    item$download(dest=infile)

    if(!is.null(FUN))                   FUN(infile, ...)                else
    if(type == "xlsx" || type == "xls") readxl::read_excel(infile, ...) else
    if(type == "csv")                   read.csv(infile, ...)           else
    stop("UNHANDLED FILE EXTENSION")
  }
}
