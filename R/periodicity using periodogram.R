# script to perform timeSeries Analysis Part 2
# Calculates periodicity of time series and forecast the future behavior
# @depends: GeneCycle, AnomalyDetection, Forecast
# path to the internediate file create when job_stats are calculated
filepath<-"F:/pdf/R/sampledata/output/job_stats_derived_intermediate.csv"
# directoruy where to save output of all jobs 
rootdirectory<- "F:/pdf/R/sampledata/UI/output";
job_stats_derived_intermediate<- read.csv(filepath)
# remove #N/A entries from the file
job_stats_derived_intermediate<- subset(job_stats_derived_intermediate,jobname!="#N/A")
result<-sapply( split(job_stats_derived_intermediate, factor(job_stats_derived_intermediate$jobname)),function(sampled){
  #sampled<-subset(job_stats_derived_intermediate,jobname=="bmxftp_fscs_adj_folder_for_caw")
  jobName=sampled$jobname[1]
  # order the time series according to the date
  sampled<- sampled[order(sampled$date),]
  # plot the initial time series
  plot.ts(sampled$runtime, xlab=sampled$jobname[1])
  
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
  # STEP $ Find the periodicity of series using periodogram
  periodogram<- GeneCycle::periodogram(zooseries)
  # plot the periodogram
  # plot(periodogram$freq,periodogram$spec[,1], type="h")
  # Extract the dominant frequencies using box plot outlier detection
  outs<- boxplot.stats(periodogram$spec[,1])
  # case 1: when no dominant frequencies are present then set frequency to 1
  if(length(outs$out)==0){
    freq<-1
  } else {
    # extract the dominant frequiencies
      indices<-which(periodogram$spec[,1] %in% outs$out)
      periods<-round(1/periodogram$freq[indices])
    # remove duplicate entries
      periods<- unique(periods)
    # use kmeans clustering to find frequencies
      if(length(periods)<=3){
       freq<- sort(periods) 
      } else {
        centers<-1
      # Select only those frequencies which have significant difference between them
      # e.g. out of 5,7,8 only the one which is most dominant is selected
        if(max(Mod(diff(periods))>=3)){ centers<-3} 
        kmeans<- kmeans(periods,centers = centers)
        mat<- cbind(indices, periods, periodogram$spec[indices,1],kmeans$cluster)
        mat<- as.data.frame(mat)
        freq<-sapply(split(mat,factor(mat$V4)),function(sampled){ sampled[which.max(sampled[,3]),2] })
        freq<- sort(as.vector(freq))
        freq
        }
  }
   # freq
   # corresponding to each frequency using stl seasonal component are extracted
   output<- do.call(cbind, sapply(freq, function(data){
      name=paste("Period ",data)
      if(data!=1){
        res<-tryCatch({ res<-stl(ts(zooseries, frequency=data), s.window = data)
        list(name=as.vector(res$time.series[,"seasonal"]))
        }, error= function(e){ 
      # in case of error that is when no pattern can be extracted simply log transform the series    
          list(error=log(UI$runtime)) })
      } else list(log(UI$runtime))
    }))
   # create a dataframe with columns represting the seasonal component extracted corresponding to that frequency
   output<- data.frame("date"=UI$date,output)
   err<-which(names(output)=="error")
   if(length(err!=0)){
     output<- output[,1:(err-1)]
     names(output)<- c("date",paste("Periodicity",freq[1:(err-2)], sep = " "))
     
   } else {
     names(output)<- c("date",paste("Periodicity",freq, sep = " "))
   }
     
   # create a directory if it don't exist
   if(!dir.exists(paste(rootdirectory,jobName,sep = "/"))){
     dir.create(paste(rootdirectory,jobName,sep = "/"))
   }
   write.csv(output,paste(rootdirectory,jobName,"temporal_patterns.csv", sep = "/"), row.names = F)
  
   
   # STEP 5 Forecast the future behavior
   # forecast the behavior using stl
   # in case when stl fails use ARIMA models
   if(sum(freq==1)==0) { 
     fit<- tryCatch(stl(ts(zooseries, frequency=min(freq)), s.window = min(freq))
            , error=function(e){
              forecast::auto.arima(UI$runtime)
            })
     } else { 
     fit<- forecast::auto.arima(UI$runtime)
   }
   fore<- forecast::forecast(fit)
   UI$date<- as.Date(UI$date,format="%m/%d/%Y")
   # calulating the no. of days forecast is to be calculated 
   # min for next 2 observations and max 10 next observations
   nheads<- min(10,max(2,len/10))
   nheads<- min(nheads,nrow(fore$lower))
   #extract the forecast values from the variable and generating dates corresponding to those forecast
   forecast.df<- data.frame(fore$lower[1:nheads,],fore$upper[1:nheads,]) 
   names(forecast.df)<- c("lower 80","lower 95","upper 80","upper 95")
   forecast.df$pointForecast<- apply(forecast.df,1,mean)
   # difference between successive observations
   timediff<- UI$date[len]-UI$date[len-1]
   # date vector to hold forecast dates
   dates<- c()
   # generating dates using loop
   prev=UI$date[len]
   for(i in (1:nheads)){
     dates[i]=prev+timediff
     prev<- dates[i]
   }
   forecast.df$date<-as.Date(dates)
   #forecast.df$date<- strptime(forecast.df$date,format="%Y-%m-%d")
   # create a directory if it don't exist
   if(!dir.exists(paste(rootdirectory,jobName,sep = "/"))){
     dir.create(paste(rootdirectory,jobName,sep = "/"))
   }
   write.csv(forecast.df,paste(rootdirectory,jobName,"forecast.csv", sep = "/"), row.names = F)
}) # end of sapply
# clean up the used variables
rm(job_stats_derived_intermediate,result,filename,rootdirectory)