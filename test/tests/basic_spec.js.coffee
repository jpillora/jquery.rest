#=require ./index

#BASIC TESTS
describe "Basic validations", ->

  form = null
  html = """
    <div data-demo>
      <form>
        <input name='num1' value='42' data-validate='number'>
        <input name='num2' value='21' data-validate='number'>

        <input class='submit' type='submit'/>
      </form>
    </div>
  """

  beforeEach ->
    $('#konacha').html html
    form = $("form")
    form.asyncValidator(skipHiddenFields: false)

  describe "When initialisation", ->
    it "should have jquery accessor functions", ->
      expect($.isFunction(form.asyncValidator)).to.equal true

    it "should have attached validation engine object", ->
      expect(form.data("asyncValidator")).not.to.equal `undefined`


  describe "Field/Fieldset counts", ->
    it "should have 1 'no_group' fieldset", ->
      form.validate()
      obj = form.data("asyncValidator")
      expect(obj.fieldsets.size()).to.equal 1

    it "num fields in form, should be num fields in fieldsets", ->
      form.validate()
      obj = form.data("asyncValidator")
      numFields = 0
      obj.fieldsets.each (fs) ->
        numFields += fs.fields.size()

      expect(obj.fields.size()).to.equal numFields


  describe "When submitted", ->
    it "should be valid", ->
      form.validate (result) ->
        expect(result).to.equal `undefined`


    it "should be invalid", ->
      
      #make invalid
      form.find("input:first").val "abc"
      form.validate (result) ->
        expect(result).to.be.a "string"



