/* @module cli
*
* Take Screenshot in PNG format from CLI.
* Prints result if `imgcat` available (save to a file if specified).
* If `imgcat` is not available, always saves a result to file.
*
*/

const cp = require('child_process')
const fs = require('fs')
const sharp = require('sharp')
const which = require('which')
const { takeSS, withBrowser } = require('./pptr')

const imgcatAvaibale = () => which.sync('imgcat', {nothrow: true})

const save = (buffer, filename0) => {
  const filename = filename0 || 'sample.png'
  fs.writeFileSync(filename, buffer)
  console.log(`Screenshot saved to ${filename}`)
}

const previewAndSave = (buffer, filename) => {
  if (imgcatAvaibale()) {
    console.log('Result:')
    console.log(cp.execSync('imgcat', {input: buffer}).toString('binary'))
    if (filename) {
      save(buffer, filename)
    }
  } else {
    save(buffer, filename)
  }
}

const main = async () => {
  let url, filename
  const arg2 = process.argv[2]
  if (arg2.startsWith('http')) {
    url = arg2
    if (process.argv.length >= 4) {
      filename = process.argv[3]
    }
  } else {
    console.error('Supply a URL starting with http')
    process.exit(1)
  }

  await withBrowser(async (browser) => {
    const buffer = await takeSS(browser, url)
    const resized = await sharp(buffer).resize(640).toBuffer()
    previewAndSave(resized, filename)
  })
}

module.exports = main
