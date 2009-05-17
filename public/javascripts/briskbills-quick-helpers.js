/* This is useful for any ajax's that need to pop-up something after an existing popup is on screen*/
function show_modal_after_close(content, options){ 
	if ( $('MB_overlay') ) { 
		setTimeout(function(){show_modal_after_close(content,options)}, 500);
	}
	else { 
		Modalbox.show(content,options); 
	} 
};