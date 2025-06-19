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


#' Write data from R memory to OneDrive
#' 
#' This function given a path will write a file to OneDrive from memory.
#' 
#' If \code{FUN} is \code{NULL} it will guess based on file extension. It 
#' supports: arff, csv, dbf, dta, rds, rdata, rec, table, yml, and yaml. 
#' 
#' @param drive A pointer to an ms_drive object from `Microsoft365R`
#' @param x The data to be written.
#' @param path The OneDrive path to write too with filename. 
#' @param FUN The function to read the data into memory. The default will make a
#' guess of supported type from the filename extension. The first argument to
#' the function must be the data. The second argument is what would normally be
#' the file (it will be a \code{\link{rawConnection}}). This function
#' defaults to NULL and when that is the case the routine will make a guess
#' based on the file extension, e.g. if the extension is ".csv" it will use
#' R's \code{\link{write.csv}}. 
#' @param \dots Additional arguments to pass to the function that writes the file.
#' @return An R object containing the requested data.
#' 
#' @importFrom Microsoft365R ms_drive_item
#' @importFrom utils write.csv
#' @importFrom foreign write.arff write.dbf write.dta 
#' @importFrom stats write.ftable
#' @importFrom yaml write_yaml
#' @importFrom checkmate makeAssertCollection assert_class assert_string assert_function reportAssertions
#' @export
#' @seealso \code{\link{link_path}}, \code{\link{owned_azure}}, and \code{\link{shared_azure}}
#' @examples
#' \dontrun{
#' library(Microsoft365R)
#' drive <- get_business_onedrive(auth_type="device_code")
#' data  <- write_azure(drive, data, "/SomeDir/sharedata.csv")
#' }
write_azure <- function(drive, x, path, FUN=NULL, ...)
{
  coll <- checkmate::makeAssertCollection()
  checkmate::assert_class(x = drive, add = coll, classes="ms_drive")
  checkmate::assert_string(x = path, add = coll)
  checkmate::assert_function(x = FUN, add = coll, null.ok = TRUE)
  checkmate::reportAssertions(coll)
  
  filename <- basename(path)
  path     <- dirname(path)
  ext      <- tolower(tools::file_ext(filename))
  item     <- if(path == '.') 
                get_item_azure(drive, filename)$get_parent_folder() else
                get_item_azure(path)

  if(is.null(FUN) && ext=='')
    stop("Cannot guess file handling with no file extension.")
  if(!item$is_folder())
    stop("ms_drive_item found is not a folder.")
  
  # If FUN is NULL, guess based on extension
  if(is.null(FUN))
  {
    outer_name <- as.character(subsitute(x))
    FUN <- switch(
      ext,
      arff  = foreign::write.arff,
      csv   = utils::write.csv,
      dbf   = foreign::write.dbf,
      dta   = foreign::write.dta,
      rds   = saveRDS,
      rdata = function(x, file, ...) save(get(list=outer_name, envir=as.environment(-1)), file = file, ...),
      rec   = foreign::write.epiinfo,
      table = stats::write.ftable,
      yml   = ,
      yaml  = yaml::write_yaml,
      NULL
    )
    if(is.null(FUN)) stop(paste0("Unhandled File Extension '", ext, "'"))
  }
  
  conn <- rawConnection(raw(0), "w+")
  # on.exit(close(conn)) apparently upload does this?
  FUN(x, conn, ...)
  seek(conn, 0, rw="read")
  item$upload(src = conn, dest=filename)
}