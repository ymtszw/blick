require('./blick.css')

export const blick = (flags) => {
  const Elm = require('./Blick.elm')
  const app = Elm.Blick.fullscreen(flags)

  app.ports.queryDOMOrigin.subscribe(([id_, field, selector]) => {
    const { left, top, width, height } = document.querySelector(selector).getBoundingClientRect()
    app.ports.listenDOMOrigin.send([id_, field, { left, top, width, height }])
  })

  app.ports.lockScroll.subscribe(() => document.documentElement.classList.add('is-clipped'))

  app.ports.unlockScroll.subscribe(() => {
    // Port function will be called BEFORE backdrop element removed
    if (document.querySelectorAll('.modal-background').length <= 1) {
      document.documentElement.classList.remove('is-clipped')
    }
  })
}
