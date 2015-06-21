Meteor.publish 'latest', ->
  Packages.find {},
    sort: 'latestVersion.published': -1
    limit: 10
