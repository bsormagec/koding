ChatInputModule = require './chatinput'
CreateChannelModule = require './createchannel'
ChannelNotificationSettingsModule = require './channelnotificationsettings'

module.exports =
  getters   : require './getters'

  actions   :
    feed        : require './actions/feed'
    message     : require './actions/message'
    thread      : require './actions/thread'
    channel     : require './actions/channel'
    suggestions : require './actions/suggestions'
    user        : require './actions/user'
    command     : require './actions/command'

  stores    : [
    require './stores/messagesstore'
    require './stores/channelsstore'
    require './stores/channelthreadsstore'
    require './stores/messagethreadssstore'
    require './stores/selectedchannelthreadidstore'
    require './stores/selectedmessagethreadidstore'
    require './stores/followedpublicchannelidsstore'
    require './stores/followedprivatechannelidsstore'
    require './stores/popularchannelidsstore'
    require './stores/channelparticipantidsstore'
    require './stores/channelpopularmessageidsstore'
    require './stores/openedchannelsstore'
    require './stores/suggestions/suggestionsquerystore'
    require './stores/suggestions/suggestionsflagsstore'
    require './stores/suggestions/suggestionsstore'
    require './stores/suggestions/suggestionsselectedindexstore'
    require './stores/messagelikerssstore'
    require './stores/channelflagsstore'
    require './stores/messageflagsstore'
    require './stores/socialsharelinksstore'
    require './stores/activesocialsharelinkidstore.coffee'
    require './stores/channelmessagessearchquerystore'
    require './stores/filteredchannelmessagesidsstore'
    require './stores/channelparticipants/channelparticipantssearchquerystore'
    require './stores/channelparticipants/channelparticipantsdropdownvisibilitystore'
    require './stores/channelparticipants/channelparticipantsselectedindexstore'
    require './stores/channelmessageloadermarkersstore'
    require './stores/sidebarchannels/sidebarpublicchannelsquerystore'
    require './stores/sidebarchannels/sidebarpublicchannelstabstore'
  ]
  # module stores
  .concat ChatInputModule.stores
  .concat CreateChannelModule.stores
  .concat ChannelNotificationSettingsModule.stores

  register: (reactor) ->
    reactor.registerStores @stores

    realtimeActionCreators = require './actions/realtime/actioncreators'
    realtimeActionCreators.bindNotificationEvents()
    realtimeActionCreators.bindAppBadgeNotifiers()

