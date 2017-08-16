var json={nodes:nodes,links:links,stream_data:thirds};
console.log(json);
var width = 1000,
    height = 600;

var color = d3.scale.category20();
var force = d3.layout.force()
    .charge(-120)
    .linkDistance(15)  
    .gravity(.2)
    .size([width, height]);
var color = d3.scale.category20();
var svg = d3.select("#graph").append("svg")
    .attr("width", width)
    .attr("height", height);
    // define arrow markers for graph links
svg.append("defs").append("marker")
    .attr("id", "marker")
    .attr("viewBox", "0 -5 10 10")
    .attr("refX", 15)
    .attr("refY", 0)
    .attr("markerWidth", 6)
    .attr("markerHeight", 6)
    .attr("orient", "auto")
	.attr("opacity",0.5)
  .append("path")
    .attr("d", "M0,-5L10,0L0,5");

		

var r=[3*Math.sqrt(100),3*Math.sqrt(50),3*Math.sqrt(10)];

var i=0;
//var slider=d3.select("#slider");
var timer=setInterval("play()", 50);
var ticked=0;


function init() {

	force
		.nodes(json.nodes)
		.links(json.links)
		.linkDistance(function(d) {return 60 })
		.start();
	
	var link = svg.selectAll("line.link")
		.data(json.links)
		.enter().append("line")
		.attr("class", "link")
		.on("click", function(d){ alert("link from "+d.source.name+"->"+d.target.name)})
		.style("stroke",function(d) { return ("black");})
		.style("stroke-width", function(d) { return 2; })
		.style("visibility", "hidden")
		.style("stroke-opacity",.1)
		;
	link.append("title")
		.text(function(d) { return (d.source.name+"->"+d.target.name);});
			
	var node = svg.selectAll("circle.node")
		.data(json.nodes)
		.enter().append("circle")
		.attr("class", "node")
		.attr("r", 0)
		.on("dblclick", function(d){window.location="Simple.htm?jobName="+d.name})
		.style("fill", function(d) { return color(d.name); })
		.style("visibility", "hidden")
		.call(force.drag);	
	node.append("title")
		.text(function(d) { return d.name; });
	/*
	var texts = svg.selectAll("text.label")
                .data(json.nodes)
                .enter().append("text")
                .attr("class", "label")
                .attr("fill", "black")
                .style("font-size", "10px")
                .text(function(d) {  return d.name;  });
	*/
	force.on("tick", function() {
	/**	if(ticked)	{
			var mxScale=d3.scale.linear().domain([0,3780]).range([0,width]),
				myScale=d3.scale.linear().domain([0,2400]).range([0,height]);
			link.attr("x1", function(d) { return mxScale(d.source.coords[0]); })
		    .attr("y1", function(d) { return myScale(d.source.coords[1]); })
		    .attr("x2", function(d) { return mxScale(d.target.coords[0]); })
	  	    .attr("y2", function(d) { return myScale(d.target.coords[1]); });
		
		node.attr("cx", function(d) { return mxScale(d.coords[0]); })
		    .attr("cy", function(d) { return myScale(d.coords[1]); });
	
		} else {
	*/	link.attr("x1", function(d) { return d.source.x; })
		    .attr("y1", function(d) { return d.source.y; })
		    .attr("x2", function(d) { return d.target.x; })
	  	    .attr("y2", function(d) { return d.target.y; })
			.attr("marker-end",function(d){ return "url(#marker)"})

			;
		//console.log(link.marker);
		node.attr("cx", function(d) {  return d.x; })
		    .attr("cy", function(d) {  return d.y; });
		//}
	//	texts.attr("transform", function(d) {
      //  return "translate(" + d.x + "," + d.y + ")";
   // });
	  });
	  
    //console.log(stream);
    console.log(thirds[stream].noOfJobs);
    $("#stream").html("Stream name : "+stream);
    $("#jobs").html("Jobs: "+ thirds[stream].noOfJobs);
    $("#leaf-jobs").html("Leaf Jobs: "+ thirds[stream].leafJobs);
    $("#root-jobs").html("Root Jobs: "+ thirds[stream].rootJobs);
    $("#hosts").html("Hosts: "+ thirds[stream].hosts);
    $("#intermediate-jobs").html("Intermediate Jobs: "+ thirds[stream].intermediateJobs);
    $("#jobs-alert").html("Jobs with alerts: "+thirds[stream].jobsWithAlerts);
    $("#jobs-fail").html("Jobs which failed: "+thirds[stream].jobsWhichFail);
    $("#max-run").html("Jobs with Max Run alarms: "+thirds[stream].MaxRun);
    $("#min-run").html("Jobs with Min Run alarms: "+thirds[stream].MinRun);
    $("#start-sla").html("Jobs with start SLA violations: "+thirds[stream].jobsWithStartSLAViolation);
    $("#end-sla").html("Jobs with end SLA violations: "+thirds[stream].jobsWithEndSLAViolation);
	//slider.property("max",json.links.length);
	start();
}
function start() {	
	//svg.select("#chapter").text(chapters[i].title);
	//svg.select("#POV").text(chapters[i].povName);
	//console.log(i);
	var link = svg.selectAll("line.link")
 	     .style("visibility", function(d) {return "visible";})
 	var node = svg.selectAll("circle.node")
 	     //.attr("r", function(d) {return 4*(d.visits.filter(function(v) {return v<=i;}).length);})
 	     .attr("r",function(d){return (10)})
 	     .style("opacity", function(d) {return .8;})
 	     .style("stroke",function(d) {return "white";})//d.lastSeen==i?"black":"white";})
 	     .style("visibility", function(d) {return "visible";})
	showColor();
}


function play() {
	if(i<json.links.length){i++;
	//slider.property("value",i);
	start(i);}	
}
function showColor() {	
	
		var node = svg.selectAll("circle.node")
		.style("fill", function(d) { //console.log(fourths[d.name]); 
		return ((fourths[d.name].root=="TRUE")? ("red"):((fourths[d.name].leaf=="TRUE")?("green"):"blue"));
 		   })
     	
}
//init();
var timer=setInterval("play()", 50);