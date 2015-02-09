
module.exports.setup = ->
  # http://stackoverflow.com/a/10865271/4240939
  # https://gist.github.com/branneman/8048520#7-the-wrapper
  # having a global require helps shorten require paths sometimes
  
  GLOBAL.rootDir = __dirname.replace('/server', '/')
  GLOBAL.rootRequire = (module) -> require(rootDir + module)
  
  
  #- global libraries
  GLOBAL._ = require 'lodash'
  GLOBAL._.string = require 'underscore.string'
  GLOBAL.tv4 = require 'tv4' # required for TreemaUtils to work
  GLOBAL.tv4.addSchema rootRequire 'app/schemas/root.schema'