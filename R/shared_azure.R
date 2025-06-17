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

#' Named list of Microsoft365R items that are shared on OneDrive
#' 
#' Retrieve a named list of shared OneDrive items given a drive authentication
#' object.
#' 
#' @param drive A pointer to an ms_drive object from `Microsoft365R`
#' @return Named list of `Microsoft365R::ms_drive_item`'s shared with user.
#' @export
#' @examples
#' \dontrun{
#' drive <- get_business_onedrive(auth_type="device_code")
#' names(shared(drive))
#' }
#' @importFrom checkmate makeAssertCollection assert_class reportAssertions
shared_azure <- function(drive)
{
  coll <- checkmate::makeAssertCollection()
  checkmate::assert_class(x = drive, add = coll, classes="ms_drive")
  checkmate::reportAssertions(coll)
  
  items <- drive$list_shared_items(allow_external = TRUE)
  names(items) <- sapply(items, function(x) x$properties$name)
  items
}
