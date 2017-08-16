# script to find interstream dependencies
filepath.1<-"F:/pdf/R/sampledata/input/job_dependencies.csv";
filepath.2<-"F:/pdf/R/sampledata/input/job_stream_map.csv";
filepath.3<-"F:/pdf/R/sampledata/output/inter_stream_connections.csv"
job_dependencies <- read.csv(filepath.1);
job_stream_map <- read.csv(filepath.2);
job_dependencies.1<-merge(job_dependencies,job_stream_map,by.x = "JobName",by.y ="jobName",all.x = T )
job_dependencies.2<-merge(job_dependencies.1,job_stream_map,by.x = "PredecessorName",by.y ="jobName",all.x = T )
names(job_dependencies.2)<-c("PredecessorName","JobName","streamName","parentStream");
# remove entries where both parent and child stream are same
job_dependencies.3<-job_dependencies.2[job_dependencies.2$streamName!=job_dependencies.2$parentStream,]
#remove NA entries
job_dependencies.3<-job_dependencies.3[!is.na(job_dependencies.3$streamName),]
#create a factor to split
job_dependencies.3$factor<-paste(job_dependencies.3$streamName,job_dependencies.3$parentStream,sep=", ")
#now split the entries according to factor
splitbyfactor<-split(job_dependencies.3,factor(job_dependencies.3$factor))
# apply looping function to calculate stats for each factor
result<-sapply(splitbyfactor,function(row) { 
    chcount<-length(unique(row$JobName));
    pcount<-length(unique(row$PredecessorName))
    list<-list("childinfluencingcount"=chcount,"parentinfluencingcount"=pcount)
    list$streamName<- as.character(row$streamName[1])
    list$parentStreamName<- as.character(row$parentStream[1])
    list$dependentJobs<- paste(unique(row$JobName), collapse = ",")
    list$parentJobs<- paste(unique(row$PredecessorName), collapse = ",")
    list
})
result<-as.data.frame(t(result))
# convert List object to dataframe for writing it into a CSV file
result.2<- do.call("cbind",lapply(result, as.character))
write.csv(result.2,filepath.3,row.names = F)
# clean the used space
rm(job_dependencies.3,job_dependencies.2,job_dependencies.1,job_stream_map,job_dependencies,result)#,names,newcolumns)
rm(splitbyfactor,filepath.2,filepath.1,result.2,filepath.3)
