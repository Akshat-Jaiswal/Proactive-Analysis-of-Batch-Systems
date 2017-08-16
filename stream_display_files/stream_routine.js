var id=0;
var firsts=[];
var seconds=[];
var thirds=[];
var fourths=[];
/*de.csv("streamstatstable.csv", function(data){
  data.forEach(function(d){
    var name=d.streamname;
    if(d.streamName==stream)
      firsts[name]={"streamname":d.streamName,"noOfJobs":d.numberofjobs,"rootJobs":d.numberofrootjobs,"leafJobs":d.numberofleafjobs,"intermediateJobs":d.numberofintermediatejobs,"hosts":d.numberofhosts};
  });
})
console.log(firsts); */
var stream=location.search.substring("1").split("=")[1];
console.log("StreamName="+stream);

d3.csv("job_stream_map.csv",function(data){
      //  console.log("data Read from Job_stream_map");
	//	console.log(data);
        data.forEach(function(d){
           // var first=[];
            var name=d.jobName;
            if(d.streamName== stream)
            firsts[name]={"streamname":d.streamName,"name":d.jobName};
            // firsts[name]={"name":d.streamname};
            //first["group"]=d.jobcount; 
         });
d3.csv("streamstatstable.csv", function(data){
  data.forEach(function(d){
    if(d.streamname==stream){
      var name=d.streamname;
      thirds[name]={
		  "streamname":d.streamname,
		  "jobsWithEndSLAViolation":d.numberofjobswithendslaviolations,
		  "jobsWithStartSLAViolation":d.numberofjobswithstartslaviolations,
		  "MinRun":d.numberofjobswithminrunalarms,
		  "MaxRun":d.numberofjobswithmaxrunalarms,
		  "jobsWhichFail":d.numberofjobswithfailures,
		  "jobsWithAlerts":d.numberofjobswithalerts,
		  "noOfJobs":d.numberofjobs,
		  "rootJobs":d.numberofrootjobs,
		  "leafJobs":d.numberofleafjobs,
		  "intermediateJobs":d.numberofintermediatejobs,
		  "hosts":d.numberofhosts};
      console.log(thirds[stream]);
    }  
  });
})
d3.csv("job_stats.csv", function(data){
     // console.log(data);
         data.forEach(function(d){
          var fourth=[];
          var name=d.JobName;         
         if(firsts[d.JobName]){
		  
		 /** fourth["job"]=d.JobName;
          fourth["root"]=d.isRoot;
          fourth["leaf"]=d.isLeaf;
          fourths.push(fourth);*/
         // id++;
		  fourths[name]={"job":d.JobName,"root":d.isRoot,"leaf":d.isLeaf};
           //console.log(fourth);
          }
          });
         
         console.log(fourths);
    });
    d3.csv("job_dependencies.csv", function(data){
     // console.log(data);
         data.forEach(function(d){
          var second=[];
          if(d.PredecessorName=="")
              d.PredecessorName=d.JobName;
          
          if(firsts[d.JobName] && firsts[d.PredecessorName]){
          second["source"]=d.JobName;
          second["target"]=d.PredecessorName;
          seconds.push(second);
         // id++;
         
           }
          });
          console.log(seconds);
          flag2=true;
          seconds.forEach(addLink);
          // now call the init method
          init();
         
    });
        //console.log(data[0]);
        });
        
var nodes=[];
var links=[];
var nodeList=[];


function addLink(d,debug) {
    var s,t
 if(firsts[d.source]){
    if((s=nodeList.indexOf(d.source))==-1) {
        //if(debug){console.log("adding node "+d.source);}
        nodeList.push(d.source);
        nodes.push({name:d.source,size:1,name:firsts[d.source].name,count:firsts[d.source].streamname});
        s=nodeList.indexOf(d.source)

    } else {
        //if(debug){console.log("new visit to "+d.source);}
        nodes[s].size++;
        //nodes[s].visits.push(d.value);
        //nodes[s].lastSeen=d.value;
        //nodes[s].count=firsts[d.source].group;
    };
}
 if(firsts[d.target]){
    if((t=nodeList.indexOf(d.target))==-1) {
        //if(debug){console.log("adding node "+d.target);}
        nodeList.push(d.target)
        nodes.push({name:d.target,size:1,name:firsts[d.target].name,count:firsts[d.target].streamname});
        t=nodeList.indexOf(d.target)
    } else {if(d.source!=d.target) {
        //if(debug){console.log("new visit to "+d.target);}
        nodes[t].size++;
        //nodes[t].visits.push(d.value);
        //nodes[t].lastSeen=d.value;
       // nodes[t].count=firsts[d.target].group;
      }
    };

    links.push({source:nodes[s],target:nodes[t],thirds:thirds[stream],fourths:fourths,left:false,right:true});
}
    //console.log(nodes);
}
