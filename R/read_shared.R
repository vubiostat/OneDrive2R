# Copyright (C) 2024-2025 Shawn Garbett, Cole Beck, James Grindstaff, Lauren
# Samuels, Vanderbilt University
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#' Microsoft365R items that are shared on drive
#' 
#' Retrieve a list of shared OneDrive items given a drive authentication
#' object.
#' 
#' @param drive A pointer to an ms_drive object from `Microsoft365R`
#' @return Named list of `Microsoft365R::ms_drive_item`'s shared with user.
#' @export
#' @examples
#' \dontrun{
#' drive <- get_business_onedrive(drive_type="device_code")
#' names(shared(drive))
#' }
#' @importFrom checkmate makeAssertCollection assert_class reportAssertions
shared <- function(drive)
{
  coll <- checkmate::makeAssertCollection()
  checkmate::assert_class(x = drive, add = coll, classes="ms_drive")
  checkmate::reportAssertions(coll)
  
  shared_objs <- drive$do_operation("sharedWithMe",
                                    options=list(allowexternal="true"))
  objs <- lapply(shared_objs$value, function(obj) obj$remoteItem)
  names(objs)  <- sapply(objs, function(o) o$name)

  objs
}

#' Read a file from OneDrive that was shared
#' 
#' This function given a path will read a file that was shared directly
#' into memory. This is important if the file contains information
#' that one doesn't want stored to disk, e.g. private health information (PHI)
#' or private identifiable information (PII).
#' 
#' Unfortunately, if one "mounts" a OneDrive it will by DEFAULT
#' copy the files locally. The files must be manually turned off to "sync". 
#' 
#' @param drive A pointer to an ms_drive object from `Microsoft365R`
#' @param path The path to the file.
#' @param FUN The function to read the data into memory. The default will make a guess of supported type from the filename extension.
#' @param \dots Additional arguments to pass to the function that reads the data into memory.
#' @return An R object containing the requested data.
#' 
#' @importFrom Microsoft365R ms_drive_item
#' @importFrom utils read.csv
#' @importFrom foreign read.arff read.dbf read.dta read.octave read.mtp read.spss read.systat read.xport
#' @importFrom stats read.ftable
#' @importFrom readxl read_excel
#' @export
#' @examples
#' \dontrun{
#' library(Microsoft365R)
#' drive <- get_business_onedrive(drive_type="device_code")
#' data  <- read.shared(drive, "/SomeDir/sharedata.csv")
#' }
#' @importFrom checkmate makeAssertCollection assert_class assert_string assert_function reportAssertions
read_shared <- function(drive, path, FUN=NULL, ...)
{
  coll <- checkmate::makeAssertCollection()
  checkmate::assert_class(x = drive, add = coll, classes="ms_drive")
  checkmate::assert_string(x = path, add = coll)
  checkmate::assert_function(x = FUN, add = coll, null.ok = TRUE)
  checkmate::reportAssertions(coll)
  
  filename <- basename(path)
  items    <- strsplit(dirname(path), "/")[[1]]
  objs     <- shared(drive)
  top      <- objs[[ifelse(items[1]=='.',filename,items[1])]]

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
