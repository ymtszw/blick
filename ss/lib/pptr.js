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
  await page.waitFor(5000) // Wait for possible initial animations/effects to settle
  const buffer = await screenshotPage(page, url)
  await page.close()
  return buffer
}

const screenshotPage = async (page, url) => {
  if (url.startsWith('https://qiita.com')) {
    return await handleQiitaPage(page)
  } else if (url.includes('github.com')) {
    return await handleGitHubPage(page)
  } else {
    return await page.screenshot()
  }
}

const handleQiitaPage = async (page) => {
  const slideElement = await page.$('.slide')
  if (slideElement) {
    return await slideElement.screenshot()
  } else {
    const mainElement = await page.$('.p-items_article')
    if (mainElement) {
      return await mainElement.screenshot()
    } else {
      return await page.screenshot()
    }
  }
}

const handleGitHubPage = async (page) => {
  const mainTextElement = await page.$('[itemprop=text]')
  if (mainTextElement) {
    return await mainTextElement.screenshot()
  } else {
    return await page.screenshot()
  }
}

const withBrowser = async (fun) => {
  const browser = await puppeteer.launch({headless: true, args: ['--no-sandbox', '--disable-setuid-sandbox']})
  process.on('error', () => browser.close())
  console.log('Browser up.')
  await fun(browser)
  return browser.close()
}

module.exports = { takeSS, withBrowser }
