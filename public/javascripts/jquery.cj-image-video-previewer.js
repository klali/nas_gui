/*globals window,document,jQuery,alert */
/* ***********************************************************************************

	CJ Image Video Previewer JavaScript framework

	Copyright (c) 2009-2010, Doug Jones. All rights reserved.

	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions
	are met:
	
	a) Redistributions of source code must retain the above copyright
	   notice, this list of conditions and the following disclaimer.
	  
	b) Redistributions in binary form must reproduce the above copyright
	   notice, this list of conditions and the following disclaimer in the
	   documentation and/or other materials provided with the distribution. 
	  
	c) Neither the name of the Creative Juices, Bo. Co. nor the names of its
	   contributors may be used to endorse or promote products derived from
	   this software without specific prior written permission.
	
	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
	A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
	OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
	LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
	DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
	THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
	OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	For further information, visit the Creative Juices website: www.cjboco.com.
	
	Version History
	
	1.1.0	(07-04-2010) - Fixed an IE8 bug. Added autoPlay.
	1.0.2	(03-18-2010) - Fixed a bug with the mouse tracking. This 
						   prevented the script from firing properly on mouseovers.
	1.0.1	(12-28-2009) - Tweaked the POSITIONING check. Now forcing RELATIVE
						   if it has not been set.
	1.0		(10-23-2009) - Initial release.

*********************************************************************************** */

/*
 jQuery('img.photo',this).imagesLoaded(myFunction)
 execute a callback when all images have loaded.
 needed because .load() doesn't work on cached images

 mit license. paul irish. 2010. (http://gist.github.com/268257)
 webkit fix from Oren Solomianik. thx!

 callback function is passed the last image to load
 as an argument, and the collection as `this`
*/
(function ($) {
	jQuery.fn.imagesLoaded = function (callback) {
		var elems = this.filter('img'),
			len = elems.length;
		elems.bind('load', function () {
				if (--len <= 0) {
					callback.call(elems, this);
				}
			}).each(function () {
				// cached images don't fire load sometimes, so we reset src.
				if (this.complete || this.complete === undefined) {
					var src = this.src;
					// webkit hack from http://groups.google.com/group/jquery-dev/browse_thread/thread/eee6ab7b2da50e1f
					// data uri bypasses webkit log warning (thx doug jones)
					this.src = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==";
					this.src = src;
				}
			});
	};
})(jQuery);

