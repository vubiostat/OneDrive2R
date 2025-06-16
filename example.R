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
  filename     <- basename(path)
  items        <- strsplit(dirname(path), "/")[[1]]
  path_len     <- length(items)
  # case: "path" is top-level filename
  if(path_len == 1 && items == '.')
  {
    items <- fp <- filename
  } else
  {
    fp <- do.call(file.path, as.list(c(items[-1], filename)))
    items <- items[1]
  }
  objs         <- shared(auth)
  top <- objs[[items]]

  if(is.null(top))
    stop(paste("Requested top level of path must be shared name. Check: `names(shared(auth))`"))

  # there must be a better way to set the root directory to a shared folder
  item <- ms_drive_item$new(auth$token, auth$tenant, top)
  if(path_len > 1) item <- item$get_item(fp)

  type <- tolower(tools::file_ext(filename))
  infile <- tempfile(fileext = paste0('.', type))
  on.exit(unlink(infile))  # This is the auto delete
  item$download(dest = infile)

  if(is.null(FUN))
  {
    FUN <- switch(type,
      xls =,
      xlsx = readxl::read_excel,
      csv = ifelse(use.readr, readr::read_delim, read.csv),
      rds = readRDS,
      rdata = load,
      NULL
    )
    if(is.null(FUN)) stop("UNHANDLED FILE EXTENSION")
  }
  FUN(infile, ...)
}
