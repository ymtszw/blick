require('./blick.css')

export const blick = (flags) => {
  const Elm = require('./Blick.elm')
  const app = Elm.Blick.fullscreen(flags)

  app.ports.queryEditorDOMRectPort.subscribe(([rawMatId, fieldThruPort, rawSelector]) => {
    const { left, top, width, height } = document.querySelector(rawSelector).getBoundingClientRect()
    app.ports.listenEditorDOMRectSub.send([rawMatId, fieldThruPort, { left, top, width, height }])
  })

  app.ports.lockScroll.subscribe(() => document.documentElement.classList.add('is-clipped'))

  app.ports.unlockScroll.subscribe(() => {
    // Port function will be called BEFORE backdrop element removed
    if (document.querySelectorAll('.modal-background').length <= 1) {
      document.documentElement.classList.remove('is-clipped')
    }
  })
}
