// JavaScript Document
var jobName= getQueryString("jobName");
var jobAttributes=null;
if(jobName!=null){
d3.csv("output2/job_stats_1.csv",function(data){
	for(key in data){
		if(data[key].JobName==jobName){
			jobAttributes=data[key];
			break;
		}
	}
	if(jobAttributes==null){
		alert("No Job Matches or Stats are currenly not available for this Job")
		return;
	}
	console.log("Logging Attributes")
	console.log(jobAttributes);
	var table=d3.select("#sidebar table");
	// clear the previous content
	table.html("");
	// for each attribute add entries to table
	$.each(jobAttributes, function(key,value){
		if(key=="uptreejobs" || key=="downtreejobs");
		else{
		var tr=table.append("tr");	
		tr.append("td").attr("class","key").text(key);	
		tr.append("td").attr("class","value").text(value);	
		}
	})
})
}
else alert("Not Enough Query String Parameters in call to Script")