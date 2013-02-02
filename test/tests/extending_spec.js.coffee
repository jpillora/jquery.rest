#=require ./index

#EXTENDING TESTS
describe "Extending validations", ->

  form = null
  html = """
    <div data-demo>
      <form>
        <input name="field1" value="abc" data-validate="validator1">
        <input name="field2" value="efg" data-validate="validator2">
        <input name="field3" value="def">
        <input class="submit" type="submit"/>
      </form>
    </div>
  """

  #validators used in this spec
  $.asyncValidator.addFieldRules
    validator1:
      fn: (r) ->
        return "Must equal '" + r.myVar + "' (not " + r.val() + ")"  if r.val() isnt r.myVar
        true
      myVar: "abc"

    validator2:
      extend: "validator1"
      #validator1.myVar overridden !
      myVar: "def"

    validator3:
      extend: "validator2"
      #validator1.fn overridden !
      #validator2.myVar inherited !
      fn: (r) ->
        myVar2x = r.myVar + r.myVar
        return "Must equal '" + myVar2x + "' (double)"  if r.val() isnt myVar2x
        true

  beforeEach ->
    $('#konacha').html html
    form = $("form")
    form.asyncValidator(skipHiddenFields: false)

  describe "When submitted", ->

    it "extended validator should be invalid", ->
      form.validate (result) ->
        expect(result).to.be.a "string"

    describe "Make valid", ->

      beforeEach ->
        form.find("input[name=field2]").val "def"

      it "extended validator should be valid", ->
        form.validate (result) ->
          expect(result).to.equal `undefined`

      describe "Enable validator 3", ->

        beforeEach ->
          form.find("input[name=field3]").attr "data-validate", "validator3"

        it "double extended validator should be invalid", ->
          form.validate (result) ->
            expect(result).to.be.a 'string'

        it "double extended validator should be valid", ->
          form.find("input[name=field3]").val "defdef"
          form.validate (result) ->
            expect(result).to.equal `undefined`




