
/** @externType Ace.instance */

/**
 * @register {string -> Ace.instance}
 */
function edit(id) {
  return ace.edit(id);
}

/**
 * @register {Ace.instance, string -> Ace.instance}
 */
 function setTheme(inst, name) {
    return inst.setTheme(name);
 }

 /**
  * @register {Ace.instance, string -> Ace.instance}
  */
  function setMode(inst, name) {
    return inst.getSession().setMode(name);
  }