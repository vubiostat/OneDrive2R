library(Microsoft365R)
library(readxl)
library(foreign)

# Example authentication
# drive <- get_business_onedrive(drive_type="device_code")

shared <- function(drive)
{
  shared_objs <- drive$do_operation("sharedWithMe",
                                    options=list(allowexternal="true"))
  objs <- lapply(shared_objs$value, function(obj) obj$remoteItem)
  names(objs)  <- sapply(objs, function(o) o$name)

  objs
}

one_drive_2_R <- function(drive, path, FUN=NULL, ...)
{
  filename <- basename(path)
  items    <- strsplit(dirname(path), "/")[[1]]
  objs     <- shared(drive)
  top      <- objs[[items[1]]]

  if(is.null(top)) stop(paste("Requested top level of path must be shared name. Check: `names(shared(drive))`"))
  # There _should_ be a better way than calling new, but alas
  item     <- ms_drive_item$new(drive$token, drive$tenant, top)
  if(length(items) > 1)
  {
      fp     <- do.call(file.path, as.list(c(items[-1], filename)))
      item   <- item$get_item(fp)
  }

  type <- tolower(tools::file_ext(filename))
  if(is.null(FUN))
  {
    FUN <- switch(type,
      arff  = foreign::read.arff,
      csv   = utils::read.csv,
      dbf   = foreign::read.dbf,
      dta   = foreign::read.dta,
      m     = foreign::read.octave,
      mtp   = foreign::read.mtp,
      rds   = readRDS,
      rdata = load,
      rec   = foreign::read.epiinfo,
      spss  = foreign::read.spss,
      syd   = ,
      sys   = foreign::read.systat,
      table = stats::read.ftable,
      xls   = ,
      xlsx  = readxl::read_excel,
      xpt   = foreign::read.xport,
      NULL
    )
    if(is.null(FUN)) stop(paste0("Unhandled File Extension '", type, "'"))
  }

  infile <- tempfile(fileext = paste0('.', type))
  on.exit(unlink(infile))  # This is the auto delete
  item$download(dest = infile)

  FUN(infile, ...)
}
