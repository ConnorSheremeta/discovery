$(document).ready(function () {
 	$('.btn-xsmall').click(function(){ //you can give id or class name here for $('button')
    	$(this).text(function(i,old){
        	return old=='more' ?  'less' : 'more';
    	});
	});
	$('#sortAndPerPage .css-dropdown .btn ul, .sidenav .facet_limit ul').css('display', 'none');
	$('#sortAndPerPage .css-dropdown .btn').click(function(){
		$(this).find('ul').toggle();
	});
	$('.facet_limit .twiddle').click(function(){
		$(this).parent().find('ul').toggle();
	});
});