#path to the intermediate input file
#filepath<-"F:/pdf/R/sampledata/output/job_stats_derived_intermediate.csv"
#sampled<- subset(job_stats_derived_intermediate,jobname=="rc_heft_bp_book")
sampled<-subset(job_stats_derived_intermediate,jobname=="hpc_idphi_sealimit")
#function to find period/frequency of a timeseries data
# only able to detect single seasonality
find.freq<- function(x){
  if(var(x)==0){ 
    return(1)
  }
  n<-length(x)
  spec <- spec.ar(c(na.contiguous(x)), plot = F)
  if(max( spec$spec) >10)
  {
    period <- round(1/spec$freq[which.max(spec$spec)])
    if(period==Inf)
    {
      j<- which(diff(spec$spec)>0)
      if(length(j)>0)
      {
        nextmax<- j[1]+which.max(spec$spec[j[1]:500])
        if(nextmax <= length(spec$freq)) 
          period<- round(1/spec$freq[nextmax])
        else
          period <- 1
      }
      else period <-1
    }
  }
   else period <-1
  return(period)
}
#function to decompose timeseries into trend, seasonality and error terms
decomp<- function(x, transform=T){
  require(forecast)
  #transform series 
  if(transform & min(x,na.rm = T) >=0){
    lambda <- BoxCox.lambda(na.contiguous(x))
    x<- BoxCox(x,lambda =lambda )
  }
  else{
    lambda <- NULL
    transform <-F
  }
  #for seasonal data decomposing using stl
  if(frequency(x)>1){
    x.stl <- stl(x, s.window = "periodic", na.action = na.contiguous)
    trend <-x.stl$time.series[,2]
    season <- x.stl$time.series[,1]
    remainder <- x.stl$time.series[,3]
    model<- x.stl
   }
  #for non seasonal data
  else{
    require(mgcv)
    tt <- 1:length(x)
    trend <- rep(NA,length(x))
    trend[!is.na(x)]<- fitted((gam(x~s(tt))))
    season <-NULL
    remainder <- x-trend
    model<- auto.arima(x)
  }
  return(list("trend"=trend,"seasonal"=season,"remainder"=remainder,"tranform"=transform,"lambda"=lambda,"model"=model))
}
#outlier detection
detect_outliers<- function(x, method="Student",...){
  #outlier detection using extreme studentized test
  outliers<- rep(F, length(x))
  if(method=="Student"){
    mean<- mean(x)
    sd<- sd(x)
    outliers<- Mod(x-mean)/sd > 3 & sd!=0
  }
  if(method=="boxplot"){
    stats<- boxplot.stats(x,...)
    outs<- stats$out
    outliers[which(x %in% outs)]<-T
  }
  if(method=="twitter"){
    library(AnomalyDetection)
    result<- AnomalyDetectionTs(x,direction = 'both', plot=T,...)
    outliers<-which(x$runtime %in% result$anoms[[2]])
  }
  return(outliers)
}
#returns overall trend as increasing or decreasing or constant
overall_trend<-function(y, lowpass, hypass){
  #fits a straight line using linear regression
  x<- 1:length(y)
  fit<- lm(y~x)
  slope<- fit[[1]][2]
  constant<- fit[[1]][1]
  if(slope<hypass) trend="decreasing"
  else if (slope>lowpass) trend="increasing"
  else trend="constant"
  return(list("trend"=trend,"slope"=slope,"constant"=constant))
}
#function to cluster time series data 
cluster_series<- function(series,type="hierarchical",method="DTW",clusters=3,...){
  library(dtw)
  if(type=="hierarchical"){
    #create a distance matrix using DTW distances
    distmatrix<- dist(series,method = method,...)
    #perform hierarchical clustering
    hc<- hclust(distmatrix,method="average",...)
    memb<- cutree(hc,clusters)
  }
  if(type=="kmeans"){
    kmeans<- kmeans(series,centers=clusters,...)
    memb<- kmeans$cluster
  }
  return(memb)
}
#function to detect changepoints in time series
find_changepoints<- function(series,method="Student",...){
  library(cpm)
  cpts<-processStream(series,cpmType = method)
  return(cpts$changePoints)
}
#rm(ts1,fore,clusters,cpts,filepath,freq,order,outliers,result,trend)
# read the intermediate file
job_stats_derived_intermediate <- read.csv(filepath)
output<- sapply(split(job_runhistory_annotated, factor(job_runhistory_annotated$jobname)), function(sampled){
  #order the data according to the date
  order<- order(as.Date(sampled$date,format="%m/%d/%Y"))
  sampled<- sampled[order,]
  # first find the frequency of required time series
  freq<- find.freq(sampled$runtime)
  #create a time series object using ts
  ts1<- ts(sampled$runtime,frequency=freq)
  #find overall trend
  trend<- overall_trend(sampled$runtime)
  #find outliers in this series
  outliers<- detect_outliers(sampled$runtime)
  #find change points
  cpts<- find_changepoints(sampled$runtime)
  # apply hierarchical clustering using DTW distances
  #clusters<- cluster_series(sampled$runtime)
  # decompose series to find trend and seasonality
  result<- decomp(ts1,T)
  # forecast using ARIMA/STL Model
  library(forecast)
  fore<- forecast(result$model)
  
  result.df<- list("frequency"=freq,"outliers"=which(outliers==T),"changePoints"=cpts,
                   "timeSeries"=ts1,"Trend"=result$trend,"Seasonality"=result$seasonal,
                   "remainders"=result$remainder,"Overall Trend"=trend$trend)
  result.df
  
})
output<- sapply(split(job_stats_derived_intermediate, as.factor(job_stats_derived_intermediate$jobname)), function(sampled){
  order<- order(as.Date(sampled$date,format="%m/%d/%Y"))
  sampled<- sampled[order,]
  ts<- ts(sampled$runtime)
  list("timeseries"=ts,"jobname"= sampled$jobname[1]) 
})