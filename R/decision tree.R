fitted.results <- ifelse(predicted > 0.5,1,0)

misClasificError <- mean(fitted.results != train$V1)
print(paste('Accuracy',1-misClasificError))
plot(sampled$runtime,type="l",main="Runtime Over Time",xlab="Time",ylab="Runtimes")
points(outliers,sampled$runtime[outliers],pch="+",cex=1.5,col="orange")
points(cpts,sampled$runtime[cpts],pch="*",cex=2,col="blue")
lines(1:length(sampled$runtime),result$trend,col="blue")
abline(result.1$constant,result.1$slope,lty=2,col="orange")
legend("topright",c("Outliers","Changepoints","Trend","Overall Trend (Decreasing)"),pch=c("+","*","",""),col=c("orange","blue","blue","orange"),lty=c(0,0,1,2),y.intersp = .5)

xyplot(runtime~date |day, job_stats_derived_intermediate,panel = function(x,y,...){
  panel.xyplot(x,y,...)
})
filepath<-"F:/pdf/R/sampledata/output/job_stats_derived_intermediate.csv"
job_stats_derived_intermediate<- read.csv(filepath)
test<- job_stats_derived_intermediate[job_stats_derived_intermediate$jobname=="hpc_idphi_sealimit",]
attach(job_stats_derived_intermediate)
job_stats_derived_intermediate<- transform(job_stats_derived_intermediate, jobstatus= factor(jobstatus))
job_stats_derived_intermediate$day<- weekdays(as.Date(job_stats_derived_intermediate$date,format="%m/%d/%Y"))
job_stats_derived_intermediate<- transform(job_stats_derived_intermediate, day= factor(day))
# creating a sample for testing data
set.seed(6)
failedjobs<- which(job_stats_derived_intermediate$jobstatus==32) 
testsample1<- sample(failedjobs, 50)
testsampled2<- sample(1: length(job_stats_derived_intermediate$jobstatus), 100)
test<- c(testsample1, testsampled2)
training<- job_stats_derived_intermediate[-c(test),]
test<- job_stats_derived_intermediate[c(test),]
rm(testsample,testsample1,testsampled2)
formula<- jobstatus~ day+ runtime+ starttimeviolated+ endtimeviolated+ minalert+ maxalert+ minrunalarmthreshold+ maxrunalarmthreshold+ workload
library(party)
dtree<- ctree(formula, training)