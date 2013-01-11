/** @externType dom_element */
/** @externType Dialog.button */

/**
 * @register {string, string -> void}
 */
function dialog(id, title) {
  $(id).dialog({title: title});
}

/**
 * @register {string, string, int -> void}
 */
function option(id, name, value) {
  $(id).dialog("option", name, value);
}

/**
 * @register {string, opa[list(Dialog.button)] -> void}
 */
function buttons(id, buttons) {
  $(id).dialog("option", "buttons", list2js(buttons));
}

/**
 * @register {string -> void}
 */
function close(id) {
  $(id).dialog("close");
}

/**
 * @register {string, string, (-> void) -> void}
 */
function on(id, event, callback) {
  $(id).on(event, function (event, ui) {
    callback();
  });
}