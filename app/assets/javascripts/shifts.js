$(document).ready(function() {
	$('#edit_raw_shifts').click(function() {
		edit_shift_div = $('#raw_shifts')
		edit_shift_div.is(":hidden") ? edit_shift_div.slideDown(500) : edit_shift_div.slideUp(500);
	});

	$('#menu').hover(function() {
		$('#menu_text').text("Everyone");
		$('#menu_drop').slideToggle('fast');
	}, function() {
		$('#menu_text').text("Menu");
		$('#menu_drop').slideToggle('fast');
	});

//	$('#menu, #menu_drop').mouseleave(function() {
//		$('#menu_drop').slideUp('slow');
//		console.log("mouseleave");
//	});
});

var toggled_name = ''
function toggle_names(name) {
	console.log(name + " " + toggled_name);
	if (toggled_name == name) {
		$(".day_table").slideDown("fast");
		$(".schedule_row").slideDown("fast");
		toggled_name = '';
	} else {
		$(".day_table").slideDown("fast");
		$("." + name).slideDown("fast");
		$(".schedule_row:not(." + name + ")").slideUp("fast");
		toggled_name = name;
	};
};

function show_all_names() {
	toggled_name = '';
	$(".day_table").slideDown("fast");
	$(".schedule_row").slideDown("fast");
}

function toggle_day(id) {
	var toggle = $("#t" + id);
	toggle.is(":hidden") ? toggle.slideDown("slow") : toggle.slideUp("slow");
};
