#=require ./index

#BASIC TESTS
describe "Validators", ->

  form = null
  html = """
    <div data-demo>
      <form>
        <input id='required' data-validate='required'>
        <input id='number' data-validate='number'>

        <input id='phone' data-validate='phone'>
        <input id='currency' data-validate='currency'>

        <input name='multiRequired' id='multiRequired' data-validate='required,number'>
        <input name='multiOptional' id='multiOptional' data-validate='phone,number'>

        <input name='minMax' id='minMax' data-validate='min(3),max(5)'/>

        <input class='submit' type='submit'/>
      </form>
    </div>
  """

  beforeEach ->
    $('#konacha').html html
    form = $("form")
    form.asyncValidator(skipHiddenFields: false)

  afterEach ->
    form.asyncValidator(false)

  describe "number", ->
    it "should be a number", ->
      $('#number').val('X').validate (result) ->
        expect(result).to.be.a 'string'

    it "should be valid", ->
      $('#number').val('42').validate (result) ->
        expect(result).to.equal `undefined`

  describe "required", ->
    it "should be required", ->
      $('#required').validate (result) ->
        expect(result).to.be.a 'string'

    it "should be valid", ->
      $('#required').val('X').validate (result) ->
        expect(result).to.equal `undefined`

  describe "phone (aus)", ->

    it "should start with 0", ->
      $('#phone').val('1299998888').validate (result) ->
        expect(result).to.be.a 'string'

    it "should be 10 chars", ->
      $('#phone').val('099998888').validate (result) ->
        expect(result).to.be.a 'string'

    it "should be valid", ->
      $('#phone').val('0299998888').validate (result) ->
        expect(result).to.equal `undefined`


  describe "multiple", ->

    it "should be invalid (required)", ->
      $('#multiRequired').validate (result) ->
        expect(result).to.be.a 'string'

    it "should be invalid (number)", ->
      $('#multiRequired').val('hello').validate (result) ->
        expect(result).to.be.a 'string'

    it "should be valid", ->
      $('#multiRequired').val('42').validate (result) ->
        expect(result).to.equal `undefined`

    it "should be invalid (NOT required but is word)", ->
      $('#multiOptional').val('hello').validate (result) ->
        expect(result).to.be.a 'string'

    it "should be valid (NOT required)", ->
      $('#multiOptional').validate (result) ->
        expect(result).to.equal `undefined`

  describe "min-max chars", ->

    it "should be invalid (min)", ->
      $('#minMax').val('aa').validate (result) ->
        expect(result).to.be.a 'string'

    it "should be invalid (max)", ->
      $('#minMax').val('aaaaaa').validate (result) ->
        expect(result).to.be.a 'string'

    it "should be valid", ->
      $('#minMax').val('aaaa').validate (result) ->
        expect(result).to.equal `undefined`

