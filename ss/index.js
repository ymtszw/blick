/*
* Entry point of the script.
* If executed with command line arguments, it runs as one-off CLI script.
* Otherwise it runs as a crawler program for Blick.
*/

const mainCLI = require('./lib/cli')
const mainCrawler = require('./lib/crawler')

const asCLI = () => process.argv.length >= 3

const main = async () => {
  if (asCLI()) {
    await mainCLI()
  } else {
    console.log('Starting crawler.')
    await mainCrawler()
  }
}

const handleError = async (err) => {
  console.error(err)
}

main().catch(handleError)
