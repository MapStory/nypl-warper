//set page content so footer is always "below the fold"
function setPageHeight(){
  var wH = $(window).height();
  var gH = $("#sitehead").height();
  $("main").css("min-height",wH-gH);  
 }
 
$(window).resize(function() {
  setPageHeight();
});

$(document).ready(function() {
  setPageHeight();   
});