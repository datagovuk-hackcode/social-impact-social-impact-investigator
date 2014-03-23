function setupMenu() {
var pinned = new Array ();
	function ButtonStatus(i, j, pinned) {
		var status = $('#categories > div:nth-child(' + i + ')').attr('class');
		if (status == "inactive") 
		{
			$('#categories > div:nth-child(' + i + ')').attr('class', "active");
			var spam = $('#' + j).text().replace(/\s/g, "");
			pinned.push(spam);
			$('#' + j + ' > img:nth-child(1)').attr('src', "pin.png");
		}
		else if (status == "active")
		{
			$('#categories > div:nth-child(' + i + ')').attr('class', "inactive");
			$('#' + j + ' > img:nth-child(1)').attr('src', "NotPinned.png");
			var index = pinned.indexOf(($('#'+ j + " > p1" ).text()).replace(/\s/g, ""));
			delete pinned[index];
		};
	};
	$(document).on('click', '.category', function(){
		var i = $(this).data('id');
		var j = $(this).parent().attr('id')
		ButtonStatus(i, j, pinned);
	});
	function OpenedClosed(){
		if($('#more').attr('class') == "closed") {
        removeSocial();
				$('#more').attr('class', 'opened');
				$('#main').prepend(Handlebars.compile($("#sidebar-template").html())());
        $.each(JSON.parse($.cookie("selectedCategories")), function (_, category) {
          $("#categories_form > input[value='" + category + "']").prop('checked', true);
        });
			$('#search-name').css({"width" : "70%"});
			$('#search-all').css({'margin-left' : '6em'});
			} else {
				$('#more').attr('class', 'closed');
				$('#categories').remove();
				$('#search-name').css({"width" : "82%"});
				$('#search-all').css({'margin-left' : '0em'})
			}
    resizePage();
	};
	$("#more").click(function(){
		OpenedClosed();
	});
}
