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

#' Extract Azure path from a shared URL link
#' 
#' Given a shared item link from OneDrive extract the path to use for
#' retrieval via Microsoft365R's API. The file must be shared and then the link
#' must come from the web interface by clicking the "\dots > Copy Link". It does
#'  not work from a link for an owned file. 
#' 
#' Note: This function is based on observation of links from Microsoft
#' and is not guaranteed to work. It is provided as a hopefully helpful resource.
#' 
#' @param url A string that is the url of note.
#' @return The path contained within the url.
#' @export
#' @importFrom stringr str_match
#' @examples
#' # Construct URL inside R help constraints
#' url <- paste0('https://vumc365-my.sharepoint.com/:x:/r/personal/',
#'               '/first_last_company_org/Documents/TopFolder/SubFolder/abc.csv',
#'               '?d=asdfasdfasdfasdfasdfa2beb6&csf=1&web=1&e=PJBSO0x')
#' link_path(url)
#' @importFrom checkmate makeAssertCollection assert_string reportAssertions
link_path <- function(url)
{
  coll <- checkmate::makeAssertCollection()
  checkmate::assert_string(x = url, add = coll)
  checkmate::reportAssertions(coll)
  stringr::str_match(url, "Documents/(.+)\\?d=")[,2]
}