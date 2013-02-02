#=require ./index

#AJAX TESTS
describe "Ajax validations", ->
  
  form = null
  html = """
    <div data-demo>
      <form>
        <input name="field" value="abc" data-validate="testAjax">
        <input class="submit" type="submit"/>
      </form>
    </div>
  """

  #ajax test validator
  $.asyncValidator.addFieldRules
    testAjax:
      fn: (r) ->
        setTimeout ->
          if r.val() is "def"
            r.callback()
          else
            r.callback("My ajax test failed!")
        , 0
        
        #ajax!
        `undefined`

  beforeEach ->
    $('#konacha').html html
    form = $("form")
    form.asyncValidator(skipHiddenFields: false)

  describe "On submission", ->
    #valid test
    it "should be invalid", (done) ->

      input = form.find("input:first")
      expect(input.length).to.equal 1
      expect(input.val()).to.equal "abc"

      form.validate (result) ->
        expect(result).to.be.a "string"
        done()

    #invalid test
    it "should be valid", (done) ->
      
      #make invalid
      input = form.find("input:first")
      expect(input.length).to.equal 1
      expect(input.val()).to.equal "abc"
      input.val("def")

      form.validate (result) ->
        expect(result).to.equal `undefined`
        done()



