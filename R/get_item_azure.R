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

#' Get an item listing from Azure OneDrive
#' 
#' Get an item `ms_drive_item` object from Azure given a path. 
#' 
#' The cloud operations of Azure split between shared and owned files. 
#' Collaborative projects need code that remains consistent and simple 
#' in retrieval of files. This function deals with the complexity of
#' find the item between owned and shared files and allows for different
#' users to utilize the same simple function.
#' 
#' @param drive A pointer to an ms_drive object from `Microsoft365R`
#' @param path The path to the file.
#' @return An `ms_drive_item` object containing the requested data.
#' 
#' @importFrom Microsoft365R ms_drive_item
#' @importFrom checkmate makeAssertCollection assert_class assert_string reportAssertions
#' @export
#' @examples
#' \dontrun{
#' library(Microsoft365R)
#' drive <- get_business_onedrive(auth_type="device_code")
#' item  <- get_item_azure(drive, "/SomeDir/sharedata.csv")
#' }
get_item_azure <- function(drive, path)
{
  coll <- checkmate::makeAssertCollection()
  checkmate::assert_class(x = drive, add = coll, classes="ms_drive")
  checkmate::assert_string(x = path, add = coll)
  checkmate::reportAssertions(coll)
  
  # Try the easy path first
  item     <- tryCatch(drive$get_item(path), silent=TRUE, error=function(e) NULL)
  filename <- basename(path)
  
  # Do the shared search
  if(is.null(item))
  {
    segments <- strsplit(dirname(path), "/")[[1]]
    items    <- shared_azure(drive)
    item     <- items[[ifelse(segments[1]=='.',filename,segments[1])]]
  
    if(is.null(item)) stop(paste("Requested top level of path must be shared/owned name. Check: `names(shared_azure(drive))`"))
    if(length(segments) > 1)
    {
      fp     <- do.call(file.path, as.list(c(segments[-1], filename)))
      item   <- item$get_item(fp) # Request rest of path
    }
  }

  item
}
