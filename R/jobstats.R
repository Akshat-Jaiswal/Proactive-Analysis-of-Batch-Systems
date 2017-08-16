filepath.1<-"F:/pdf/R/sampledata/input/job_dependencies.csv";
filepath.2<-"F:/pdf/R/sampledata/input/job_about.csv";
filepath.3<-"F:/pdf/R/sampledata/input/job_runhistory_annotated.csv";
filepath.4<-"F:/pdf/R/sampledata/input/job_thresholds.csv";
filepath.5<-"F:/pdf/R/sampledata/output/job_stats_derived_intermediate.csv"
filepath.6<-"F:/pdf/R/sampledata/output/job_stats.csv"
job_dependencies <- read.csv(filepath.1);
#convert blank entries to NA to avoid confusion
job_dependencies$PredecessorName[job_dependencies$PredecessorName==""]<-NA
#find children for each job
childs<-sapply(split(job_dependencies,factor(job_dependencies$PredecessorName)),function(x){ 
  len<-length(x$JobName[!is.na(x$JobName)]); 
  names<-toString(x$JobName); 
  list("count"=len,"outdegreejobs"=names)
})
childs<-as.data.frame(t(childs))
parents<-sapply(split(job_dependencies,factor(job_dependencies$JobName)),function(x){ 
  len<-length(x$PredecessorName[!is.na(x$PredecessorName)]); 
  names<-toString(x$PredecessorName); 
  list("count"=len,"outdegreejobs"=names)
})
parents<-as.data.frame(t(parents))
childs.1<-cbind(childs,"JobName"=row.names(childs))
parents.1<-cbind(parents,"JobName"=row.names(parents))
rm(parents,childs)
complete<-merge(childs.1,parents.1,by="JobName",all=T,incomparables = NA)
names(complete)<-c("JobName","outdegree","outdegreejobs","indegree","indegreejobs")
#coercing to integers
complete$outdegree<-as.integer(as.character(complete$outdegree))
complete$indegree<-as.integer(as.character(complete$indegree))
#replace NA entries with 0
complete$indegree[is.na(complete$indegree)]<-0
complete$outdegree[is.na(complete$outdegree)]<-0
#add isroot and is leaf columns
complete$isRoot<-complete$indegree==0
complete$isLeaf<-complete$outdegree==0
rm(parents.1,childs.1)
job_about<-read.csv(filepath.2);
complete.1<-merge(complete,job_about[,c("jobname","streamname","hostname")],by.x = "JobName",by.y = "jobname",all.x = T,incomparables = NA)
rm(complete)

