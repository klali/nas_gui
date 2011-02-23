// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).bind('reveal.facebox', function() {
    win_width = $(window).width();
    pop_with = $('#facebox .popup').outerWidth();
    $('#facebox').css('left', $(window).width() / 2 - ($('#facebox .popup').outerWidth() / 2))
    })
