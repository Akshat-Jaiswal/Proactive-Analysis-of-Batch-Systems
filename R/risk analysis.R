# script to perform risk analysis 
filepath<-"F:/pdf/R/sampledata/output/job_stats.csv"
filepath.2<-"F:/pdf/R/sampledata/output/risk_assessment.csv"
#   helper function for labelling
#   @param x:   the value to be classified   
#   @param min: minimum value of distribution of X
#   @param max: maximum value of distrubution of X
#   @param classes: vector containning the class labels
#   
#   the function uniformly divides the complete range into n equal
#   intervals where n= number of classes and then decides the class label
#   according to the interval where x fits
#   @return "character" : One of the classes from argument classes
#
classifyInto<- function(x,min,max,classes) {
  if(length(classes)==0) stop("Classes Not specified")
  # count the number of classes
  steps<- length(classes)  
  # interval length for each class segment
  interval<- (max-min)/steps
  range=interval
  i=1;
  while( x> range) {
    range=range+interval
    i<- i+1
  }
  
  output<- classes[i]
  output
}

job_stats<- read.csv(filepath)
riskMatrix<- job_stats[,c("JobName","uptreesize","downtreesize","runcount","failurecount")]
names(riskMatrix)[c(2,3)]<- c("vulnerability","impact")
#
#   calculating the probability of failure (P)= failed count/ total run count
#
riskMatrix$probabilityOfFailure<- riskMatrix$failurecount/ riskMatrix$runcount
#   replacing any NA entries with 0
#
riskMatrix$probabilityOfFailure[is.na(riskMatrix$probabilityOfFailure)]<-0
#
#   Impact is calculated usinh the downtree size of each node
#   Higher the downtree size Higher is its impact
#   normalize the impact scores using min-max normalization
#
max<-max(riskMatrix$impact)
min<- min(riskMatrix$impact)
#   normalized Value
riskMatrix$impact<- (riskMatrix$impact-min)/(max-min)
#
#   Vulnerability is the probability of failure of a job due to 
#   failure of any of its parent jobs
#   vulnerability score is calculated using the uptree size of any node
#   now normalize the vulnerability score
#
max<- max(riskMatrix$vulnerability)
min<- min(riskMatrix$vulnerability)
#normalized Value
riskMatrix$vulnerability<- (riskMatrix$vulnerability-min )/(max-min)

# normalize probability of failure
max<- max(riskMatrix$probabilityOfFailure)
min<- min(riskMatrix$probabilityOfFailure)
# normalized value
riskMatrix$probabilityOfFailure<- (riskMatrix$probabilityOfFailure)/(max-min)

#   now calculating the risk score
riskMatrix$riskScore<- riskMatrix$impact*(riskMatrix$vulnerability+riskMatrix$probabilityOfFailure)

#   now label the classes for each classifier
riskMatrix$impactClassifier<-sapply(riskMatrix$impact, classifyInto,0,1,c("Trivial","Minor","Moderate","Major","Extreme"))
riskMatrix$vulnerabilityClassifier<-sapply(riskMatrix$vulnerability,classifyInto,0,1,c("Trivial","Minor","Moderate","Major","Extreme"))
riskMatrix$failureClassifier<- sapply(riskMatrix$probabilityOfFailure, classifyInto,0,1,c("Rare","Unlikely","Moderate","Likely","Frequent"))
max<- max(riskMatrix$riskScore)
min<- min(riskMatrix$riskScore)
riskMatrix$riskClassifier<- sapply(riskMatrix$riskScore,classifyInto, min, max,c("Minimal","Minor","Moderate","Significant","Severe"))

#   converting the list into a data frame so that it easier to write into a CSV file
riskMatrix.df<-do.call("cbind",lapply(riskMatrix, as.character))
write.csv(riskMatrix.df,filepath.2,row.names = F,na="")
#   remove all the used variables to clean the space
rm(riskMatrix.df, riskMatrix, max, min, job_stats, filepath.2,filepath,classifyInto)