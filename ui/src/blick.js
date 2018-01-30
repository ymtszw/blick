require('./blick.css')

export const blick = (flags) => {
  const Elm = require('./Blick.elm')
  Elm.Blick.fullscreen(flags)
}
