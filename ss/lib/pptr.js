/* @module pptr
*
* Wrapper of `puppeteer`.
* Provides convenient functions.
*
*/

const puppeteer = require('puppeteer')

const takeSS = async (browser, url) => {
  const page = await browser.newPage()
  await page.setViewport({width: 1200, height: 675}) // 16:9
  await page.setExtraHTTPHeaders({'accept-language': 'ja'})
  await page.goto(url, {waitUntil: 'networkidle2'})
  const buffer = await page.screenshot()
  await page.close()
  return buffer
}

const withBrowser = async (fun) => {
  const browser = await puppeteer.launch()
  await fun(browser)
  return browser.close()
}

module.exports = { takeSS, withBrowser }
