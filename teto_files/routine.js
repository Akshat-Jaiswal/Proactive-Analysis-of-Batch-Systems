var json={nodes:nodes,links:links};
console.log(json);
var width = 960,
    height = 600;

var color = d3.scale.category20();
var force = d3.layout.force()
    .charge(-360)
    .linkDistance(15)  
    .gravity(.2)
    .size([width, height]);

var svg = d3.select("#graph").append("svg")
    .attr("width", width)
    .attr("height", height);


var r=[3*Math.sqrt(100),3*Math.sqrt(50),3*Math.sqrt(10)];

var i=0;
var ticked=0;
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
	
function init() {
			force
		.nodes(json.nodes)
		.links(json.links)
		.linkDistance(function(d) {return 180 })
		.start();
	
	var link = svg.selectAll("line.link")
		.data(json.links)
		.enter().append("line")
		.attr("class", "link")
		.on("dblclick", function(d){ alert("link from "+d.source.name+"->"+d.target.name+" with influencing factor "+d.group )})
		.style("stroke",function(d) { return (d.group?(d.group>1?"blue":"orange"):"brown");})
		.style("stroke-width", function(d) { return 2; })
		.style("visibility", "hidden")
		//.style("stroke-opacity",.1)
		;
	link.append("title")
		.text(function(d) { return (d.source.name+"->"+d.target.name);});
			
	var node = svg.selectAll("circle.node")
		.data(json.nodes)
		.enter().append("circle")
		.attr("class", "node")
		.attr("r", 50)
		.on("dblclick", function(d){ window.location="stream_display.html?streamname="+d.name;})
		.style("fill", function(d) { return color(d.name); })
		.style("visibility", "hidden")
		.call(force.drag);	
	node.append("title")
		.text(function(d) { return d.name; });
//		.style("visibility",function(d){ return "hidden";})
/*	var texts = svg.selectAll("text.label")
                .data(json.nodes)
                .enter().append("text")
                .attr("class", "label")
                .attr("fill", "black")
                .text(function(d) {  return d.name;  });
*/	
	force.on("tick", function() {
	/*	if(ticked)	{
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
			.attr('marker-end', 'url(#marker)');
     
		
		node.attr("cx", function(d) {  return d.x; })
		    .attr("cy", function(d) {  return d.y; });
		//}
		//texts.attr("transform", function(d) {    return "translate(" + d.x+50 + "," + d.y+50 + ")"; })
		//	 .attr("margin","10px");
	  });
	  
	start();
}
function start() {	
	//svg.select("#chapter").text(chapters[i].title);
	//svg.select("#POV").text(chapters[i].povName);
	//console.log(i);
	var link = svg.selectAll("line.link")
 	     .style("visibility", function(d) {return "visible";})
 	var node = svg.selectAll("circle.node")
 	     //.attr("r", function(d) {return 6*(d.visits.filter(function(v) {return v<=i;}).length);})
 	     .attr("r",function(d){return (d.count>50?d.count/5:(d.count<20?d.count*2:d.count/2))})
 	     .style("opacity", function(d) {return d3.max([.50,1-.02*(i-d.lastSeen)]);})
 	     .style("stroke",function(d) {return "white";})//d.lastSeen==i?"black":"white";})
 	     .style("visibility", function(d) {return d.firstSeen<=i?"visible":"hidden";})
}
function play() {
	if(i<json.links.length){i+=1;
	//slider.property("value",i);
	start(i);}	
}
init();
var timer=setInterval("play()", 50);

