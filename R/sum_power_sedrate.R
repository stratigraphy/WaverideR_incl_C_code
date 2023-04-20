#' @title Calculate sum of maximum spectral power for sedimentation rates based
#' for a wavelet spectra
#'
#' @description The \code{\link{sum_power_sedrate}} function is used calculate the sum of
#' maximum spectral power for a list of astronomical cycles from a wavelet spectra.
#' The data is first normalized using the average spectral power curves
#'  for a given percentile based on results of the \code{\link{model_red_noise_wt}} function
#'
#'@param red_noise Red noise curves generated using the \code{\link{model_red_noise_wt}} function
#'@param wavelet Wavelet object created using the \code{\link{analyze_wavelet}} function
#'@param percentile Percentile value (0-1) of the rednoise runs which is used to normalize the data for.
#'To account for the distribution/distortion of the spectral power distribution based on the analytical technique and
#'random red-noise the data is normalized against a percentile based red-noise curve which is the results of the
#''\code{\link{model_red_noise_wt}} modelling runs.
#'@param sedrate_low Minimum sedimentation rate (cm/kyr)for which the sum of maximum spectral power is calculated for.
#'@param sedrate_high Maximum sedimentation rate (cm/kyr) for which the sum of maximum spectral power is calculated  for.
#'@param spacing Spacing (cm/kyr) between sedimentation rates
#'@param cycles Astronomical cycles (in kyr) for which the combined sum of maximum spectral power is calculated for
#'@param x_lab label for the y-axis \code{Default="depth"}
#'@param y_lab label for the y-axis \code{Default="sedrate"}
#'@param genplot Generate plot \code{Default="TRUE"}
#'
#'
#'@examples
#'\dontrun{
#'#estimate sedimentation rate for the the magnetic susceptibility record \cr
#'# of the Sullivan core of De pas et al., (2018).
#'
#'mag_wt <- analyze_wavelet(data = mag,
#' dj = 1/100,
#' lowerPeriod = 0.1,
#' upperPeriod = 254,
#' verbose = FALSE,
#' omega_nr = 10)
#'
#'#increase n_simulations to better define the red noise spectral power curve
#'mag_wt_red_noise <- model_red_noise_wt(wavelet=mag_wt,
#'n_simulations=100,
#'verbose=FALSE)
#'
#'sedrates <- sum_power_sedrate(red_noise=mag_wt_red_noise,
#'wavelet=mag_wt,
#'percentile=0.75,
#'sedrate_low = 0.5,
#'sedrate_high = 4,
#'spacing = 0.05,
#'cycles = c(2376,1600,1180,696,406,110),
#'x_lab="depth",
#'y_lab="sedrate",
#'genplot = TRUE)
#'}
#'
#'
#' @return
#'Returns a matrix with sum of maximum spectral power for a given sedimentation rates and a given depths.
#'
#'If \code{Default="TRUE"} a plot is created with 3 subplots.
#'Subplot 1 is plot in which the the sum of maximum spectral power for a
#'given sedimentation rate is plotted for each depth given depth.
#'Subplot 2 is a plot in which the average sum of maximum spectral power is plotted fro each sedimentation
#'Subplot 3 is a color scale for subplot 1.
#'
#' @export
#' @importFrom matrixStats rowSds
#' @importFrom Matrix rowMeans
#' @importFrom stats qnorm
#' @importFrom stats quantile
#' @importFrom parallel detectCores
#' @importFrom parallel makeCluster
#' @importFrom doSNOW registerDoSNOW
#' @importFrom utils txtProgressBar
#' @importFrom utils setTxtProgressBar
#' @importFrom tcltk setTkProgressBar
#' @importFrom tcltk setTkProgressBar
#' @importFrom foreach foreach
#' @importFrom stats runif
#' @importFrom stats sd
#' @importFrom reshape2 melt
#' @importFrom graphics par
#' @importFrom graphics image
#' @importFrom graphics axis
#' @importFrom graphics mtext
#' @importFrom graphics text
#' @importFrom graphics box
#' @importFrom graphics polygon
#' @importFrom grDevices rgb
#' @importFrom foreach %dopar%
#' @importFrom graphics layout
#' @importFrom parallel stopCluster




