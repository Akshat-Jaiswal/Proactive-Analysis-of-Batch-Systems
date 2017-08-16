# weekly analysis
filepath<-"F:/pdf/R/sampledata/output/job_stats_derived_intermediate.csv"
filepath.2<-"F:/pdf/R/sampledata/output/weekly_analysis.csv"
rootdirectory<- "F:/pdf/R/sampledata/UI/output";

job_stats_derived_intermediate<- read.csv(filepath)
job_stats_derived_intermediate<- subset(job_stats_derived_intermediate,jobname!="#N/A")
job_stats_derived_intermediate<- transform(job_stats_derived_intermediate, jobstatus= factor(jobstatus))
job_stats_derived_intermediate$day<- weekdays(as.Date(job_stats_derived_intermediate$date,format="%m/%d/%Y"))
job_stats_derived_intermediate<- transform(job_stats_derived_intermediate, day= factor(day))
splitter<- paste(job_stats_derived_intermediate$jobname,job_stats_derived_intermediate$day)
job_stats_derived_intermediate$splitter<- splitter                 
rm(splitter)
# replace all NA entries with False
job_stats_derived_intermediate[is.na(job_stats_derived_intermediate)]<-F
output<- sapply(split(job_stats_derived_intermediate, as.factor(job_stats_derived_intermediate$splitter)), function(sampled){
  output<- list()
  output$jobName<- as.character(sampled$jobname[1])
  output$day<- as.character(sampled$day[1])
  output$runcount<- length(sampled$runtime)
  output$failcount<- sum(sampled$jobstatus==32)
  output$minalertcount<- sum(sampled$minalert)
  output$maxalertcount<- sum(sampled$maxalert)
  output$startslaviolationcount<- sum(sampled$starttimeviolated)
  output$endslaviolationcount<- sum(sampled$endtimeviolated)
  output$avgRuntime<- mean(sampled$runtime)
  output$avgWorkload<- mean(sampled$workload)
  output
  })
output<- data.frame(t(output))
output.df<-do.call("cbind",lapply(output, as.character))

write.csv(output.df,filepath.2,row.names = F,na="")
output<- read.csv(filepath.2)
sapply(split(output,factor(output$jobName)), function(sampled){
  jobName=sampled$jobName[[1]]
  if(!dir.exists(paste(rootdirectory,jobName,sep = "/"))){
    dir.create(paste(rootdirectory,jobName,sep = "/"))
  }
  #sampled.df<- do.call("cbind",lapply(as.data.frame(sampled), as.character))
  write.csv(sampled,paste(rootdirectory,jobName,"week_stats.csv", sep = "/"), row.names = F)
})
rm(output, output.df)