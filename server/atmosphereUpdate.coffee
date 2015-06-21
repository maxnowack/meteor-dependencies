atmosphereUpdateInProgress = false

atmosphereUpdate = ->
  if atmosphereUpdateInProgress
    return console.log 'ATMO: Update already in progress'
  atmosphereUpdateInProgress = true
  console.log 'ATMO: Updating packages...'
  cnx = DDP.connect('https://atmospherejs.com')
  AtmoPackages = new Mongo.Collection 'packages', connection: cnx
  AtmoVersions = new Mongo.Collection 'versions', connection: cnx
  return console.error('ATMO: Cannot connect to atmosphere') if !cnx

  try
    Packages.find().forEach (p) -> p.updateAtmo
      connection: cnx
      packages: AtmoPackages
      versions: AtmoVersions
  catch e
    console.error 'ATMO: Exception while getting packages', e

  cnx.disconnect()
  console.log 'ATMO: Updated'
  atmosphereUpdateInProgress = false

Meteor.methods atmosphereUpdate: ->
  atmosphereUpdate()

Meteor.startup ->
  atmosphereUpdate()
  SyncedCron.add
    name: 'ATMO: Update'
    schedule: (parser) ->
      parser.text 'every 1 hour'
    job: ->
      before = moment()
      atmosphereUpdate()
      'ATMO: Took' + moment().diff(before) / 1000 + ' seconds'
