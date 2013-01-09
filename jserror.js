/** @externType Ace.instance */
/** @externType Ace.event */
/** @externType Ace.position */
/** @externType Ace.def_event */

// hack: only trigger the given callback when the events performed on the
// editor are user performed to prevent loops.
var userTriggered = false;

/**
 * @register {string -> Ace.instance}
 */
function edit(id) {
  var inst = ace.edit(id);
  document.getElementById(id).addEventListener.("keydown", function() {
    console.log('putting user triggered to true');
    userTriggered = true;
  }, false);
  return inst;
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



/**
 * @register {Ace.instance, (Ace.event -> void) -> Ace.instance}
 */
function onChange(inst, callback) {
  return inst.getSession().on('change', function (e) {
    if (!userTriggered)
      return;

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
  userTriggered = false;
  return inst.getSession().setValue(val);
}

/**
 * @register {Ace.instance, Ace.position, string -> Ace.instance}
 */
function insertValue(inst, pos, text) {
  userTriggered = false;
  return inst.getSession().insert(pos, text);
}

/**
 * @register {Ace.instance, Ace.position, Ace.position -> void}
 */
function removeValue(inst, start, end) {
  var Range = ace.require('ace/range').Range
  var r = new Range(start.row, start.column, end.row, end.column);
  userTriggered = false;
  return inst.getSession().remove(r);
}