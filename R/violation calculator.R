#merge the two tables
job_runhistory_annotated.1<-merge(job_runhistory_annotated,by="jobname",job_thresholds[,c("starttimesla","endtimesla","minrunalarmthreshold","maxrunalarmthreshold","jobname","nextday")]);
#function to calculate violations
violationCalculator<-function(row){
  # initializing variable
  st<-row["starttime"]
  et<-row["endtime"]
  sts<-row["starttimesla"]
  ets<-row["endtimesla"]
  runtime<-row["runtime"]
  minrunalarm<-row["minrunalarmthreshold"]
  maxrunalarm<-row["maxrunalarmthreshold"]
  stviolated<-0;
  etviolated<-0;
  minrunalert<-0;
  maxrunalert<-0;
  st<-strptime(st,"%m/%d/%Y %H:%M");
  et<-strptime(et,"%m/%d/%Y %H:%M");
  
    #first calculate start time violation
  if(sts!="" && !is.na(sts)){
    sts<-strptime(paste(row["date"],sts),"%m/%d/%Y %H:%M");
    if(st>sts) stviolated<-1;
  }
  #now calculating end time violation
  if(ets!="" && !is.na(ets)){
    ets<-strptime(paste(row["date"],ets),"%m/%d/%Y %H:%M");
    if(ets<st) ets<-ets+24*60*60;
    if(et>ets) etviolated<-1;
  }
  #calculating min run alarm alert
  #if(runtime<minrunalarm && !is.na(minrunalarm) && minrunalarm!="") minrunalert<-1;
  #calculating max run alarm alert
  #if(runtime>maxrunalarm && !is.na(maxrunalarm) && maxrunalarm!="") maxrunalert<-1;
  list("starttimeviolated"=stviolated,"endtimeviolated"=etviolated);
}
#now apply the function to each entry
result<-apply(job_runhistory_annotated.1,1,violationCalculator)
#seperate each individual result
result<-t(sapply(result,unlist))
#bind the result together with the table
job_runhistory_annotated.2<-cbind(job_runhistory_annotated.1,result)
job_runhistory_annotated.2$minalert<-job_runhistory_annotated.2$runtime<job_runhistory_annotated.2$minrunalarmthreshold
job_runhistory_annotated.2$maxalert<-job_runhistory_annotated.2$runtime>job_runhistory_annotated.2$maxrunalarmthreshold
rm(job_runhistory_annotated.1)
calculateSummary<-function(x){
  startslaviolationcount<-sum(x$startslaviolated);
  endslaviolationcount<-sum(x$endslaviolated);
  minalertcount<-length(x$minalert[x$minalert==T])
  maxalertcount<-length(x$maxalert[x$maxalert==T]);
  ordr<-order(x$date)
  runtimes<-x$runtime[ordr];
  runcount<-length(runtimes)
  len<-1:runcount
  failurecount<-length(x$jobstatus[x$jobstatus==32])
  model<-lm(runtimes~len)
  slope<-model[[1]][2]
  intercept<-model[[1]][1]
  mean<-mean(runtimes)
  sd<-sd(runtimes)
  if(slope<0) trend<-"decreasing" else trend<-"increasing"
  # output
  
  output<-list("startslaviolationcount"=startslaviolationcount,"endslaviolationcount"=endslaviolationcount,"minalertcount"=minalertcount,"maxalertcount"=maxalertcount)
  output$runcount<-runcount;
  output$failurecount<-failurecount
  output$trend<-trend;
  output$slope<-slope;
  output$intercept<-intercept;
  output$mean<-mean
  output$sd<-sd
  outliers<-(Mod(runtimes-mean)/sd)>2
  outliercount<-length(runtimes[outliers])
  output$outliercount<-outliercount;
  require(cpm)
  cps<-processStream(runtimes,cpmType = "Student");
  output$changepoints<-cps$changePoints
  output$noofchangepoints<-length(output$changepoints)
  output;
  
}