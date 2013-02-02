#=require ./index

#BASIC TESTS
describe "Group Ajax validation", ->

  form = null
  html = """
    <div data-demo>
      <form>
        <fieldset data-validate="sumTo10Async">
          <input name="f1" value="" data-validate="numberAsync">
          <input name="f2" value="3" data-validate="numberAsync">
        </fieldset>
        <input class="submit" type="submit"/>
      </form>
    </div>
  """

  #validators used in this spec
  $.asyncValidator.addFieldRules
    numberAsync:
      fn: (r) ->
        sum = 0
        setTimeout ->
          if !r.val().match /^\d+$/
            r.callback("Field must be a number")
          else
            r.callback()
        , 0
        #ajax!
        `undefined`

  $.asyncValidator.addGroupRules
    sumTo10Async:
      run: 'after'
      fn: (r) ->
        sum = 0
        setTimeout ->
          r.fields().each ->
            sum += parseInt($(@).val())
          if sum isnt 10
            r.callback("Fields must all sum to 10 not " + sum)
          else
            r.callback()
        , 0
        #ajax!
        `undefined`

  beforeEach ->
    $('#konacha').html html
    form = $("form")
    form.asyncValidator(skipHiddenFields: false)

  describe "When submitted (advanced)", ->

    it "group 'before' validator 'required' should fail", (done) ->
      form.validate (result) ->
        expect(result).to.be.a 'string'
        done()

    it "group 'after' validator 'sumTo10' should not be reached and the field validator 'number' should fail ", (done) ->
      form.find("input:first").val "X"
      form.validate (result) ->
        expect(result).to.have.string "number"
        done()

    it "group 'after' validator 'sumTo10' should be reached and fail", (done) ->
      form.find("input:first").val "3"
      form.validate (result) ->
        expect(result).to.have.string "must all sum to 10"
        done()

    it "group 'after' validator 'sumTo10' should pass", (done) ->
      form.find("input:first").val "7"
      form.validate (result) ->
        expect(result).to.equal `undefined`
        done()

  null
