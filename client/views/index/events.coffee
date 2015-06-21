Template.Index.events
  'keyup .ui.search .prompt': (event, template) ->
    template.searchValue.set $(event.target).val()
