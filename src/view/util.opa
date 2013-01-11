//
// view/util.opa
//
//
// @author: Tim Coppieters
// @date: 01/2013



module ViewUtil {

  // executes given cont if value != ""
  function requires_value(cont, value, text) {
    if (value == "") {
      Client.alert(text)
    } else {
      cont(value);
    }
    void
  }

}