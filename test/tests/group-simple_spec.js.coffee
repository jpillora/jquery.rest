#=require ./index

#BASIC TESTS
describe "Group validations (Simple)", ->

  form = null
  html = """
    <div data-demo>
      <form>
        <section data-validate="required">
          <input name="f1" value="abc">
          <input name="f2" value="def">
        </section>
        <input name="f3" value="abc">
        <input class="submit" type="submit"/>
      </form>
    </div>
  """

  beforeEach ->
    $('#konacha').html html
    form = $("form")
    form.asyncValidator(skipHiddenFields: false)

  describe "Field/Fieldset count", ->
    it "should have 1 fieldsets", ->
      
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


  describe "When submitted (simple)", ->
    it "should be valid", ->
      form.validate (result) ->
        expect(result).to.equal `undefined`


    it "should be invalid", ->
      #make invalid
      form.find("input:first").val ""
      form.validate (result) ->
        expect(result).to.be.a "string"

  null
