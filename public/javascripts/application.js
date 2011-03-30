// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$.facebox.settings.closeImage = '/images/closelabel.png';
$.facebox.settings.loadingImage = '/images/loading.gif';

$(document).ready(function($) {
    $('a[rel*=facebox]').facebox();
    $('ul.sortable').nestedSortable({
      listType: 'ul',
      disableNesting: 'no-nest',
      forcePlaceholderSize: true,
      handle: 'div',
      helper: 'clone',
      items: 'li',
      opacity: .6,
      placeholder: 'placeholder',
      tabSize: 25,
      tolerance: 'pointer',
      toleranceElement: '> div',
      update: function(event, ui) {
        var mylist = $('ul.sortable').nestedSortable('serialize');
        $.post("/tags/save_list", mylist);
        return true;
      }
    });
});

$(document).bind('reveal.facebox', function() {
    setTimeout("$('#facebox').css('left', $(window).width() / 2 - ($('#facebox .popup').outerWidth() / 2))", 250);
    });

$(document).bind('loading.facebox', function() {
    $(document).bind('keydown.facebox', function(e) {
      if(e.keyCode == 39) $('#nextLink').click();
      if(e.keyCode == 37) $('#prevLink').click();
      return true;
      });
    });

$(document).bind('close.facebox', function() {
    $('img#crop_photo').imgAreaSelect({ remove: true });
    });

function storeResults(img, selection) {
  $('input#temp_thumb_width').val(selection.width);
  $('input#temp_thumb_height').val(selection.height);
  $('input#temp_thumb_x1').val(selection.x1);
  $('input#temp_thumb_y1').val(selection.y1);
  $('#saveButton').removeAttr('disabled');
};

function saveThumb() {
  $('input#tag_thumb_id').val($('input#temp_thumb_id').val());
  $('input#tag_thumb_width').val($('input#temp_thumb_width').val());
  $('input#tag_thumb_height').val($('input#temp_thumb_height').val());
  $('input#tag_thumb_x1').val($('input#temp_thumb_x1').val());
  $('input#tag_thumb_y1').val($('input#temp_thumb_y1').val());
  $(document).trigger('close.facebox');
};
