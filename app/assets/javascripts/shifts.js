//(function($) {
function toggle_day(id) {
//	alert( "Handler for .click() " + id + " called." );
//	var toggle = document.getElementById("d" + id);
	var toggle = $("#t" + id);
	toggle.is(":hidden") ? toggle.slideDown("slow") : toggle.slideUp("slow");
//	alert( "click " + id);
//	alert( toggle.is( ":hidden" ));

};
//})(jQuery);
