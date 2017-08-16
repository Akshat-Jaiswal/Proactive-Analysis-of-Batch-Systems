// JavaScript Document
// script to display temporal patterns on screen
min2y=max2y=0;	
	var jobName= getQueryString("jobName");
	var rootDirectory="output/"
	var filepath2=rootDirectory+jobName+"/temporal_patterns.csv";
    var series=[]
	d3.csv(filepath2,function(data) {
		// first find the keys of dataset
		for( var key in data[0]){
			if(key!="date")
			series[key]=[]
		}
		data.forEach(function(d){
			for(var key in d){
			 var dt= new Date(Date.parse(d.date));
			 if(key!="date"){
			 	series[key].push({x:dt,y:d[key]});
				min2y=min2y> parseFloat(d[key])?parseFloat(d[key]):min2y;
				max2y=max2y< parseFloat(d[key])?parseFloat(d[key]):max2y;
			 }
			}	
		})
		console.log("logging temporal data read");
		console.log(series) 
		// create data from series for use in chart and display
		var displayData=[]
		for(var key in series){
			displayData.push( {"key":key, "values": series[key]}) 
		}
		console.log(displayData);
		
		// create a chart using nv
		  var chart = nv.models.lineChart()
                .margin({left: 100})  //Adjust chart margins to give the x-axis some breathing room.
                .useInteractiveGuideline(true)  //We want nice looking tooltips and a guideline!
               // .transitionDuration(350)  //how fast do you want the lines to transition?
                .showLegend(true)       //Show the legend, allowing users to turn on/off line series.
                .showYAxis(true)        //Show the y-axis
                .showXAxis(true)        //Show the x-axis
 		 ;
		 chart.xAxis     //Chart x-axis settings
      .axisLabel('Date')        
      .tickFormat(function(d){
		  return d3.time.format('%b %d %Y')(new Date(d));		  
	   });
 
	  chart.xScale(d3.time.scale())
	  //chart.yScale(d3.range(1000,5000));
	  chart.yDomain([-2*max2y,2*max2y])
	  if(min2y>0)
	  chart.yDomain([0,2*max2y])
 	  chart.yAxis     //Chart y-axis settings
		  //.axisLabel('Count')
		  .tickFormat(d3.format('.02f'));
	  d3.select('#pattern svg')    //Select the <svg> element you want to render the chart in.   
		  .datum(displayData)         //Populate the <svg> element with chart data...
		  .call(chart);          //Finally, render the chart!
	
	  //Update the chart when window resizes.
	  nv.utils.windowResize(function() { chart.update() });

	})