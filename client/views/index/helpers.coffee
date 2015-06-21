Template.Index.helpers
  latest: ->
    Packages.find {},
      sort: lastUpdated: -1
      limit: 15
