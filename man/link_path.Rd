% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/link_path.R
\name{link_path}
\alias{link_path}
\title{Extract Azure path from a shared URL link}
\usage{
link_path(url)
}
\arguments{
\item{url}{A string that is the url of note.}
}
\value{
The path contained within the url.
}
\description{
Given a shared item link from OneDrive extract the path to use for
retrieval via Microsoft365R's API. The file must be shared and then the link
must come from the web interface by clicking the "\dots > Copy Link". It does
not work from a link for an owned file.
}
\details{
Note: This function is based on observation of links from Microsoft
and is not guaranteed to work. It is provided as a hopefully helpful resource.
}
\examples{
# Construct URL inside R help constraints
url <- paste0('https://vumc365-my.sharepoint.com/:x:/r/personal/',
              '/first_last_company_org/Documents/Top\%20Folder/Sub\%20Folder/abc.csv',
              '?d=asdfasdfasdfasdfasdfa2beb6&csf=1&web=1&e=PJBSO0x')
link_path(url)
}
