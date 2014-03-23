$(function(){
	resizePage();
  setupMenu();
	$(window).resize(resizePage);

  // Bind to sidebar changes
  bindCategoriesChanges();

  Handlebars.registerHelper('equal', function(lvalue, rvalue, options) {
    if (arguments.length < 3)
    throw new Error("Handlebars Helper equal needs 2 parameters");
  console.log(lvalue);
  console.log(rvalue);
  if( lvalue!=rvalue ) {
    return options.inverse(this);
  } else {
    return options.fn(this);
  }
  });

  // Go home when title clicked
  $("#title").click(function() { hasher.setHash('home'); });

  // Register partials
  registerPartial('views-selector');
  registerPartial('company-views-selector');

  // Register view change links
  registerCompanyViewLink('company_details_view', 'details');
  registerCompanyViewLink('company_explorer_view', 'explorer');
  registerCompanyViewLink('company_compare_view', 'compare');
  registerViewLink('explorer_view', 'explorer');
  registerViewLink('compare_view', 'compare');

  // Routing
  crossroads.addRoute('home', function() {
    loadTemplate("search", "home");
    $("#search").submit(function() { searchCompany(); return false; });
  });
  crossroads.addRoute('company/{name}/details', function(name) {
    addSocial();

    window.name = name;
    loadTemplate("loading-results", "company-loading-results");
    loadCompanyDetails(name, function(details) {
      loadTemplate("results", "company-results", details);
      console.log($("input[name=chart]:radio"));
      $(document).on('change', "input[name=chart]:radio", function() {
        graphData(details, $("#graph-choice input:checked").attr("value"));
      });
      graphData(details, $("#graph-choice input:checked").attr("value"));
    });
  });
  crossroads.addRoute('company/{name}/compare', function(name) {
    removeSocial();
    window.name = name;
    loadTemplate("company-compare", "company-compare", {name: name});
  });
  crossroads.addRoute('company/{name}/explorer', function(name) {
    removeSocial();
    window.name = name;
    loadTemplate("loading-explorer", "company-loading-explorer");
    loadCompanyDetails(name, function(details) {
      loadTemplate("company-explorer", "company-explorer", details);
    });
  });
  crossroads.addRoute('compare', function() {
    removeSocial();
    loadTemplate("compare", "compare");
  });
  crossroads.addRoute('explorer', function() {
    removeSocial();
    loadTemplate("explorer", "explorer", {category: encodeURIComponent(JSON.parse($.cookie("selectedCategories"))[0])});
  });
  crossroads.routed.add(console.log, console);
  crossroads.routed.add(resizePage, resizePage);
  function parseHash(newHash, oldHash){
    crossroads.parse(newHash);
  }
  hasher.initialized.add(parseHash); // Parse initial hash
  hasher.changed.add(parseHash); // Parse hash changes
  hasher.init();

  // Default route
  if(!hasher.getHash()){ hasher.setHash('home'); }
});

// Search for a specific company
function searchCompany() {
  hasher.setHash("company/" + encodeURIComponent($("#search-name").val()) + "/details");
}

// Resize various style things
function resizePage() {
	var mainHeight = $(window).height()-$(".header").height()-$("#footer").height()-6;
// $("#results").height(mainHeight);
  $("#container").width($("#main").width()-$("#categories").width());
  // $("iframe").height(0);
  // $("iframe").height($(document).height() - $("#header").height()).height();
  $("iframe").height("575");
}

// Load a specific template
function loadTemplate(templateName, currentPath, data) {
  if (typeof(data) === 'undefined') {
    data = {};
  }

  data['current'] = currentPath;

  console.log(data['current']);

  var template = Handlebars.compile($("#" + templateName + "-template").html());
  $("#container").html(template(data));
}

// Load results for a specific company
function loadCompanyDetails(name, callback) {
  var url = "http://10.10.63.58:9292/api/companies/" + name;
  $.get(url).done(function(data) {
    data['category'] = encodeURIComponent(data['industries'][0]['industry']);
    data['subcategory'] = encodeURIComponent(data['industries'][0]['subindustry']);
    callback(data)
  });
}

// Register a link to load a specific view
function registerCompanyViewLink(linkId, viewId) {
  $(document).on('click', 'a#' + linkId, function() {
    hasher.setHash('company/' + window.name + '/' + viewId);
  });
}
function registerViewLink(linkId, viewUrl) {
  $(document).on('click', 'a#' + linkId, function() {
    hasher.setHash(viewUrl);
  });
}

// Register a Handlebars partial
function registerPartial(name) {
  Handlebars.registerPartial(name, $("#" + name + "-partial").html());
}

// Listen to when categories choices change
function bindCategoriesChanges() {
  $(document).on('change', '#categories_form', function() {
    var selectedCategories = [];
    $("#categories_form > input:checked").each(function(_, el) {
      selectedCategories.push($(el).attr('value'));
    });

    $.cookie("selectedCategories", JSON.stringify(selectedCategories));
  });
}

function addSocial() {
  var template = Handlebars.compile($("#social-template").html());
  $("#social").html(template);
}

function removeSocial() {
  $("#social").html();
}
