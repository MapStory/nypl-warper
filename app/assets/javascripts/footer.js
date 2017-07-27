// set page content so footer is always "below the fold"
// Use no-conflict naming to work on all pages of the application
function setPageHeight(){
  var wH = jQuery(window).height();
  var gH = jQuery("#sitehead").height();
  jQuery("main").css("min-height",wH-gH);  
 }
 
jQuery(window).resize(function() {
  setPageHeight();
});

jQuery(document).ready(function() {
  setPageHeight();   
});