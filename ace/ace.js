
/** @externType Ace.instance */
/** @externType Ace.event */
/** @externType Ace.position */
/** @externType Ace.def_event */

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


var selfTriggered = true;

/**
 * @register {Ace.instance, (Ace.event -> void) -> Ace.instance}
 */
function onChange(inst, callback) {
  return inst.getSession().on('change', function (e) {
    if (selfTriggered)
      return (selfTriggered = false);

    console.log(e);
    callback({action: e.data.action,
              text: e.data.text,
              start: {row: e.data.range.start.row, column: e.data.range.start.column},
              end: {row: e.data.range.end.row, column: e.data.range.end.column}
            });
  });
}


/**
 * @register {Ace.instance, string -> Ace.instance}
 */
function setValue(inst, val) {
  return inst.getSession().setValue(val);
}

/**
 * @register {Ace.instance, Ace.position, string -> Ace.instance}
 */
function insertValue(inst, pos, text) {
  selfTriggered = true;
  return inst.getSession().insert(pos, text);
}