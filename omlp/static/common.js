var isSubmitted = false;

function goPage(page, params) {
//	if (isSubmitted) {
//		alert("処理中です。しばらくお待ちください。");
//		return;
//	}
	with (document.menuForm) {
		action = "/" + page;
		// set hash parameter values
		for (var param in params) {
			var elems = document.getElementsByName(param);
/*			if (elems == null) {		// 見つからなかったら
				alert("elem not found");
				var aelem =  document.createElement('input');
				aelem.type = "hidden";
				aelem.name = param;
				aelem.value = params[param];
				document.menuForm.appendChild(aelem);
			}
			else { */
				elems[0].value = params[param];
//			}
		}
		
		isSubmitted = true;
		
		submit();
	}
}

// onsubmit で disable にするやつ
// http://espion.just-size.jp/archives/05/220233057.html
var DisableSubmit = {
   init: function() {
      this.addEvent(window, 'load', this.set());
   },

   set: function() {
      var self = this;
      return function() {
         for (var i = 0; i < document.forms.length; ++i) {
            if(document.forms[i].onsubmit) continue;
            document.forms[i].onsubmit = function() {
               self.setDisable(this.getElementsByTagName('input'));
            };
         }
      }
   },

   setDisable: function(elms) {
      for (var i = 0, elm; elm = elms[i]; i++) {
         if ((elm.type == 'submit' || elm.type == 'image') && !elm.disabled) {
            Set(elm);
            unSet(elm);
         }
      }

      function Set(button) {
         window.setTimeout(function() { button.disabled = true; }, 1);
      }
      function unSet(button) {
         window.setTimeout(function() { button.disabled = false; }, 5000);
      }
   },

   addEvent: function(elm, type, event) {
      if(elm.addEventListener) {
         elm.addEventListener(type, event, false);
      } else if(elm.attachEvent) {
         elm.attachEvent('on'+type, event);
      } else {
         elm['on'+type] = event;
      }
   }
}

DisableSubmit.init();
