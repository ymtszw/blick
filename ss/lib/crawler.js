/* @module crawler
*
* Take Screenshots of target Materials fetched from gear API.
* Then uploads them to cloud file storage.
*
*/

const sharp = require('sharp')
const { takeSS, withBrowser } = require('./pptr')
const { list_new } = require('./api_client')

const debugImgcat = (buffer) => {
  const cp = require('child_process')
  console.log(cp.execSync('imgcat', {input: buffer}).toString('binary'))
}

const ss = async (browser, material) => {
  const url = material.data.url
  const buffer = await takeSS(browser, url)
  const raw = await sharp(buffer)
  const info = await raw.metadata()
  const cropStrategy = (info.height > info.width) ? sharp.gravity.north : sharp.gravity.centre
  const resized = await raw.resize(640, 360).crop(cropStrategy).toBuffer()
  debugImgcat(resized)
}

const main = async () => {
  const materials = await list_new()

  await withBrowser(async (browser) => {
    return Promise.all(materials.map(async (material) => await ss(browser, material)))
  })
}

module.exports = main
