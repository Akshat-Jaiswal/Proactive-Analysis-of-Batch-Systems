// script to fetch data // JavaScript Document
/*These lines are all chart setup.  Pick and choose which chart features you want to utilize. */
var miny=0,maxy=0;
 var addScatterPlot=function(data){
	 var minalert=[],maxalert=[],starttimeviolated=[],endtimeviolated=[],noviolation=[],outlier=[], failed=[];
	 		data.forEach(function(d){
			var dt= new Date(Date.parse(d.date));
			var flag=true;
			// calculating min and max values for 
			miny= miny>parseFloat(d.runtime)?parseFloat(d.runtime):miny;
			maxy= maxy<parseFloat(d.runtime)?parseFloat(d.runtime):maxy;
			
			if(d.jobstatus==32){
				failed.push({x:dt,y:d.runtime, shape:'cross'})
				flag=false;
			
			}
			if(d.minalert=="TRUE"){
				minalert.push({x:dt,y:d.runtime, shape:'circle'})
				flag=false;
			}
			if(d.maxalert=="TRUE"){
				maxalert.push({x:dt,y:d.runtime, shape:'square'})
				flag=false;
			
			}
			if(starttimeviolated=="TRUE"){
				starttimeviolated.push({x:dt,y:d.runtime,shape:'triangle-down'})
				flag=false;
			
			}
			if(d.endtimeviolated=="TRUE"){
				endtimeviolated.push({x:dt,y:d.runtime, shape:'triangle-up'})
				flag=false;
			
			}
			if(d.outlier=="TRUE"){
				outlier.push({x:dt,y:d.runtime, shape:'cross'})
				flag=false;
			
			}
			if(flag)
				noviolation.push({x:dt,y:d.runtime, shape:'diamond'});
		});
		mydata=[];
//		if(minalert.length!=0){
			mydata.push(
			{
			key:'Min. Alert',
			values:minalert
			});
//		}
//		if(maxalert.length!=0){
			mydata.push(
			{
			key:'Max. Alert',
			values:maxalert
			});
//		}	
//		if(noviolation.length!=0){
			mydata.push(
			{
			key:'No Violation',
			values:noviolation
			});	
//		}	
			mydata.push(
			{
			key:'Failed',
			values:failed
			});

//		if(starttimeviolated.length!=0){
			mydata.push(
			{
			key:'Start Time Violated',
			values:starttimeviolated
			});
			
//		}	
//		if(endtimeviolated.length!=0){
			mydata.push(
			{
			key:'End Time Violated',
			values:endtimeviolated
			});
//		}	
//		if(outlier.length!=0){
			mydata.push(
			{
			key:'Outliers',
			values:outlier
			});
//		}	


		
		//console.log(mydata);
		chart = nv.models.scatterChart()
            .showDistX(true)
            .showDistY(true)
			 .margin({left: 100})  //Adjust chart margins to give the x-axis some breathing room.
               
			//.transitionDuration(300)
            .color(d3.scale.category10().range());
		//chart.scatter.onlyCircles(false)
        chart.dispatch.on('renderEnd', function(){
            console.log('render complete');
        });

	chart.xAxis     //Chart x-axis settings
      .axisLabel('Date')        
      .tickFormat(function(d){
		  return d3.time.format('%b %d %Y')(new Date(d)); 
		  });
 
  chart.xScale(d3.time.scale())
  //chart.yScale(d3.range(1000,5000));
  chart.yDomain([-1.2*maxy,1.2*maxy])
  if(miny>=0)
	  chart.yDomain([0,1.2*maxy])
 
  chart.yAxis     //Chart y-axis settings
      .axisLabel('Runtime')
      .tickFormat(d3.format('.02f'));

        d3.select('#chart1 svg')
            .datum(mydata)
            .call(chart);
		//console.log(mydata);
        nv.utils.windowResize(chart.update);
        chart.dispatch.on('stateChange', function(e) { nv.log('New State:', JSON.stringify(e)); });

 }
var mydata;
var timeSeries=[],trend=[],overall=[],vertical1=[],vertical2=[];
var i=1;
 var getQueryString= function(field, url){
	 var href= url? url:window.location.href;
	 var reg= new RegExp('[?&]'+field+'=([^&#]*)','i');
	 var string= reg.exec(href);
	 return string ? string[1]:null;
 }

