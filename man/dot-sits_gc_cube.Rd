% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sits_gdalcubes.R
\name{.sits_gc_cube}
\alias{.sits_gc_cube}
\title{Create a cube_view object}
\usage{
.sits_gc_cube(c_tile, period, method, resampling)
}
\arguments{
\item{c_tile}{A tile of a data cube}

\item{period}{A \code{character} with the The period of time in which it
is desired to apply in the cube, must be provided based on ISO8601, where 1
number and a unit are provided, for example "P16D".}

\item{method}{A \code{character} with the method that will be applied in
the aggregation, the following are available: "min", "max", "mean",
"median" or "first".}

\item{resampling}{A \code{character} with the method that will be applied
in the resampling in mosaic operation. The following are available: "near",
"bilinear", "bicubic" or others supported by gdalwarp
(see https://gdal.org/programs/gdalwarp.html).}
}
\value{
a \code{list} with a cube_view objects.
}
\description{
Create a cube_view object
}
\keyword{internal}
