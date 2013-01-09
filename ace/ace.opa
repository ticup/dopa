package ace

type Ace.instance = external
type Ace.position = { int row, int column }
type Ace.event = { string action, string text, Ace.position start, Ace.position end }

module Editor {

  function Ace.instance edit(id) {
    %%ace.edit%%(id)
  }

  function Ace.instance set_theme(inst, string) {
    %%ace.setTheme%%(inst, string)
  }

  function Ace.instance set_mode(inst, string) {
    %%ace.setMode%%(inst, string)
  }

  function Ace.instance on_change(inst, callback) {
    %%ace.onChange%%(inst, callback)
  }

  function Ace.instance set_value(inst, val) {
    %%ace.setValue%%(inst, val)
  }

  function Ace.instance insert_value(inst, pos, text) {
    %%ace.insertValue%%(inst, pos, text)
  }

  function remove_value(inst, start, end) {
    %%ace.removeValue%%(inst, start, end)
  }
}