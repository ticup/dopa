package jquery-ui

type Dialog.button = {string text, (-> void) click}
module Widgets {

  function dialog(id, title) {
    %%widgets.dialog%%(id, title)
  }

  function option(id, name, value) {
    %%widgets.option%%(id, name, value)
  }

  function buttons(id, buttons) {
    %%widgets.buttons%%(id, buttons)
  }

  function close(id) {
    %%widgets.close%%(id)
  }

  function on(id, event, callback) {
    %%widgets.on%%(id, event, callback)
  }
}