require(igraph)
#creating a graph after removing NA entries
g<-graph_from_data_frame(job_dependencies[!is.na(job_dependencies$PredecessorName),])
#get vertexname and Id map
vertices<-V(g)
vertexNames<-as.data.frame(factor(vertices))
vertices<-row.names(vertexNames)
dim(vertices)<-c(length(vertices),1)
rm(vertexNames)
downtreeresult<-sapply(vertices,function(root){
  res<-dfs(g,root = root,unreachable = F,neimode = "in",order.out = F)
  index<-as.vector(res$order[!is.na(res$order)]);
  downtreesize<-length(index)-1 # removing self count;
  downtreejobs<-paste(collapse = ", ",vertices[index[-1]]);
  list("downtreesize"=downtreesize,"downtreejobs"=downtreejobs);
})
downtreeresult<-as.data.frame(t(downtreeresult))
downtreeresult$JobName<-row.names(downtreeresult)
complete.2<-merge(complete.1,downtreeresult,all.x=T,by="JobName")
rm(complete.1,downtreeresult)
#now calculating uptree details
uptreeresult<-sapply(vertices,function(root){
  res<-dfs(g,root = root,unreachable = F,neimode = "out",order.out = F)
  index<-as.vector(res$order[!is.na(res$order)]);
  downtreesize<-length(index)-1 # removing self count;
  downtreejobs<-paste(collapse = ", ",vertices[index[-1]]);
  list("uptreesize"=downtreesize,"uptreejobs"=downtreejobs);
})
uptreeresult<-as.data.frame(t(uptreeresult))
uptreeresult$JobName<-row.names(uptreeresult)
complete.3<-merge(complete.2,uptreeresult,all.x=T,by="JobName")
rm(complete.2,uptreeresult,g,vertices)
#now calculating violations
job_runhistory_annotated <- read.csv(filepath.3)
job_thresholds <- read.csv(filepath.4)
#merge 2 tables
job_runhistory_annotated.1<-merge(job_runhistory_annotated,by="jobname",job_thresholds[,c("starttimesla","endtimesla","minrunalarmthreshold","maxrunalarmthreshold","jobname","nextday")])
#convert string to appropiate date format
starttime<-strptime(job_runhistory_annotated.1$starttime,"%m/%d/%Y %H:%M");
endtime<-strptime(job_runhistory_annotated.1$endtime,"%m/%d/%Y %H:%M");
date<-strptime(job_runhistory_annotated.1$date,"%m/%d/%Y")
starttimesla<-strptime(paste(date,job_runhistory_annotated.1$starttimesla),"%Y-%m-%d %H:%M")
endtimesla<-strptime(paste(date,job_runhistory_annotated.1$endtimesla),"%Y-%m-%d %H:%M")
#index where nextday =True
index<- job_runhistory_annotated.1$nextday==T
#converting NAs to false to avoid confusion
index[is.na(index)]<-F
endtimesla[index]<-endtimesla[index]+24*60*60
#creating new columns for violations
job_runhistory_annotated.1$starttimeviolated<-starttime > starttimesla
job_runhistory_annotated.1$endtimeviolated<- endtime > endtimesla
job_runhistory_annotated.1$minalert<-job_runhistory_annotated.1$runtime<job_runhistory_annotated.1$minrunalarmthreshold
job_runhistory_annotated.1$maxalert<-job_runhistory_annotated.1$runtime>job_runhistory_annotated.1$maxrunalarmthreshold
rm(starttimesla,endtimesla,date,starttime,endtime,job_runhistory_annotated)
write.csv(job_runhistory_annotated.1,filepath.5)
#function to calculate summary for each job
calculateSummary<-function(x){
  
  startslaviolationcount<-length(x$starttimeviolated[x$starttimeviolated==T & !is.na(x$starttimeviolated)]);
  endslaviolationcount<-length(x$endtimeviolated[x$endtimeviolated==T & !is.na(x$endtimeviolated)]);
  minalertcount<-length(x$minalert[x$minalert==T & !is.na(x$minalert)])
  maxalertcount<-length(x$maxalert[x$maxalert==T & !is.na(x$maxalert)]);
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
  outliers<-(Mod(runtimes-mean)/sd)>3 & sd!=0
  outliercount<-length(runtimes[outliers])
  output$outliercount<-outliercount;
  require(cpm)
  cps<-processStream(runtimes,cpmType = "Student");
  output$changepoints<-paste(x$date[cps$changePoints],collapse = ", ");
  output$noofchangepoints<-length(cps$changePoints)
  output;
}
#apply this function to every jobname
result<-sapply(split(job_runhistory_annotated.1,factor(job_runhistory_annotated.1$jobname)),calculateSummary)
result<-as.data.frame(t(result))
result$JobName<-row.names(result)
#now merge this with complete.3 to generate complete job_stats table
complete.4<-merge(complete.3,result,by="JobName",all.x = T,incomparables = NA)
#convert it data.frame
complete.df<-do.call("cbind",lapply(complete.4, as.character))
write.csv(complete.df,filepath.6,row.names = F,na="")
rm(complete.3,job_dependencies,job_runhistory_annotated.1,result,job_about,job_thresholds)
rm(index,filepath.1,filepath.2,filepath.3,filepath.4,filepath.5,filepath.6)
rm(complete.df,complete.4)
