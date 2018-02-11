/*
* Entry point of the script.
* If executed with command line arguments, it runs as one-off CLI script.
* Otherwise it runs as a crawler program for Blick.
*/

const mainCLI = require('./lib/cli')

const asCLI = () => process.argv.length >= 3

const main = async () => {
  process.on('unhandledRejection', console.dir)
  if (asCLI()) {
    await mainCLI()
  } else {
    console.log('Starting crawler.')
    // TODO: As crawler
  }
}

main()
