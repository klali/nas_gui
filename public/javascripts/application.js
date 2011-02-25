// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function($) {
    setTimeout("$('a[rel*=facebox]').facebox({ loadingImage : '/images/loading.gif', closeImage : '/images/closelabel.png' })", 150);
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
    });
    $('#saveListButton').click(function(){
      /*
      var mylist = $('ul.sortable').nestedSortable('toHierarchy', {startDepthCount: 0});
      var mylist = $('ul.sortable').nestedSortable('toArray', {startDepthCount: 0});
      mylist = dump(mylist);
      */
      var mylist = $('ul.sortable').nestedSortable('serialize');
      $.post("/tags/save_list", mylist);
      //alert(mylist);
      return false;
    });
});

function dump(arr,level) {
  var dumped_text = "";
  if(!level) level = 0;

  //The padding given at the beginning of the line.
  var level_padding = "";
  for(var j=0;j<level+1;j++) level_padding += "    ";

  if(typeof(arr) == 'object') { //Array/Hashes/Objects
    for(var item in arr) {
      var value = arr[item];

      if(typeof(value) == 'object') { //If it is an array,
        dumped_text += level_padding + "'" + item + "' ...\n";
        dumped_text += dump(value,level+1);
      } else {
        dumped_text += level_padding + "'" + item + "' => \"" + value + "\"\n";
      }
    }
  } else { //Stings/Chars/Numbers etc.
    dumped_text = "===>"+arr+"<===("+typeof(arr)+")";
  }
  return dumped_text;
}

$(document).bind('reveal.facebox', function() {
    setTimeout("$('#facebox').css('left', $(window).width() / 2 - ($('#facebox .popup').outerWidth() / 2))", 150);
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
  $('input#tag_thumb_id').val($('input#temp_thumb_id').val())
  $('input#tag_thumb_width').val($('input#temp_thumb_width').val())
  $('input#tag_thumb_height').val($('input#temp_thumb_height').val())
  $('input#tag_thumb_x1').val($('input#temp_thumb_x1').val())
  $('input#tag_thumb_y1').val($('input#temp_thumb_y1').val())
  $(document).trigger('close.facebox')
};
