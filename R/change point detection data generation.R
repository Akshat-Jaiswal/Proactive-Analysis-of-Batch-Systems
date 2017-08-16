maxNumberOfChangePoints <- 5 # maximal number of change points
minLambda <- 1; maxLambda <- 20 # range of how many logins we would expect on average by day
lengthOfSerSeries <- 300 # number of days 
numberOfSeries <- 10 # number of customer we want to simulate

# creates a sequence of the number of daily logins
# for one customer
generateSequence <- function(maxNumberOfChangePoints = 4, lengthOfSerSeries = 300, 
                             minLambda = 1, maxLambda = 15) {
  # get number of change points for this customer
  cp <- sample(c(1:maxNumberOfChangePoints), size=1)
  if(cp == 1){
    # get the sequence mean
    segmentMean <- sample(c(minLambda,maxLambda),1)
    # sample the number of logins
    seq <- rpois(n= lengthOfSerSeries, lambda= segmentMean)
    attr(seq,"segmentSize") <- lengthOfSerSeries
    attr(seq,"segmentMean") <- segmentMean
  }else{
    # estimate the breakpoints
    breakpoints <- sort(sample(c(2:(lengthOfSerSeries-1)),cp)) 
    segmentSize <- diff(c(0,breakpoints,lengthOfSerSeries))
    # estimate the average for each sequence
    segmentMean <- sample(c(minLambda:maxLambda),size = (cp+1))
    seq <- unlist(sapply(1:(cp+1), function(i){
      # sample the number of logins
      rpois(n= segmentSize[i], lambda= segmentMean[i])
    }, simplify = TRUE))
    attr(seq,"segmentSize") <- segmentSize
    attr(seq,"segmentMean") <- segmentMean
  }
  return(seq)
}

# creates all the sequences for the specified number of customers
loginSeqs <- replicate(n = numberOfSeries, 
                       generateSequence(maxNumberOfChangePoints,
                                        lengthOfSerSeries, minLambda, maxLambda), 
                       simplify = FALSE)
# create a data frame that stores all the information in the "long" format
# (+ "parameter signature" that can be used later in Tableau as label)
toyData <- data.frame(DAY = rep(seq(as.Date("2014-01-01 00:00:00"), 
                                    as.Date("2014-01-01 00:00:00") + (lengthOfSerSeries-1), 
                                    by="day"), times = numberOfSeries),
                      customerid = sort(rep(c(1:numberOfSeries), times = lengthOfSerSeries)),
                      numberOfLogins = unlist(loginSeqs),
                      trueMean = unlist(sapply(loginSeqs,function(i){
                        rep(attr(i,"segmentMean"),attr(i,"segmentSize"))
                      }, simplify = FALSE)), # add column containing the true mean value
                      signature = unlist(sapply(loginSeqs,function(i){ # save parameters
                        s1 <- paste("(Br(",length(attr(i,"segmentSize"))-1,")=[",sep="")
                        s2 <- paste(format(as.Date("2014-01-01 00:00:00")+
                                             cumsum(attr(i,"segmentSize")
                                                    [-length(attr(i,"segmentSize"))]+1),
                                           "%d.%b"),
                                    collapse=",",sep="")
                        s3 <- "] SegMeans=["
                        s4 <- paste(attr(i,"segmentMean"),collapse=",",sep="")
                        s5 <- "])"
                        rep(paste(s1,s2,s3,s4,s5,sep=""), times = lengthOfSerSeries)
                      }, simplify = FALSE))
)
# store parameters as attribute of the data frame
creationParameters <- sapply(loginSeqs,function(i){ # save parameters
  list(segmentSize = attr(i,"segmentSize"), segmentMean = attr(i,"segmentMean"))
}, simplify = FALSE)
attr(toyData,"creationParameters") <- creationParameters # attache parameters

# save as RData file
save(toyData, 
     file = paste("GENERATED_CUSTOMERACTIVITY_DATA_",
                  format(Sys.time(),"%y%m%d_%H%M%S"),".RData",sep=""))

# save as Excel file 
# for excel export - http://cran.r-project.org/web/packages/XLConnect/vignettes/XLConnect.pdf
#require(XLConnect)
#wb = loadWorkbook(paste("DATA/GENERATED_CUSTOMERACTIVITY_DATA_",
 #                       format(Sys.time(),"%y%m%d_%H%M%S"),".xlsx",sep=""),
  #                create = TRUE)
#createSheet(wb, "CUSTOMERACTIVITY")
#writeWorksheet(wb, toyData, "CUSTOMERACTIVITY")
#saveWorkbook(wb)