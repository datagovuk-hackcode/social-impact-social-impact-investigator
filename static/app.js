$(function(){
	resizePage();
	$(window).resize(resizePage);

	var source = $("#results-template").html();
	window.template = Handlebars.compile(source);
	// $("#sub-button").click(function(){
		// loadData($("#text-box").val());
	// });
  $("#search").submit(function() {
    loadData($("#text-box").val());
    return false;
  });
	// loadData('apple');
});

function loadData(name) {
		$.get("http://socialimpact.harryrickards.com/api/companies/" + encodeURIComponent(name)).done(function(data){
			console.log(data);
			$("#search-all").hide();
			var html = window.template(data);
			$("#results").html(html);
			$("#results").show();
			resizePage();
		});
}

function resizePage() {
	var mainHeight = $(window).height()-$(".header").height()-$("#footer").height()-6;
	$("#results").height(mainHeight);
	var bothWidth = $("#both").width() / 2 - 8;
	console.log(bothWidth);
	$("#social").width(bothWidth);
	$("#financial").width(bothWidth);
}
