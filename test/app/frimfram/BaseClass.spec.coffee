describe 'BaseClass', ->
  it 'has Backbone Events', ->
    for key, value of Backbone.Events
      expect(FrimFram.BaseClass.prototype[key]).toBe(value)

  describe '.listenToShortcuts()', ->
    it 'hooks up shortcuts specified in a shortcuts object', ->
      class SubClass extends FrimFram.BaseClass
        shortcuts:
          'backspace': 'funcA'
          'enter': ->
            
        funcA: ->

      spyOn(window, 'key')

      sc = new SubClass()
      sc.listenToShortcuts()
      expect(key.calls.count()).toBe(2)
      
  describe '.destroy()', ->
    it 'clears all properties from the object, except for "destroyed" and "destroy"', ->
      o = new FrimFram.BaseClass()
      o.destroy()
      expect(_.isEqual(_.keys(o), ['destroyed', 'destroy'])).toBe(true)
    
 