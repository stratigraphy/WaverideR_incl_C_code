#' @title Extract power from a wavelet spectra
#'
#' @description Extracts the the spectral power from a wavelet spectra in the depth domain using a traced period
#' and boundaries surround the traced period.
#' The extraction of spectral is useful for cyclostratigraphic studies because the spectral power of an
#' astronomical cycle is modulated by higher order astronomical cycles.
#'The spectral power record from an astronomical cycle can thus be used as a proxy for
#' amplitude modulating cycles
#'The traced period result from the \code{\link{track_period_wavelet}}
#'function with boundaries is used to extract spectral power in the depth domain from a wavelet spectra.
#'
#'@param completed_series Traced period result from the \code{\link{track_period_wavelet}}
#'function completed using the \code{\link{completed_series}}.
#'The input can be pre-smoothed using the the \code{\link{loess_auto}} function.
#'@param wavelet Wavelet object created using the \code{\link{analyze_wavelet}} function.
#'@param period_up Upper period as a factor of the to be extracted power \code{Default=1.2}.
#'@param period_down Lower period as a factor of the to be extracted power \code{Default=0.8}.
#'@param tracked_cycle_period Period of the tracked cycle (make sure that
#'\code{tracked_cycle_period}) and \code{extract_cycle_power}) are of the same
#'unit (either depth or time domain).
#'@param extract_cycle_power Period of the cycle for which the power will be
#'extracted (make sure that \code{extract_cycle_power}) and
#'\code{tracked_cycle_period}) are of the same unit (either depth or time domain).
#'
#'@examples
#'#Extract the power of the 405 kyr eccentricity cycle from the the magnetic \cr
#'# susceptibility data set of De pas et al., (2018) \cr
#'#Perform the CWT on the magnetic susceptibility data set of De pas et al., (2018)
#'
#'mag_wt <- analyze_wavelet(data = mag,
#' dj = 1/100,
#' lowerPeriod = 0.1,
#' upperPeriod = 254,
#' verbose = TRUE,
#' omega_nr = 10)
#'
#'#Track the 405 kyr eccentricity cycle in a wavelet spectra
#'
#'#mag_track <- track_period_wavelet(astro_cycle = 405,
#'#                                   wavelet=mag_wt,
#'#                                   n.levels = 100,
#'#                                   periodlab = "Period (metres)",
#'#                                   x_lab = "depth (metres)")
#'
#'#Instead of tracking, the tracked solution data set \code{\link{mag_track_solution}} \cr
#'#is used
#'mag_track <- mag_track_solution
#'
#' mag_track_complete <- completed_series(
#'   wavelet = mag_wt,
#'   tracked_curve = mag_track,
#'   period_up = 1.2,
#'   period_down = 0.8,
#'   extrapolate = TRUE,
#'   genplot = TRUE
#' )
#'
#'#Smooth the completed tracking of the 405 kyr eccentricity cycle in the wavelet spectra
#'
#'mag_track_complete <- loess_auto(time_series = mag_track_complete,
#' genplot = TRUE, print_span = TRUE)
#'
#'#extract the spectral power of the 405 kyr eccentricity cycle
#'mag_power <- extract_power(
#'completed_series = mag_track_complete,
#'wavelet = mag_wt,
#'period_up = 1.2,
#'period_down = 0.8,
#'tracked_cycle_period = 405,
#'extract_cycle_power = 405
#')
#'
#'@return
#'Returns a matrix with 3 columns.
#'The first column is depth/time.
#'The second column is extracted power.
#'The third column is extracted power/total power.
#'
#' @export
#' @importFrom Hmisc approxExtrap
#' @importFrom stats na.omit

extract_power <- function(completed_series = NULL,
                           wavelet=NULL,
                           period_up =1.2,
                           period_down = 0.8,
                          tracked_cycle_period=NULL,
                          extract_cycle_power=NULL){

  my.data <- cbind(wavelet$x,wavelet$y)
  my.w <- wavelet
  filtered_power <- my.data[,1]
  filtered_power <- as.data.frame(filtered_power)
  filtered_power$value <- NA


  completed_series[,2] <- completed_series[,2]*(extract_cycle_power/tracked_cycle_period)
  completed_series <- na.omit(completed_series)

  app <- approxExtrap(x=completed_series[,1],y=completed_series[,2],xout=my.data[,1],
                      method="linear")
  interpolated <- cbind(app$x,app$y)

    Power = my.w$Power
  Period = my.w$Period


  interpolated <- as.data.frame(interpolated)
  interpolated$high <- interpolated[,2]*period_up
  interpolated$low <- interpolated[,2]*(period_down)

  for (i in 1:nrow(filtered_power)){

    row_nr_high <- Closest(Period[],interpolated[i,3],which=TRUE)
    row_nr_low <- Closest(Period[],interpolated[i,4],which=TRUE)

    row_nr_high <-row_nr_high[1]
    row_nr_low <- row_nr_low[1]

    value <- Power[c(row_nr_low:row_nr_high),i]
    value  <- sum(value, na.rm = T)
    value <- as.numeric(value)
    filtered_power[i,2] <- value
  }

  total_pwr <- colSums(Power,na.rm = TRUE)
  filtered_power$total <- total_pwr
  filtered_power$pwr_div_total <- filtered_power[,2]/filtered_power[,3]

  filtered_power
}