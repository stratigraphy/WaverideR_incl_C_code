#' @title Extract power from a wavelet spectra by using a constant period/duration
#'
#' @description Extract spectral power from the wavelet using a constant period/duration and
#' boundaries as selection criteria. The extraction of spectral is useful for cyclostratigraphic studies because the spectral power of an
#' astronomical cycle is modulated by higher order astronomical cycles.
#'The spectral power record from an astronomical cycle can thus be used as a proxy for
#' amplitude modulating cycles. The spectral power is extracted from a wavelet spectra
#' which was created using the \code{\link{analyze_wavelet}}
#'function for a given, \code{cycle}, \code{period_up} and \code{period_down}
#'
#'
#'@param wavelet Wavelet object created using the \code{\link{analyze_wavelet}} function.
#'@param cycle Period of cycle for which the power will be extracted from the record.
#'@param period_up Upper period as a factor of the to be extracted power \code{Default=1.2}.
#'@param period_down Lower period as a factor of the to be extracted power \code{Default=0.8}.
#'
#'@examples
#'#Extract the spectral power of the 210 yr de Vries cycle from the Total Solar \cr
#'#Irradiance data set of Steinhilver et al., (2012).
#'
#'TSI_wt <-
#'  analyze_wavelet(
#'    data = TSI,
#'    dj = 1/200,
#'    lowerPeriod = 16,
#'    upperPeriod = 8192,
#'    verbose = TRUE,
#'    omega_nr = 6
#'  )
#'TSI_wt_pwr_de_Vries_cycle <-  extract_power_stable(
#'  wavelet = TSI_wt,
#'  cycle = 210,
#'  period_up = 1.2,
#'  period_down = 0.8
#')
#'
#'
#'@return
#'Returns a matrix with 3 columns.
#'The first column is depth/time.
#'The second column is extracted power.
#'The third column is extracted power/total power.
#'
#' @export
#' @importFrom DescTools Closest

extract_power_stable <- function(wavelet=NULL,
                          cycle=NULL,
                          period_up =1.2,
                          period_down = 0.8){

  Period <- as.data.frame(wavelet$Period)
  extract_power_high <- cycle*period_up
  extract_power_low <- cycle*period_down
  low_rownr <- Closest(Period[,1],extract_power_low,which=TRUE)
  high_rownr <- Closest(Period[,1],extract_power_high,which=TRUE)
  Power <- as.data.frame(wavelet$Power)
  Power_sel <- Power[(low_rownr:high_rownr),]
  Power_sel <- as.data.frame(colSums(Power_sel))
  filtered_power <- cbind(wavelet$axis.1 ,Power_sel)
  filtered_power <-as.data.frame(filtered_power)
  total_pwr <- colSums(Power,na.rm = TRUE)
  filtered_power$total <- total_pwr
  filtered_power$pwr_div_total <- filtered_power[,2]/filtered_power[,3]
  filtered_power

  }