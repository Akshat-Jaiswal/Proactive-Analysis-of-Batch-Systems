# script to perform time Series Analysis
#   Uses the following packages 
#   @depends: AnomalyDetection, zoo, changepoint, mgcv
#
# helper function to calculate trend 
#
#   @param x: univariate time series 
#   Function uses GAM to smoothen the curve and output a trend line
#   @return vector: containning trend points
#

find.trend<- function(x,...){
  require(mgcv)
  tryCatch({
    tt <- 1:length(x)
    trend <- rep(NA,length(x))
    trend[!is.na(x)]<- fitted((gam(x~s(tt))))
    # output the trend
    trend
  }
    , error= function(e){
    return (c())
  })
}

# helper function to categorize trend as increasing, decreasing or constant
#
#   @param y: vector containning sequence of points 
#   @param lowpass: Filter for deciding whether trend is increasing or not
#   @param highpass: Filter for deciding whether trend is decreasing or not   
#   @return list
#         $trend-   "character": (increasing"/"decreasing"/"constant")
#         $slope-   "numeric"  :  slope of the straight line
#         $constant-"numeric"  :  line constant (Intercept)  
#
classify.trend<-function(y, lowpass=0.1, highpass=-0.1){
  #fits a straight line using linear regression
  x<- 1:length(y)
  fit<- lm(y~x)
  slope<- fit[[1]][2]
  constant<- fit[[1]][1]
  if(slope<highpass) trend="decreasing"
  else if (slope>lowpass) trend="increasing"
  else trend="constant"
  return(list("trend"=trend,"slope"=slope,"constant"=constant))
}

filepath<-"F:/pdf/R/sampledata/output/job_stats_derived_intermediate.csv"
rootdirectory<- "F:/pdf/R/sampledata/UI/output";
job_stats_derived_intermediate<- read.csv(filepath)
job_stats_derived_intermediate<- subset(job_stats_derived_intermediate,jobname!="#N/A")
sapply( split(job_stats_derived_intermediate, factor(job_stats_derived_intermediate$jobname)),function(sampled){
#sampled<-subset(job_stats_derived_intermediate,jobname=="bmxftp_newcrd_addr_folder_for_cmd")
jobName=sampled$jobname[1]
# order the time series according to the date
sampled<- sampled[order(sampled$date),]
# plot the initial time series
plot.ts(sampled$runtime, ylab=sampled$jobname[1])

#save original series before outlier removal
UI<-sampled[,c("date","jobstatus","runtime","starttimeviolated","endtimeviolated","minalert","maxalert")]
#   STEP 1 Find Outliers and remove them
outliers<- tryCatch(AnomalyDetection::AnomalyDetectionTs(sampled[,c("date","runtime")],plot=TRUE ,na.rm=F, direction="both"), error= function(e){
  return (list("anom"= data.frame()))
})
#plot the series
#outliers$plot
# find the indices of outliers
if(nrow(outliers$anom)!=0){
indices.outliers<- which(as.Date(sampled$date,format="%m/%d/%Y") %in% as.Date(outliers$anom[[1]], format="%Y-%m-%d"))
} else {
  indices.outliers<- c()
}
# If the last record is an outlier then ignore it 
#indices.outliers<-indices.outliers[indices.outliers!= length(sampled$runtime)]
# remove these entries by replacing them with NA
sampled$runtime[indices.outliers]<- NA
# create a zoo series corresponding to above time series data
zooseries<- zoo::zoo(sampled$runtime, sampled$date)
# use interpolation to approximate these  
zooseries<- zoo::na.approx(zooseries)
# plot the new time series
#plot.ts(zooseries,ylab="Runtime")
#make the two things equal
len= min(length(UI$runtime),length(zooseries))
UI<- UI[1:len,]
zooseries<- zooseries[1:len,]
# remove the outliers which are greater than length
indices.outliers<- indices.outliers[indices.outliers<=len]

#   STEP 2 Find the trend line for above time series
trendpoints<- find.trend(as.vector(zooseries))
#   plot the trend line on top of time series
#lines(1:length(trendpoints),trendpoints,col="blue")
#   now classify trend as incresing decreasing or constant
if(length(trendpoints)==0){
  result<- classify.trend(UI$runtime,.1,-.1)
} else
  result<- classify.trend(trendpoints,.1,-.1)
# plot the trend line on top of above diagram
#abline(result$constant,result$slope,lty=2,col="orange")
# add legend to plot
#legend("topright",c("Trend","Overall Trend (Increasing)"),col=c("blue","orange"),lty=c(1,2),y.intersp = .5)

# STEP 3 Change Point Detection
# first changepoint detection using AMOC method
cpts<- changepoint::cpt.mean(zooseries, method = "AMOC")
# plot the graph 
#plot(cpts, ylab="runtime")
# save the results
UI$trendPoints<- trendpoints
#set default value for false for outlier and change point column
UI$outlier<-F
UI$changePoint<-F
# set true for outliers indices
UI$outlier[indices.outliers]<- T
if(cpts@cpts[1]<=len){
 UI$changePoint[cpts@cpts[1]]<-T
}#set points for trendline
UI$trend<- result$slope*(1:length(UI$runtime))+ result$constant
UI[is.na(UI)]<- F
UI<-UI[order(UI$date),]
# write the result to CSV
# first create a directory corresponding to each jobname
    if(!dir.exists(paste(rootdirectory,jobName,sep = "/"))){
      dir.create(paste(rootdirectory,jobName,sep = "/"))
    }
    write.csv(UI,paste(rootdirectory,jobName,"test.csv", sep = "/"), row.names = F)
  
    }
) # end of sapply