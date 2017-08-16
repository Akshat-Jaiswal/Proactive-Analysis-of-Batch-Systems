#require(cpm)
x <- sampled$numberOfLogins; startupPeriod = 20; testStatistic = "Student"

resMW <- processStream(x, cpmType=testStatistic, ARL0=500, startup=startupPeriod)
breaks <- diff(c(0,resMW$changePoints,length(x)))
trendGroup <- unlist(sapply(c(1:length(breaks)), function(i){
  rep(i,breaks[i])
}))

segmentMeanValues <- rep(tapply(x, trendGroup, mean), breaks)
detectionTimeValues <- rep(0, length(x))
detectionTimeValues[resMW$detectionTimes] <- x[resMW$detectionTimes]

return(paste(segmentMeanValues,detectionTimeValues, sep="~"))
# '
# ,SUM([numberOfLogins]), [CPM_Startup], [CPM_Test_Statistic])