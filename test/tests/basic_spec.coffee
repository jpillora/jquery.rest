#=require ./index

#BASIC TESTS
describe "Basic", ->

  client = null

  beforeEach ->
    client = new $.RestClient()

  describe "When initialisation", ->
    it "should have an 'add' function", ->
      expect(client).to.be.defined()
      expect(client.add).to.be.a 'function'

