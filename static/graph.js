function graphData(data2, type) {
  if (type === 'polar') {
    $('#chart').on('mouseenter', function(){
      $(this).append('<div id="legend">\
        Legend:\
        <br>\
        <br>\
        <p1>llll</p1>\
        <p2>Community</p2>\
        <br>\
        <br>\
        <p3>llll</p3>\
        <p2>Employees</p2>\
        <br>\
        <br>\
        <p5>llll</p5>\
        <p2>Environment</p2>\
        <br>\
        <br>\
        <p7>llll</p7>\
        <p2>Governance</p2>\
        <br>\
        <br>\
        </div>'
        );
    });
    $('#chart').on('mouseleave', function(){
      $('#legend').remove()
    });
  }

  var community = "";
  community = data2.ratings.community;
  employees = data2.ratings.employees;
  environment = data2.ratings.environment;
  governance = data2.ratings.governance;
  var data = [
  {
    value : community,
          color: "#7D4F6D",
  },
  {
    value : employees,
    color: "#C7604C",
  },
  {
    value : environment,
    color: "#69D2E7"
  },
  {
    value : governance,
    color: "#9D9B7F"
  }
  ];
  var options = {
    //Boolean - Whether we show the scale above or below the chart segments
    scaleOverlay : true,
    //Boolean - If we want to override with a hard coded scale
    scaleOverride : true,
    //** Required if scaleOverride is true **
    //Number - The number of steps in a hard coded scale
    scaleSteps : 5,
    //Number - The value jump in the hard coded scale
    scaleStepWidth : 20,
    //Number - The centre starting value
    scaleStartValue : 0,
    //Boolean - Show line for each value in the scale
    scaleShowLine : true,
    //String - The colour of the scale line
    scaleLineColor : "rgba(0,0,0,.1)",
    //Number - The width of the line - in pixels
    scaleLineWidth : 1,
    //Boolean - whether we should show text labels
    scaleShowLabels : true,
    //Interpolated JS string - can access value
    scaleLabel : "<%=value%>",
    //String - Scale label font declaration for the scale label
    scaleFontFamily : "'Arial'",
    //Number - Scale label font size in pixels  
    scaleFontSize : 12,
    //String - Scale label font weight style  
    scaleFontStyle : "normal",
    //String - Scale label font colour  
    scaleFontColor : "#666",
    //Boolean - Show a backdrop to the scale label
    scaleShowLabelBackdrop : true,
    //String - The colour of the label backdrop 
    scaleBackdropColor : "rgba(255,255,255,0.75)",
    //Number - The backdrop padding above & below the label in pixels
    scaleBackdropPaddingY : 2,
    //Number - The backdrop padding to the side of the label in pixels  
    scaleBackdropPaddingX : 2,
    //Boolean - Stroke a line around each segment in the chart
    segmentShowStroke : true,
    //String - The colour of the stroke on each segement.
    segmentStrokeColor : "#fff",
    //Number - The width of the stroke value in pixels  
    segmentStrokeWidth : 2,
    //Boolean - Whether to animate the chart or not
    animation : true,
    //Number - Amount of animation steps
    animationSteps : 100,
    //String - Animation easing effect.
    animationEasing : "easeOutBounce",
    //Boolean - Whether to animate the rotation of the chart
    animateRotate : true,
    //Boolean - Whether to animate scaling the chart from the centre
    animateScale : false,
    //Function - This will fire when the animation of the chart is complete.
    onAnimationComplete : null
  };
  var ctx = document.getElementById("ratings-chart").getContext("2d");
  var myNewChart = new Chart(ctx).PolarArea(data);

  var data3 = {
    labels : ["community","employees","environment","governance"],
    datasets : [
    {
      fillColor : "rgba(151,187,205,0.5)",
      strokeColor : "rgba(151,187,205,1)",
      pointColor : "rgba(151,187,205,1)",
      data : [data2.ratings.community, data2.ratings.employees, data2.ratings.environment, data2.ratings.governance]
    }],
  };


  if (type === 'radar') {
    new Chart(ctx).Radar(data3,options);
  } else {
    new Chart(ctx).PolarArea(data,options);
  }
}
