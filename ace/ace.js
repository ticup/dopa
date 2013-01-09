/** @externType Ace.instance */
/** @externType Ace.event */
/** @externType Ace.position */
/** @externType Ace.def_event */

// hack: only trigger the given callback when the events performed on the
// editor are user performed to prevent loops.
var program_triggered = false;

function trigger_as_program(cont) {
  program_triggered = true;
  var result = cont();
  program_triggered = false;
  return result;
}

/**
 * @register {string -> Ace.instance}
 */
function edit(id) {
  var inst = ace.edit(id);
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
    if (program_triggered)
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
  return trigger_as_program(function () {
    return inst.getSession().setValue(val);
  });
}

/**
 * @register {Ace.instance, Ace.position, string -> Ace.instance}
 */
function insertValue(inst, pos, text) {
  return trigger_as_program(function () {
    return inst.getSession().insert(pos, text);
  });
}

/**
 * @register {Ace.instance, Ace.position, Ace.position -> void}
 */
function removeValue(inst, start, end) {
  var Range = ace.require('ace/range').Range;
  var r = new Range(start.row, start.column, end.row, end.column);
  return trigger_as_program(function () {
    return inst.getSession().remove(r);
  });
}