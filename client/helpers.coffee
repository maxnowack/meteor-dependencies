Template.registerHelper 'momentFormat', (date, format) ->
  moment(date).format(format)

Template.registerHelper 'formatLocalized', (date) ->
  moment(date).format 'LLL'

Template.registerHelper 'atmosphereUrl', (name) ->
  "https://atmospherejs.com/#{name.replace(':','/')}"