var rootDirectory="output/"
var jobName= getQueryString("jobName");
var filepath=rootDirectory+jobName+"/test.csv";
//alert("Path to file:"+filepath)
miny=maxy=0
d3.csv(filepath, function(data){
		console.log("Data Read from csv")
		console.log(data);
		
		data.forEach(function(d){
			miny= miny>parseFloat(d.runtime)?parseFloat(d.runtime):miny;
			maxy= maxy<parseFloat(d.runtime)?parseFloat(d.runtime):maxy;
			
			++i;
			var parts= d.date.split("/");
			//var dt= new Date(parseInt()
			var dt= new Date(Date.parse(d.date));
			timeSeries.push({x:dt,y: d.runtime});
			trend.push({x: dt,y: d.trendPoints});
			overall.push({x: dt,y: d.trend});
			if(d.changePoint=="TRUE"){
				vertical1.push({x:dt,y:d.runtime})
			}
			
		});
		console.log("min max values:"+miny+" "+maxy);
	mydata=[
    {
      values: timeSeries,      //values - represents the array of {x,y} data points
      key: 'Original Time Series', //key  - the name of the series.
      color: '#ff7f0e'  //color - optional: choose your own line color.
    },
    {
      values: trend,
      key: 'TrendLine',
      color: '#2ca02c'
    },
    {
      values: overall,
      key: 'Overall Trend',
      color: '#7777ff',   
      //area: true      //area - set to true if you want this line to turn into a filled area chart.
    }
	
  ];
  if(vertical1.length!=0)
  mydata.push({
	  values: vertical1,
	  key: ' Last Change Point',
	  color:'#7374ff',
	  disabled: true
  });
  console.log("Logging Series")
  console.log(mydata);
		
  // now add data to graph
    var chart = nv.models.lineChart()
                .margin({left: 100})  //Adjust chart margins to give the x-axis some breathing room.
                .useInteractiveGuideline(true)  //We want nice looking tooltips and a guideline!
               // .transitionDuration(350)  //how fast do you want the lines to transition?
                .showLegend(true)       //Show the legend, allowing users to turn on/off line series.
                .showYAxis(true)        //Show the y-axis
                .showXAxis(true)        //Show the x-axis
  ;
  /*
  var svg= d3.select('#chart svg');
  svg.append("text")
        .attr("x", 400)             
        .attr("y", 15)
        .attr("text-anchor", "middle")  
        .text("Runtime vs Date Graph");
  */
  chart.xAxis     //Chart x-axis settings
      .axisLabel('Date')        
      .tickFormat(function(d){
		  return d3.time.format('%b %d %Y')(new Date(d));
		  });
 
  chart.xScale(d3.time.scale())
  //chart.yScale(d3.range(1000,5000));
  chart.yDomain([-1.2*maxy,1.2*maxy])
  if(miny>=0)
	  chart.yDomain([0,1.2*maxy])
 
  chart.yAxis     //Chart y-axis settings
      .axisLabel('Runtime')
      .tickFormat(d3.format('.02f'));
  d3.select('#chart svg')    //Select the <svg> element you want to render the chart in.   
      .datum(mydata)         //Populate the <svg> element with chart data...
      .call(chart);          //Finally, render the chart!

  //Update the chart when window resizes.
  nv.utils.windowResize(function() { chart.update() });
  // now create a scatter plot
  addScatterPlot(data);
  addForecastPlot();	
 });
 // function to get Query String parameters
// function to add forecast plot to screenn
//rootDirectory="output2/";
addForecastPlot= function(){
	var filepath2=rootDirectory+jobName+"/forecast.csv";
	var series=[]
	d3.csv(filepath2,function(data) {
			// first find the keys of dataset
			for( var key in data[0]){
				if(key!="date")
				series[key]=[]
			}
			data.forEach(function(d){
				for(var key in d){
				 var dt= new Date(d.date);
				 if(key!="date")
				 series[key].push({x:dt,y:d[key]});
				}	
			})
			console.log("logging temporal data read");
			console.log(series) 
			// create data from series for use in chart and display
			var displayData=[]
			for(var key in series){
				displayData.push( {"key":key, "values": series[key]}) 
			}
			displayData.push({"key":"Original Time Series", "values": timeSeries});
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
	  
	  chart.yDomain([-1.2*maxy,1.2*maxy])
	  if(miny>=0)
	  chart.yDomain([0,1.2*maxy])
 
	  chart.yAxis     //Chart y-axis settings
			  .axisLabel('RunTime')
			  .tickFormat(d3.format('.02f'));
		  d3.select('#forecast svg')    //Select the <svg> element you want to render the chart in.   
			  .datum(displayData)         //Populate the <svg> element with chart data...
			  .call(chart);          //Finally, render the chart!
		
		  //Update the chart when window resizes.
		  nv.utils.windowResize(function() { chart.update() });
	
		})
}