Meteor.publish 'latest', (search) ->
  check search, Match.OneOf null, undefined, String
  query = {}
  if search? and search isnt ''
    query = _.extend query, name:
      $regex: ".*#{search}.*"
      $options: 'i'

  cursors = []
  cursors.push MeteorPackages.Packages.find query,
    sort: 'lastUpdated': -1
    limit: 100
  cursors.push MeteorPackages.Versions.find query,
    sort: 'lastUpdated': -1
    limit: 100
  return cursors
