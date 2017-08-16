filepath.1<-"F:/pdf/R/sampledata/input/job_dependencies.csv";
filepath.2<-"F:/pdf/R/sampledata/input/job_stream_map.csv";
#output file
filepath.3<-"F:/pdf/R/sampledata/input/stream_graph_table.csv"
#one of the output file as input 
filepath.4<-"F:/pdf/R/sampledata/blueprint/jobstatstable.csv" 
job_dependencies <- read.csv(filepath.1);
job_stream_map <- read.csv(filepath.2);
job_dependencies.1<-merge(job_dependencies,job_stream_map,by.x = "JobName",by.y ="jobName",all.x = T )
job_dependencies.2<-merge(job_dependencies.1,job_stream_map,by.x = "PredecessorName",by.y ="jobName",all.x = T )
names(job_dependencies.2)<-c("PredecessorName","JobName","streamName","parentStream");
# remove entries where both parent and child stream are different
job_dependencies.3<-job_dependencies.2[job_dependencies.2$streamName==job_dependencies.2$parentStream,]
#remove NA entries
job_dependencies.3<-job_dependencies.3[!is.na(job_dependencies.3$streamName),]
result.1<-sapply(split(job_dependencies.3,factor(job_dependencies.3$streamName)),function(row){
  joint<-paste("{s:",row$JobName,",d:",row$PredecessorName,"}")
  jobs<-unique(c(as.character(row$JobName),as.character(row$PredecessorName)))
  output<-list("Edges"=paste(collapse = ", ",joint),"noOfJobs"=length(jobs))
  output$jobs<- paste(jobs,collapse = ", ")
  output
})
#transform list into data frame
result.1<-as.data.frame(t(result.1))
result.1$StreamName<-row.names(result.1)
jobstatstable <- read.csv(filepath.4)
result.2<-sapply(split(jobstatstable,factor(jobstatstable$streamname)),function(row){
  index<-row$isroot==T
  jobs<-row$jobname[index]
  list("rootJobs"=paste(jobs,collapse = ", "),"NoOfRootJobs"=length(jobs))
})
result.2<-as.data.frame(t(result.2))
result.2$StreamName<-row.names(result.2)
result.3<-merge(result.1,result.2,by="StreamName")
#converting it into data frame for storing in csv file
result.1<-do.call("cbind",lapply(result.3,as.character))
write.csv(result.1,filepath.3,row.names = F)
rm(job_dependencies.1,jobstatstable,job_dependencies,job_dependencies.2,job_dependencies.3,job_stream_map)
rm(result.1,result.2,result.3)
rm(filepath.1,filepath.2,filepath.3,filepath.4)