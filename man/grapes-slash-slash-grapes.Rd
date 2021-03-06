% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/opspec.R
\name{\%//\%}
\alias{\%//\%}
\title{Factor-out (aggregate/project) block records into row records.}
\usage{
table \%//\% transform
}
\arguments{
\item{table}{data (data.frame or relop).}

\item{transform}{a rowrecs_to_blocks_spec.}
}
\value{
blocks_to_rowrecs() result.
}
\description{
Call \code{blocks_to_rowrecs()}.
}
\examples{

d <- wrapr::build_frame(
  "id", "measure", "value" |
  1   , "AUC"    , 0.7     |
  1   , "R2"     , 0.4     |
  2   , "AUC"    , 0.8     |
  2   , "R2"     , 0.5     )

transform <- blocks_to_rowrecs_spec(
  wrapr::qchar_frame(
    "measure", "value" |
    "AUC"    , AUC     |
    "R2"     , R2      ),
  recordKeys = "id")

d \%//\% transform

# identity (in structure)
d \%//\% transform \%**\% t(transform)

}