/*
 CJ Image Video Previewer
*/
(function ($) {
	$.fn.cjImageVideoPreviewer = function (options) {

		var settings = {
			// user editable settings
			images: [],
			delay: 450,
			autoPlay: false,
			showProgress: true
		};

		var sys = {
			// function parameters
			version: '1.0.2',
			elem: null,
			idx: 1,
			timer: null,
			loaded: 0,
			mouseX: null,
			mouseY: null,
			state: false
		};

		/*
			handle transitions
		***************************************/

		function clearTimer() {
			if (sys.timer !== null) {
				window.clearTimeout(sys.timer);
				sys.timer = null;
			}
		}

		// reset everything
		function stopAnimation() {

			if (sys.state) {

				clearTimer();
				sys.idx = 0;
				sys.state = false;

				// show the first image
				$(sys.elem).find("div.cjImageVideoPreviewer img:first").css({
					"display": "block"
				});

				// hide all the other images
				$(sys.elem).find("div.cjImageVideoPreviewer img:not(:first)").css({
					"display": "none"
				});
			}
		}

		// this function handles the image transitions.
		function setThumbnail() {
			var curImg = $(sys.elem).attr("id") + "_IMG_" + sys.idx;
			var nextImg = $(sys.elem).attr("id") + "_IMG_" + (sys.idx + 1 > settings.images.length - 1 ? 1 : sys.idx + 1);
			sys.idx = sys.idx + 1 > settings.images.length - 1 ? 1 : sys.idx + 1;
			
			$(sys.elem).find(".cjImageVideoPreviewer img#" + nextImg).css({
				"display": "block"
			});
			$(sys.elem).find(".cjImageVideoPreviewer img#" + curImg).css({
				"display": "none"
			});
			clearTimer();
			
			if (settings.autoPlay) {

				sys.timer = window.setTimeout(setThumbnail, settings.delay);

			} else {

				// let's make sure that the mouse is still over our element before we set another timer
				if (sys.mouseX >= $(sys.elem).offset().left && sys.mouseX <= $(sys.elem).offset().left + $(sys.elem).width() && sys.mouseY >= $(sys.elem).offset().top && sys.mouseY <= $(sys.elem).offset().top + $(sys.elem).height()) {
					sys.timer = window.setTimeout(setThumbnail, settings.delay);
				} else {
					stopAnimation();
				}
			}
		}

		// make sure all out images have loaded before starting the transition animation
		function checkLoaded() {

			// check load count against our image array
			// (keep in mind we added an image to it, so length - 1 - 1)
			if (sys.loaded > settings.images.length - 2) {

				$(sys.elem).find("div.cjImageVideoPreviewerProgress").hide();
				sys.timer = window.setTimeout(setThumbnail, settings.delay);

			} else {

				// animate the progress bar (if set)
				if (settings.showProgress) {
					var pbox = $(sys.elem).find("div.cjImageVideoPreviewerProgress"),
						pbar = $(sys.elem).find("div.cjImageVideoPreviewerProgress div.cjImageVideoPreviewerProgressBar");
					if ($(pbox).css("display") !== "block") {
						$(pbox).show();
					}
					$(pbar).css({
						"left": parseInt($(pbar).css("left"), 10) + parseInt($(pbar).width() / (settings.images.length - 2), 10) + "px"
					});
				}
			}
		}

		// setup a que container and load all the images
		function setUpImageQue() {

			var link = null;

			// add our original image to the top of the array
			settings.images.unshift($(sys.elem).find("img:first").attr("src"));

			// is the original image's parent a LINK?
			if ($(sys.elem).find("img").parent()[0].nodeName === "A") {
				link = $(sys.elem).find("img").parent()[0].href;
			}
			
			// need to create an container loader for the images.
			// this will help with faster transitions
			$(sys.elem).append('<div class="cjImageVideoPreviewer">');
			$(sys.elem).find(".cjImageVideoPreviewer").css({
				"display": "none",
				"width": $(sys.elem).width() + "px",
				"height": $(sys.elem).height() + "px",
				"overflow": "hidden",
				"position": "absolute",
				"top": "0px",
				"left": "0px"
			});

			// add a progress indicator to the main element (if set)
			if (settings.showProgress) {
				$(sys.elem).find(".cjImageVideoPreviewer").append(
				$('<div class="cjImageVideoPreviewerProgress">').css({
					"display": "none",
					"width": ($(sys.elem).width() - 4) + "px",
					"height": "8px",
					"overflow": "hidden",
					"position": "absolute",
					"top": "0px",
					"left": "0px",
					"background-color": typeof $(sys.elem).css("border-top-color") === "string" ? $(sys.elem).css("border-top-color") : "#000",
					"border-width": "2px",
					"border-style": "solid",
					"border-color": typeof $(sys.elem).css("border-top-color") === "string" ? $(sys.elem).css("border-top-color") : "#000",
					"z-index": "20"
				}).append(
				$('<div class="cjImageVideoPreviewerProgressBar">').css({
					"display": "block",
					"width": ($(sys.elem).width() - 4) + "px",
					"height": "6px",
					"overflow": "hidden",
					"position": "absolute",
					"top": "0",
					"left": "-" + ($(sys.elem).width() - 4) + "px",
					// the background is using a base64 encoded image, IE doesn't show this, so it will use the background color instead
					"background": "#6bc4f7 url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABoAAAAGCAIAAABSPBl5AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAANRJREFUeNpckUtyxDAIRGms8WIq+9lMTpzL5RC5QhYZ23QakCcfFaIQEo+P8Pb+5TDJAgzY8FOAi7ffANMi7aAFbQvbyV26Jf2MuhofnzFZTuGEWBesLoNrcvEPtwcfkUTpx8FCJ7SJQwe3WsywxTJJ5EkaLAPz/ulknM8O6+pSJ+52hXCLz2Yv3pKdjrId6HyFqHICWxYoG9vZ7BHQg3G/es/uz/iQCTS+9j+bDSKyEAVL49fgMGf3+pKPtVVCBeew+gcmy35w7B6J/pPSxTpvvwUYAKIhoZSkg7l0AAAAAElFTkSuQmCC) repeat-x top left",
					"z-index": "21"
				})));
			}

			// add all the images to main element.
			$(settings.images).each(function (i) {
				var id = $(sys.elem).attr("id") + "_IMG_" + i;
				$(sys.elem).find(".cjImageVideoPreviewer:first").append(
				$('<img src="' + settings.images[i] + '" id="' + id + '" />').css({
					"display": "none",
					"position": "absolute",
					"top": "0px",
					"left": "0px",
					"z-index": 10
				}));
				$("#" + id).imagesLoaded(function () {
					sys.loaded++;
					checkLoaded();
				});
			});

			// if we have a link, let's add a click box that sits on top of everything
			if (link) {
				$(sys.elem).find(".cjImageVideoPreviewer").append(
				$('<div>').css({
					"display": "block",
					"width": $(sys.elem).width() + "px",
					"height": $(sys.elem).height() + "px",
					"position": "absolute",
					"top": "0px",
					"left": "0px",
					"cursor": settings.autoPlay ? "" : "pointer",
					"z-index": 100
				}).click(function () {
					document.location.href = link;
				}));
			}

			// reveal our creation
			$(sys.elem).find(".cjImageVideoPreviewer").css({
				"display": "block"
			});
			
		}

		function startAnimation() {

			// set the sys.state to true when we are running. Special occassions
			// can make the mouseLeave event not trigger (alerts, dialogs, etc)
			sys.state = true;
			clearTimer();

			// make sure the que container is available. If not, create it.
			if ($(sys.elem).find(".cjImageVideoPreviewer:first").length === 0) {

				// set up our que container
				setUpImageQue();
				sys.timer = window.setTimeout(startAnimation, 100);

			} else {

				// que has already been created, start out transition animation
				sys.timer = window.setTimeout(setThumbnail, settings.delay);
			}
		}

		/* 
			initialize the image preview
		***************************************/
		function init() {

			// check to make sure we have items in our image array and
			// at least one image in the element
			if (settings.images.length > 1 && $(sys.elem).find("img").length > 0) {

				// make sure the delay is a positive integer
				settings.delay = settings.delay < 0 ? 0 : parseInt(settings.delay, 10);

				// make sure the first image is top most 
				if ($(sys.elem).css("position") !== "relative" && $(sys.elem).css("position") !== "absolute") {
					alert("CJ Image Video Preview v" + (sys.version) + " Error!\n\nYou parent element (#" + $(sys.elem).attr("id") + ") must have it's positioning set to either RELATIVE or ABSOLUTE.\n\nPosition: " + ($(sys.elem).css('position')));
					return;
				}

				if (settings.autoPlay) {

					// user choose to auto play (without user interaction)
					startAnimation();

				} else {

					// set up event tracking, this ensures the mouse is still in our element
					$(document).mousemove(function (e) {
						sys.mouseX = e.pageX;
						sys.mouseY = e.pageY;
					});

					// user choose to only activate on mouseOvers
					$(sys.elem).hover(

					function (e) {
						// make sure the image is loaded before continuing
						if (sys.timer === null) {

							startAnimation();
							
						}
					}, function () {

						stopAnimation();

					});
				}
			}

		}

		/* 
			set up any user passed variables
		***************************************/
		if (options) {
			$.extend(settings, options);
		}

		/* 
			begin
		***************************************/
		return this.each(function () {
			sys.elem = this;
			init();
		});

	};
})(jQuery);
