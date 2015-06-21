Template.Index.helpers
  latest: ->
    Packages.find {},
      sort: 'latestVersion.published': -1