sum_power_sedrate  <- function(red_noise=NULL,
                               wavelet=NULL,
                               percentile=NULL,
                               sedrate_low = NULL,
                               sedrate_high = NULL,
                               spacing = NULL,
                               cycles = c(NULL),
                               x_lab="depth",
                               y_lab="sedrate",
                               genplot = TRUE){

my.data <- cbind(wavelet$x,wavelet$y)
my.w <- wavelet

Power <- matrix(unlist(as.data.frame(my.w$Power)))
Power <- as.data.frame(matrix(unlist(as.data.frame(my.w$Power)),ncol=my.w$nc,nrow=my.w$nr))
Power <- t(Power)
Powert <- t(Power)

line_1 <- cbind(my.w$Period,Powert[,1])
line_1 <- as.data.frame(line_1)

maxdetect_new <- matrix(nrow=(nrow(Powert)),ncol=ncol(Powert),0)


for (j in 1:ncol(Powert)) {
  for(i in 2:(nrow(maxdetect_new)-1)){
    if ((Powert[i,j] - Powert[(i+1),j] > 0) & (Powert[i,j] - Powert[(i-1),j]  > 0))
    {maxdetect_new[i,j] <- 1}
  }
}


maxdetect_new2 <- maxdetect_new[,]

avg_power <- cbind(my.w$Period,my.w$Power.avg)
noise_period <- cbind(my.w$Period,red_noise)
noise_period2 <- as.data.frame(noise_period)
noise_period2$mean <- rowMeans(red_noise)
noise_period2$sd <- rowSds(red_noise)
meanz <-noise_period2$mean
sdz <- noise_period2$sd

probabillity <- qnorm(p=percentile, mean=meanz, sd=sdz)
probabillity <- cbind(my.w$Period,probabillity)
probabillity[probabillity[,2]<0,] <- 0

testsedrates <- seq(from=sedrate_low,to=sedrate_high,by=spacing)
testsedrates <- as.data.frame(testsedrates)

numCores<-detectCores()
cl <- makeCluster(numCores-2)
registerDoSNOW(cl)

simulations <-ncol(Powert)
pb <- txtProgressBar(max=simulations, style=3)
progress <- function(n) setTxtProgressBar(pb, n)
opts <- list(progress=progress)
multi <-  (2*sqrt(2*log(2)))
ijk <- 1 # needed to assign 1 to ijk to avoid note


fit<- foreach (ijk=1:simulations, .options.snow = opts)%dopar% {
  fits <- matrix(data=NA,nrow=nrow(testsedrates),ncol=2)
  Power_sel <- as.data.frame(cbind(my.w$Period,Powert[,ijk]))
  maxdetect_new3 <- as.data.frame(cbind(my.w$Period,maxdetect_new2[,ijk]))
  colnames(maxdetect_new3) <- c("Period","power")
  prob_threshold <- as.data.frame(Powert[,ijk])
  #prob_threshold <- as.data.frame(Powert[,ijk]-probabillity[,2])
  prob_threshold[prob_threshold[,1]<0,1] <- 0
  prob_threshold[prob_threshold[,1]>0,1] <- 1
  maxdetect_new3[,2] <- maxdetect_new3[,2]#*prob_threshold
  maxdetect_new3 <- maxdetect_new3[maxdetect_new3$power > 0, ]
  Power_sel[,2] <- Power_sel[,2]*prob_threshold
  Power_sel[,2] <- (Power_sel[,2]*(probabillity[,2])*max(probabillity[,2]))
  colnames(Power_sel) <- c("Period","power")

  for (ij in 1:nrow(testsedrates)){
    sedrate <- testsedrates[ij,]
    cycles_in_depth <- ((cycles*sedrate)/100)

    ncycles <- my.w$omega_nr
    b <- (2*sqrt(2*log(2)))
    a <- ((8*log(2)/(2*pi)))
    k <- (ncycles/(8*log(2)))*2

    cycles_in_depth_vars <- as.data.frame(matrix(data=NA,nrow = length(cycles_in_depth),ncol=3))
    cycles_in_depth_vars$f0 <- (1/(cycles_in_depth))
    cycles_in_depth_vars$df <- (a*cycles_in_depth_vars$f0)/k
    cycles_in_depth_vars$sd_morlet <- cycles_in_depth_vars$df/b

    bottom_cycle_in_depth <- 1/(cycles_in_depth_vars$f0-(cycles_in_depth_vars$sd_morlet*multi)
    )
    top_cycle_in_depth <-  1/(cycles_in_depth_vars$f0+(cycles_in_depth_vars$sd_morlet*multi)
    )


    nearest_cycle <- as.data.frame(matrix(data=NA,nrow=length(cycles),ncol=6))
    colnames(nearest_cycle) <- c("astro_centre","astro_top","astro_bottom","spectra","diff","in_out")
    nearest_cycle[,1] <-cycles_in_depth
    nearest_cycle[,2] <-bottom_cycle_in_depth
    nearest_cycle[,3] <-top_cycle_in_depth


    for (jj in 1:length(cycles)){
      row_nr <- DescTools::Closest(maxdetect_new3[,1],cycles_in_depth[jj],which=TRUE)
      row_nr <- row_nr[1]
      nearest_cycle[jj,4] <-maxdetect_new3[row_nr,1]
    }

    nearest_cycle[,5] <- abs(nearest_cycle$spectra- nearest_cycle$astro_centre)
    nearest_cycle <- nearest_cycle[order(-nearest_cycle$spectra, -nearest_cycle$diff), ]
    sel_cycles <- nearest_cycle[!duplicated(nearest_cycle$spectra, fromLast = TRUE), ]
    sel_cycles <- sel_cycles[(sel_cycles$spectra > sel_cycles$astro_bottom &sel_cycles$spectra < sel_cycles$astro_top),]



    if (nrow(sel_cycles)==0 ){
      calc <- 0
      nr_compenents <- 0
    }else{

    calc <- matrix(data=NA,nrow=nrow(sel_cycles))
    for (j in 1:nrow(sel_cycles)){
      interval <- Power_sel[(Power_sel[,1] >= sel_cycles[j,3])
                            & Power_sel[,1] <= sel_cycles[j,2], ]
      calc[j] <-  max(interval[,2])
    }
    nr_compenents <- calc
    nr_compenents[nr_compenents[,1]>0,1] <- 1
    nr_compenents <- sum(nr_compenents[,1])
    #calc <-sum(calc)/max(Power_sel[,2])
    calc <- ((sum(calc)-min(Power_sel[,2]))/(max(Power_sel[,2])-min(Power_sel[,2])))*(nr_compenents/length(cycles))
    calc[!is.finite(calc)] <- 0}
    fits[ij,1] <- calc
    fits[ij,2] <- nr_compenents

  }
  fits <- fits
}


stopCluster(cl)

fit2 <- fit

power_max_mat <- matrix(data=NA,ncol=length(my.w$x),nrow=nrow(testsedrates))
nr_compenents_mat <- matrix(data=NA,ncol=length(my.w$x),nrow=nrow(testsedrates))

for (kk in 1:length(fit2)){
  extract <- as.data.frame(fit2[[kk]])
  power_max_mat[,kk] <- extract[,1]
  nr_compenents_mat[,kk] <- extract[,2]
}

#power_max_mat <- power_max_mat[,2:ncol(power_max_mat)]
#nr_compenents_mat <- nr_compenents_mat[,2:ncol(nr_compenents_mat)]

nrows_testsedrates <- nrow(as.data.frame(testsedrates))
sedrate_plot <- as.data.frame(matrix(data=NA,
                                     nrow=nrow(my.data)*nrows_testsedrates,ncol=3))
colnames(sedrate_plot) <-c("depth","sedrate","Power")
fit_unlist2 <- melt(fit2)
colnames(fit_unlist2) <-c("sedrate","depth","Power")
power_max_mat_2 <- melt(power_max_mat)
colnames(power_max_mat_2) <-c("sedrate","depth","Power")




depth<-rep(my.w$x,each=nrows_testsedrates)
sedrate<-unlist(rep(testsedrates,times=length(my.w$x)))
sedrate_plot <- as.data.frame(power_max_mat_2)


sedrate_plot$depth <- depth
sedrate_plot$sedrate <-sedrate
sedrate_plot$depth <- sedrate_plot$depth
sedrate_plot$sedrate <- sedrate_plot$sedrate

sedrate_plot <- as.data.frame(sedrate_plot)


depth <- (my.data[,1])
y_axis <- unlist(testsedrates)

dev.new(width=14,height=7)

layout.matrix <- matrix(c(1, 2,3), nrow = 1, ncol = 3)
layout(mat = layout.matrix,
       heights = c(1, 1,1), # Heights of the two rows
       widths = c(8,2,2))

par(mar = c(4, 4, 2, 3))

pmax_avg <- t(power_max_mat)


n.levels =100
power_max_mat.levels = quantile(pmax_avg, probs = seq(
  from = 0,
  to = 1,
  length.out = n.levels + 1
))


op = par(no.readonly = TRUE)
image.plt = par()$plt
color.palette = "rainbow(n.levels, start = 0, end = 0.7)"
key.cols = rev(eval(parse(text = color.palette)))


depth <- (my.data[,1])
y_axis <- unlist(testsedrates)
depth <- as.numeric(depth)
y_axis <- as.numeric(y_axis)
image(x=depth,y=y_axis,z=(pmax_avg), col = key.cols,breaks=power_max_mat.levels,
      xlab=x_lab, ylab=y_lab,useRaster=TRUE)

r_sum <- 10^colMeans(pmax_avg)
plot(y=y_axis,x=r_sum,type="l",ylim=c(min(y_axis),max(y_axis)),yaxs="i",
     xlab="normalized power",ylab=y_lab)

lwd.axis = 1
n.ticks = 6
label.digits = 3
label.format = "f"
width = 1.2
lab.line = 2.5
lab = NULL

key.marks = round(seq(
  from = 0,
  to = 1,
  length.out = n.ticks
) *
  n.levels)
key.labels = formatC(
  as.numeric(power_max_mat.levels),
  digits = label.digits,
  format = label.format
)[key.marks +
    1]


image(
  1,
  seq(from = 0, to = n.levels),
  matrix(power_max_mat.levels,
         nrow = 1),
  col = key.cols,
  breaks = power_max_mat.levels,
  useRaster = TRUE,
  xaxt = "n",
  yaxt = "n",
  xlab = "",
  ylab = ""
)


axis(
  4,
  lwd = lwd.axis,
  at = key.marks,
  labels = NA,
  tck = 0.02,
  tcl = (par()$usr[2] - par()$usr[1]) *
    width - 0.04
)
mtext(
  key.labels,
  side = 4,
  at = key.marks,
  line = 0.5,
  las = 2,
  font = par()$font.axis,
  cex = par()$cex.axis
)

box(lwd = lwd.axis)

fit
}