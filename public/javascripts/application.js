// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).bind('reveal.facebox', function() {
    $('#facebox').css('left', $(window).width() / 2 - ($('#facebox .popup').outerWidth() / 2))
    })

$(document).bind('loading.facebox', function() {
    $(document).bind('keydown.facebox', function(e) {
      if(e.keyCode == 39) $('#nextLink').click();
      if(e.keyCode == 37) $('#prevLink').click();
      return true;
      })
    })

$(document).bind('close.facebox', function() {
    $(document).unbind('keydown.foo');
    })
