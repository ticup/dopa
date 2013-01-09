/** @externType dom_element */
/**
 * @register {dom_element -> int}
 */  
function getCaretPosition (ctrl) {
 
  var CaretPos = 0;
  // IE Support
  if (document.selection) {
   
    ctrl.focus ();
    var Sel = document.selection.createRange ();
     
    Sel.moveStart ('character', -ctrl.value.length);
     
    CaretPos = Sel.text.length;
  }

  // Firefox support
  else if (ctrl.selectionStart || ctrl.selectionStart == '0')
    CaretPos = ctrl.selectionStart;
   
  return (CaretPos);
 
}
 

/**
 * @register {dom_element, int -> void}
 */  
function setCaretPosition(ctrl, pos) {
 
  if (ctrl.setSelectionRange) {
    ctrl.focus();
    ctrl.setSelectionRange(pos,pos);

  } else if (ctrl.createTextRange) {
    var range = ctrl.createTextRange();
    range.collapse(true);
    range.moveEnd('character', pos);
    range.moveStart('character', pos);
    range.select();
  }
}