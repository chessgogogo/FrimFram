requireUtils = require 'lib/requireUtils'

TEST_REQUIRE_PREFIX = 'test/app/'
TEST_URL_PREFIX = '/test/client/'

class ClientTestView extends FrimFram.RootView
  id: 'client-test-view'
  template: require 'templates/client-test-view'
  reloadOnClose: true
  testingLibs: ['jasmine', 'jasmine-html', 'boot', 'mock-ajax', 'test-app']

  #- Initialization

  constructor: (options) ->
    super(options)
    @subPath = options.params[0] or ''
    @subPath = @subPath[1..] if @subPath[0] is '/'
    @loadTestingLibs()

  loadTestingLibs: ->
    return @scriptsLoaded() if @testingLibs.length is 0
    f = @testingLibs.shift()
    $.getScript("/javascripts/#{f}.js", => @loadTestingLibs())

  onFileLoad: (e) ->
    @loadedFileIDs.push e.item.id if e.item.id

  scriptsLoaded: ->
    @initSpecFiles()
    @render()
    ClientTestView.runTests(@specFiles)
    window.runJasmine()


  #- Rendering

  getContext: ->
    c = super(arguments...)
    c.parentFolders = requireUtils.getParentFolders(@subPath, TEST_URL_PREFIX)
    parts = @subPath.split('/')
    c.currentFolder = parts[parts.length-1] or parts[parts.length-2] or 'All'
    c.testTree = @testTree or {}
    c


  #- Running tests

  initSpecFiles: ->
    @specFiles = ClientTestView.getAllSpecFiles()
    @testTree = requireUtils.testTree(@specFiles)
    if @subPath
      prefix = TEST_REQUIRE_PREFIX + @subPath
      @specFiles = (f for f in @specFiles when _.startsWith(f, prefix))

  @runTests: (specFiles) ->
    describe 'Client', ->
      specFiles ?= @getAllSpecFiles()
      jasmine.Ajax.install()
      beforeEach ->
        jasmine.Ajax.requests.reset()

      require f for f in specFiles # runs the tests

  @getAllSpecFiles = ->
    allFiles = window.require.list()
    (f for f in allFiles when f.indexOf('.spec') > -1)


module.exports = ClientTestView