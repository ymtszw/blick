/* @module api_client
*
* HTTP Client for blick Screenshot API.
*
*/

const http = require('http')
const https = require('https')
const url = require('url')

const host = (process.env.WORKER_ENV === 'cloud') ? 'https://blick.solomondev.access-company.com' : 'http://blick.localhost:8080'
const api_key = process.env.API_KEY
const refresh = (process.env.REFRESH === 'true') ? true : false

const mod = ({ protocol }) => (protocol === 'https:') ? https : http

const get = (path) => {
  const opts = Object.assign(url.parse(`${host}${path}`), {
    headers: {'authorization': api_key}
  })
  return new Promise((resolve, reject) => {
    mod(opts).get(opts, (incoming) => readBody(incoming, resolve)).on('error', reject)
  })
}

const readBody = (incoming, resolve) => {
  let body = ''
  incoming.on('data', (chunk) => body += chunk)
  incoming.on('end', () => {
    const contentType = incoming.headers['content-type']
    const retBody = (contentType && contentType.startsWith('application/json')) ? JSON.parse(body) : body
    resolve({
      status: incoming.statusCode,
      headers: incoming.headers,
      body: retBody
    })
  })
}

const post = (path, reqBody) => {
  const opts = Object.assign(url.parse(`${host}${path}`), {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'authorization': api_key,
    },
  })
  const payload = (typeof(reqBody) !== 'string') ? JSON.stringify(reqBody) : reqBody
  return new Promise((resolve, reject) => {
    const req = mod(opts).request(opts, (incoming) => readBody(incoming, resolve)).on('error', reject)
    req.write(payload)
    req.end()
  })
}

const list = async () => {
  const res = await get(`/api/screenshots?refresh=${refresh}`)
  if (res.status !== 200) {
    console.error(res)
    throw new Error('Failed to fetch materials.')
  }
  return res.body.materials
}

const request_upload_start = async (id, size) => {
  const res = await post(`/api/screenshots/${id}/request_upload_start`, {size: size})
  if (res.status !== 200) {
    console.error(res)
    throw new Error('Failed on requesting upload.')
  }
  return res.body
}

const upload = async (id, uploadUrl, buffer) => {
  const opts = Object.assign(url.parse(uploadUrl), {
    method: 'PUT',
    headers: {
      'content-type': 'image/png',
      'content-disposition': `attachment; filename=${id}`,
      'cache-control': 'public, max-age=3600',
    },
  })
  return new Promise((resolve, reject) => {
    console.log(`Uploading image for ${id}, ${buffer.length} bytes.`)
    const req = mod(opts).request(opts, (incoming) => readBody(incoming, resolve)).on('error', reject)
    // Using req.write() makes the request chunked, which AWS S3 cannot handle
    req.end(buffer)
  })
}

const notify_upload_finish = async (id) => {
  const res = await post(`/api/screenshots/${id}/notify_upload_finish`, {})
  if (res.status !== 204) {
    console.error(res)
    throw new Error('Failed on requesting upload.')
  }
}

module.exports = { list, request_upload_start, upload, notify_upload_finish }
