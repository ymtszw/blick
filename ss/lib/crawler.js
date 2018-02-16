/* @module crawler
*
* Take Screenshots of target Materials fetched from gear API.
* Then uploads them to cloud file storage.
*
*/

const sharp = require('sharp')
const { takeSS, withBrowser } = require('./pptr')
const { list, request_upload_start, upload, notify_upload_finish, exclude_material } = require('./api_client')

const ss = async (browser, { _id, data }) => {
  const buffer = await takeSS(browser, data.url)
  const resized = await resize(buffer)
  // console.log(require('child_process').execSync('imgcat', {input: resized}).toString('binary'))
  const size = resized.length
  const { upload_url } = await request_upload_start(_id, size)
  await upload(_id, upload_url, resized)
  return await notify_upload_finish(_id)
}

const resize = async (buffer) => {
  const raw = await sharp(buffer)
  const info = await raw.metadata()
  const cropStrategy = (info.height > info.width) ? sharp.gravity.north : sharp.gravity.centre
  return await raw.resize(640, 360).crop(cropStrategy).toBuffer()
}

const main = async () => {
  const materials = await list()
  const chunkedMaterials = chunk(materials, 3, [])
  await withBrowser(async (browser) => {
    return await chunkedMaterials.reduce(chunkReducer(browser), Promise.resolve('init'))
  })
}

const chunk = (array, n, acc) => {
  acc.push(array.slice(0, n))
  const tl = array.slice(n)
  if (tl.length === 0) {
    return acc
  } else {
    return chunk(tl, n, acc)
  }
}

const chunkReducer = (browser) => async (promise, chunk, index) => {
  await promise
  console.log(`Processing chunk #${index}`)
  return Promise.all(chunk.map(ssImpl(browser)))
}

const ssImpl = (browser) => async (material) => {
  return await ss(browser, material).catch(handleSSError(material))
}

const handleSSError = (material) => async (err) => {
  if (err.message === 'net::ERR_NAME_NOT_RESOLVED') {
    console.error(`Unreachable: ${material.data.url}`)
    await exclude_material(material._id).catch((err) => console.error(err))
  } else {
    console.error(err)
  }
}

module.exports = main
