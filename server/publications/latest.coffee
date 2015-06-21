searchPackages = (search) ->
  return if search.length < 3
  cnx = DDP.connect('https://atmospherejs.com')
  AtmoPackages = new Mongo.Collection 'packages', connection: cnx
  AtmoVersions = new Mongo.Collection 'versions', connection: cnx
  return console.error('ATMO: Cannot connect to atmosphere') if !cnx

  page = 0
  size = 100
  res = cnx.call 'Search.query', search, page, size
  _.each res.packages, (p) -> Pkg.getByName p.name
  cnx.disconnect()

Meteor.publish 'latest', (search) ->
  check search, Match.OneOf null, undefined, String
  query = latestVersion: $exists: true
  if search? and search isnt ''
    Meteor.setTimeout ->
      searchPackages search
    , 0
    query = _.extend query, name:
      $regex: ".*#{search}.*"
      $options: 'i'

  Packages.find query,
    sort: 'latestVersion.published': -1
    limit: 10
