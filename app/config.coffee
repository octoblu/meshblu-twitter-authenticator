passport = require 'passport'
TwitterStrategy = require('passport-twitter').Strategy
{DeviceAuthenticator} = require 'meshblu-authenticator-core'
MeshbluDB = require 'meshblu-db'
debug = require('debug')('meshblu-twitter-authenticator:config')

twitterOauthConfig =
  consumerKey: process.env.TWITTER_CLIENT_ID
  consumerSecret: process.env.TWITTER_CLIENT_SECRET
  callbackURL: process.env.TWITTER_CALLBACK_URL

class TwitterConfig
  constructor: (@meshbluConn, @meshbluJSON) ->
    @meshbludb = new MeshbluDB @meshbluConn

  onAuthentication: (accessToken, refreshToken, profile, done) =>
    profileId = profile?.id
    fakeSecret = 'twitter-authenticator'
    authenticatorUuid = @meshbluJSON.uuid
    authenticatorName = @meshbluJSON.name
    deviceModel = new DeviceAuthenticator authenticatorUuid, authenticatorName, meshblu: @meshbluConn, meshbludb: @meshbludb
    query = {}
    query[authenticatorUuid + '.id'] = profileId
    device =
      name: profile.name
      type: 'octoblu:user'

    getDeviceToken = (uuid) =>
      @meshbluConn.generateAndStoreToken uuid: uuid, (device) =>
        device.id = profileId
        done null, device

    deviceCreateCallback = (error, createdDevice) =>
      getDeviceToken createdDevice?.uuid

    deviceFindCallback = (error, foundDevice) =>
      if foundDevice?
        return getDeviceToken foundDevice.uuid
      deviceModel.create query, device, profileId, fakeSecret, deviceCreateCallback

    deviceModel.findVerified query, fakeSecret, deviceFindCallback

  register: =>
    passport.use new TwitterStrategy twitterOauthConfig, @onAuthentication

module.exports = TwitterConfig
