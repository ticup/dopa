/** @externType Ace.instance */
/** @externType Ace.event */
/** @externType Ace.position */
/** @externType Ace.def_event */

/** @externType list('a) */

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
  * @register {Ace.instance, string -> void}
  */
function setMode(inst, name) {
  return inst.getSession().setMode(name);
}



/**
 * @register {Ace.instance, (Ace.event -> void) -> Ace.instance}
 */
function onChange(inst, callback) {
  inst.getSession().on('change', function (e) {
    if (program_triggered)
      return;

    var event = {action: e.data.action,
                start: {row: e.data.range.start.row, column: e.data.range.start.column},
                end: {row: e.data.range.end.row, column: e.data.range.end.column}
              };

    if (e.data.action == "insertLines") {
      event.lines = js2list(e.data.lines);
    } else {
      event.text = e.data.text;
    }

    callback(event);

  });
}

/**
 * @register {Ace.instance, (Ace.position -> void) -> void}
 */
function onChangeCursor(inst, callback) {
  inst.getSession().selection.on('changeCursor', function (e) {
    var cursor = inst.getSession().selection.getCursor();
    callback(cursor);
  });
}


/**
 * @register {Ace.instance, string -> void}
 */
function setValue(inst, val) {
  return trigger_as_program(function () {
    return inst.getSession().setValue(val);
  });
}

/**
 * @register {Ace.instance, Ace.position, string -> void}
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

/**
 * @register {Ace.instance, Ace.position, Ace.position -> void}
 */
function removeLines(inst, start, end) {
  return trigger_as_program(function () {
    return inst.getSession().doc.removeLines(start.row, end.row);
  });
}

/**
 * @register {Ace.instance, Ace.position, opa[list(string)] -> void}
 */
function insertLines(inst, start, lines) {
  return trigger_as_program(function () {
    console.log(lines);
    console.log(list2js(lines));
    return inst.getSession().doc.insertLines(start.row, list2js(lines));
  });
}