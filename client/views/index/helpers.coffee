Template.Index.helpers
  latest: ->
    MeteorPackages.Packages.find {},
      sort: 'lastUpdated': -1
