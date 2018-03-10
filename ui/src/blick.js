require('./blick.css')

export const blick = (flags) => {
  const Elm = require('./Blick.elm')
  const app = Elm.Blick.fullscreen(flags)

  app.ports.queryDOMOrigin.subscribe(([id_, field, selector]) => {
    const { left, top, width, height } = document.querySelector(selector).getBoundingClientRect()
    app.ports.listenDOMOrigin.send([id_, field, { left, top, width, height }])
  })
}
