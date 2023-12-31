% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/minimal_tuning.R
\name{minimal_tuning}
\alias{minimal_tuning}
\title{Create an age model using minimal tuning}
\usage{
minimal_tuning(
  data = NULL,
  pts = 5,
  cycle = 405,
  tune_opt = "max",
  output = 0,
  genplot = FALSE,
  keep_editable = FALSE
)
}
\arguments{
\item{data}{Input is an cycle extracted filtered in the depth domain}

\item{pts}{The pts parameter specifies how many points to the left/right up/down the peak detect algorithm goes in detecting
a peak. The peak detecting algorithm works by comparing the values left/right up/down of it, if the values are both higher or lower
then the value a peak. To deal with error produced by this algorithm the pts parameter can be changed which can
aid in peak detection. Usually increasing the pts parameter means more peak certainty, however it also means that minor peaks might not be
picked up by the algorithm \code{Default=5}}

\item{cycle}{duration in kyr of the filtered/extracted cycle}

\item{tune_opt}{tuning options "min", "max" and "minmax" use minima, maxima or both
of the cyclic signal to create the age model \code{Default="max"}}

\item{output}{#'The output depends on the output setting
If output = 0 output is a matrix of with 4 columns being; depth,proxy,sedimentation rate and time
If output = 1 output is a matrix of with 2 columns being; depth and sedimentation rate
#'If output = 2 output is a matrix of with 2 columns being; depth and time}

\item{genplot}{Keep option to add extra features after plotting  \code{Default=FALSE}}

\item{keep_editable}{Keep option to add extra features after plotting  \code{Default=FALSE}}
}
\value{
The output depends on the output setting
If output = 0 output is a matrix of with 4 columns being (depth,proxy,sedimentation rate and time)
If genplot = TRUE 4 plots are generated; depth vs proxy, depth vs sedimentation rate, depth vs time and time vs proxy
If output = 1 output is a matrix of with 2 columns being (depth and sedimentation rate )
If genplot = TRUE a plot of depth vs sedimentation rate is generated
If output = 2 output is a matrix of with 2 columns being (depth and time)
If genplot = TRUE a plot of depth vs time is generated
}
\description{
Create an age model using the minimal tuning technique.
This means that the distance between 2 peaks of an extracted cycle are set
to duration of the interpreted astronomical cycle
}
\examples{
\donttest{
# Extract the 405kyr eccentricity cycle from the wavelet scalogram
# from the magnetic susceptibility record f the Sullivan core
# of Pas et al., (2018) and then create a age model using minimal tuning
# (e.g.) set the distance between peaks to 405 kyr

mag_wt <- analyze_wavelet(data = mag,
dj = 1/100,
lowerPeriod = 0.1,
upperPeriod = 254,
verbose = FALSE,
omega_nr = 10)


mag_405 <- extract_signal_stable_V2(
 wavelet = mag_wt,
 period_max = 4,
 period_min = 2,
 add_mean = FALSE,
 plot_residual = FALSE,
 keep_editable = FALSE
)

mag_405_min_tuning <- minimal_tuning(data = mag_405,
pts = 5,
cycle = 405,
tune_opt = "max",
output = 0,
genplot = FALSE,
keep_editable = FALSE)


}

}
\references{
Routines for astrochronologic testing, astronomical time scale construction, and
time series analysis <doi:10.1016/j.earscirev.2018.11.015>
}
\author{
Part of the code is based on the \link[astrochron]{sedrate2time}
function of the 'astrochron' R package
}
