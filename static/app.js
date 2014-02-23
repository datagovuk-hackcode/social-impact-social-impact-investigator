$(function(){
	resizePage();
	$(window).resize(resizePage);

  textFit($('#header'), {maxFontSize:32})

  $("#searchByCategory").on("click", function() {
    loadCategories();
    $("#categories").show();
    return false;
  });

	var source = $("#results-template").html();
	window.template = Handlebars.compile(source);
	var source_categories = $("#categories-template").html();
	window.template_categories = Handlebars.compile(source_categories);
	// $("#sub-button").click(function(){
		// loadData($("#text-box").val());
	// });
  $("#search").submit(function() {
    loadData($("#text-box").val());
    return false;
  });
	// loadData('apple');
  
  $("#categories").on("change", function() {
      loadCategoryResults($(this).val());
  });

  $(document).on("click", ".categoryLink", function(event) {
    loadData($(event.target).text());
  });

  $(".header").on("click", function() {
    location.reload();
  });
});

function loadCategoryResults(name) {
  $.get("http://socialimpact.harryrickards.com/api/categories/" + encodeURIComponent(name)).done(function(data){
    $("#search-all").hide();
    var html = window.template_categories({'categories': data});
    $("#results").html(html);
    $("#results").show()
    resizePage();
  });
}

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
  // $("#social").width(bothWidth);
  // $("#financial").width(bothWidth);
}

function loadCategories() {
  $.get("http://socialimpact.harryrickards.com/api/categories").done(function(data) {
    for (var i=0; i<data.length; i++) {
      var html = "<option>" + data[i] + "</option>";
      $("#categories").append(html);
    }
  });
}
