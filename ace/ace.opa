package ace

type Ace.instance = external

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
}