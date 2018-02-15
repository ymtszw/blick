/* @module api_client
*
* HTTP Client for blick Screenshot API.
*
*/

const http = require('http')
const url = require('url')

const host = (process.env.WORKER_ENV === 'cloud') ? 'https://blick.solomondev.access-company.com' : 'http://blick.localhost:8080'
const api_key = process.env.API_KEY

const get = (path) => {
  const opts = Object.assign(url.parse(`${host}${path}`), {
    headers: {'authorization': api_key}
  })
  return new Promise((resolve, reject) => {
    http.get(opts, (incoming) => readJson(incoming, resolve)).on('error', reject)
  })
}

const readJson = (incoming, resolve) => {
  let body = ''
  incoming.on('data', (chunk) => body += chunk)
  incoming.on('end', () => {
    const retBody = (incoming.headers['content-type'].startsWith('application/json')) ? JSON.parse(body) : body
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
    const req = http.request(opts, (incoming) => readJson(incoming, resolve)).on('error', reject)
    req.write(payload)
    req.end()
  })
}

const list_new = async () => {
  const res = await get('/api/screenshots/new')
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

module.exports = { list_new, request_upload_start }
