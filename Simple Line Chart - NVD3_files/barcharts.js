// JavaScript Document for bar charts
	var test_data=[]
	var runcount=[]
	var failurecount=[]
	var minalert=[]
	var maxalert=[]
	var startslaviolated=[]
	var endslaviolated=[]
	var runtime=[]
	var workload=[]
    var chart;
	var jobName= getQueryString("jobName");
	var filepath2=rootDirectory+jobName+"/week_stats.csv";
    d3.csv(filepath2,function(data) {
	
		data.forEach(function(d){
				runcount.push({x:d.day,y:d.runcount});
				failurecount.push({x:d.day,y:d.failcount});
				minalert.push({x:d.day,y:d.minalertcount});
				maxalert.push({x:d.day,y:d.maxalertcount});
				startslaviolated.push({x:d.day,y:d.startslaviolationcount});	
				endslaviolated.push({x:d.day,y:d.endslaviolationcount});	
				runtime.push({x:d.day,y:d.avgRuntime});
				workload.push({x:d.day,y:d.avgWorkload});

			})
		test_data=[
			{
				key : "RunCount",
				values: runcount
			},
						{
				key : "FailureCount",
				values: failurecount
			},
						{
				key : "Min Runtime Violated",
				values: minalert
			},
						{
				key : "Max Runtime Violated",
				values: maxalert
			},
						{
				key : "Start Time Violated",
				values: startslaviolated
			},
						{
				key : "End Time Violated",
				values: endslaviolated
			}
		]
		test_data2=[
			{
				key:"Average Runtime",
				values: runtime
			},
			{
				key:"Average Workload",
				values: workload
			}
		]
		console.log(test_data);
        chart = nv.models.multiBarChart()
            .barColor(d3.scale.category20().range())
            .duration(300)
            .margin({left: 100})
            .rotateLabels(45)
            .groupSpacing(0.1)
        ;

        chart.reduceXTicks(false).staggerLabels(true);

        chart.xAxis
            .axisLabel("Days of Week")
            .axisLabelDistance(35)
            .showMaxMin(false)
            .tickFormat(function(d){
				return d;
			});

        chart.yAxis
            .axisLabel("Count")
            .axisLabelDistance(-5)
            .tickFormat(d3.format(',d'))
        ;
		chart.yDomain([0,50])
        chart.dispatch.on('renderEnd', function(){
            nv.log('Render Complete');
        });

        d3.select('#barchart1 svg')
            .datum(test_data)
            .call(chart);
		
        nv.utils.windowResize(chart.update);

        chart.dispatch.on('stateChange', function(e) {
            nv.log('New State:', JSON.stringify(e));
        });
        chart.state.dispatch.on('change', function(state){
            nv.log('state', JSON.stringify(state));
        });

		// similar process for second chart
	chart2 = nv.models.multiBarChart()
            .barColor(d3.scale.category20().range())
            .duration(300)
            .margin({left: 100})
            .rotateLabels(45)
            .groupSpacing(0.1)
        ;

        chart2.reduceXTicks(false).staggerLabels(true);

        chart2.xAxis
            .axisLabel("Days of Week")
            .axisLabelDistance(35)
            .showMaxMin(false)
            .tickFormat(function(d){
				return d;
			});

        chart2.yAxis
            .axisLabel("Count")
            .axisLabelDistance(-5)
            .tickFormat(d3.format(',d'))
        ;
		chart2.yDomain([0,50])
        chart2.dispatch.on('renderEnd', function(){
            nv.log('Render Complete');
        });

		chart2.yAxis
            .tickFormat(d3.format(',.02f'))
        ;
		chart2.yDomain([0,5000])
		d3.select('#barchart2 svg')
            .datum(test_data2)
            .call(chart2);

        nv.utils.windowResize(chart2.update);

        chart2.dispatch.on('stateChange', function(e) {
            nv.log('New State:', JSON.stringify(e));
        });
        chart2.state.dispatch.on('change', function(state){
            nv.log('state', JSON.stringify(state));
        });
    });
