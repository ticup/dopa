package ace

type Ace.instance = external
type Ace.position = { int row, int column }
type Ace.event =
  { string action, string text, Ace.position start, Ace.position end } or
  { string action, list(string) lines, Ace.position start, Ace.position end }

module Editor {

  function Ace.instance edit(id) {
    %%ace.edit%%(id)
  }

  function Ace.instance set_theme(inst, string) {
    %%ace.setTheme%%(inst, string)
  }

  function set_mode(inst, string) {
    %%ace.setMode%%(inst, string)
  }

  function on_change(inst, callback) {
    %%ace.onChange%%(inst, callback)
  }

  function set_value(inst, val) {
    %%ace.setValue%%(inst, val)
  }

  function insert_value(inst, pos, text) {
    %%ace.insertValue%%(inst, pos, text)
  }

  function remove_value(inst, start, end) {
    %%ace.removeValue%%(inst, start, end)
  }

  function remove_lines(inst, start, end) {
    %%ace.removeLines%%(inst, start, end)
  }

  function insert_lines(inst, start, lines) {
    %%ace.insertLines%%(inst, start, lines)
  }

  function on_change_cursor(inst, callback) {
    %%ace.onChangeCursor%%(inst, callback)
  }
}