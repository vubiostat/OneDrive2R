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


#' Read data in a file from Azure OneDrive to memory
#' 
#' This function given a path will read a file that was shared or owned directly
#' into memory (via a tmp file). This is important if the file contains information
#' that one doesn't want stored to disk, e.g. private health information (PHI)
#' or private identifiable information (PII).
#' 
#' If \code{FUN} is \code{NULL} it will guess based on file extension. It 
#' supports: arff, csv, dbf, dta, m, mtp, rds, rdata, rec, spss, syd, sys,
#' table, xls, xlsx, xpt, yml, and yaml. 
#' 
#' Unfortunately, if one accesses a OneDrive file via the file system it will
#' copy the file locally and switch it to 'sync' mode. To get rid of the file
#' requires a manual removal and turning off 'sync' mode via the file explorer.
#' 
#' The path can be difficult to find. If one navigates to the data file to read
#' in SharePoint (the web interface to OneDrive) and clicks the \dots next to
#' the file name, the bottom most menu item is 'Details'. Clicking this and 
#' another interface opens to the right and the bottom most right corner has 
#' a 'More Details' option. Clicking on that will bring up more options and
#' there exists a 'Path' option with a double square next to it to copy
#' the path to the clipboard. The path it copies will not be the correct
#' path--it will contain additional directories (usually about 3) that need
#' to be removed before using. In the examples below the path returned was
#' '/personal/shawn_garbett_vumc_org/Documents/CQS%20Cloud%20Team/Project%20Artifacts/def.csv',
#' which needs to be shortened and '%20' replaced with space to result 'CQS Cloud Team/Project Artifacts/def.csv'.
#' 
#' Another option is to use the share URL. See \code{\link{link_path}}.
#' 
#' One can see the top level directories one
#' owns from \code{\link{owned_azure}} or shared \code{\link{shared_azure}}.
#' 
#' Example images of process from Windows 
#' 
#' After clicking the \dots on the file. Click on 'Details'.
#'  \if{html}{\figure{04winod_details.png}{options: width="95\%" alt="Figure: 04winod_details.png"}}
#'  \if{latex}{\figure{04winod_details.pdf}{options: width=18cm}}
#' 
#' After clicking on 'Details', click on 'More details' in the lower right.
#'  \if{html}{\figure{05winod_moredetails.png}{options: width="95\%" alt="Figure: 05winod_moredetails.png"}}
#'  \if{latex}{\figure{05winod_moredetails.pdf}{options: width=18cm}}
#'  
#' Click the copy 'Path' button (double square).
#'  \if{html}{\figure{06winod_copypath.png}{options: width="95\%" alt="Figure: 06winod_copypath.png"}}
#'  \if{latex}{\figure{06winod_copypath.pdf}{options: width=18cm}}
#' 
#' @param drive A pointer to an ms_drive object from `Microsoft365R`
#' @param path The path to the file. See details.
#' @param FUN The function to read the data into memory. The default will make a
#' guess of supported type from the filename extension. The first argument to
#' the function should be what would normally be the file. This function
#' defaults to NULL and when that is the case the routine will make a guess
#' based on the file extension, e.g. if the extension is ".csv" it will use
#' R's \code{\link{read.csv}}. 
#' @param \dots Additional arguments to pass to the function that reads the data into memory.
#' @return An R object containing the requested data.
#' 
#' @importFrom Microsoft365R ms_drive_item
#' @importFrom utils read.csv
#' @importFrom foreign read.arff read.dbf read.dta read.octave read.mtp read.spss read.systat read.xport
#' @importFrom stats read.ftable
#' @importFrom readxl read_excel
#' @importFrom yaml read_yaml
#' @importFrom checkmate makeAssertCollection assert_class assert_string assert_function reportAssertions
#' @export
#' @seealso \code{\link{link_path}}, \code{\link{owned_azure}}, and \code{\link{shared_azure}}
#' @examples
#' \dontrun{
#' library(Microsoft365R)
#' drive <- get_business_onedrive(auth_type="device_code")
#' data  <- read_azure(drive, "/SomeDir/sharedata.csv")
#' }
read_azure <- function(drive, path, FUN=NULL, ...)
{
  coll <- checkmate::makeAssertCollection()
  checkmate::assert_class(x = drive, add = coll, classes="ms_drive")
  checkmate::assert_string(x = path, add = coll)
  checkmate::assert_function(x = FUN, add = coll, null.ok = TRUE)
  checkmate::reportAssertions(coll)
  
  item <- get_item_azure(drive, path)
  ext  <- tolower(tools::file_ext(basename(path)))
  if(is.null(FUN))
  {
    FUN <- switch(ext,
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
      yml   = ,
      yaml  = yaml::read_yaml,
      NULL
    )
    if(is.null(FUN)) stop(paste0("Unhandled File Extension '", ext, "'"))
  }

  # Cannot do in memory only as it exceeds httr's buffer size
  # Unfortunately must be written temporarily to disk, use tmp
  infile <- tempfile(fileext = paste0('.', ext))
  # Automatic delete, i.e. upon exiting this function the file is deleted.
  on.exit(unlink(infile))
  item$download(dest = infile)
  
  FUN(infile, ...)
}
