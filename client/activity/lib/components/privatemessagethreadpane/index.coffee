kd                        = require 'kd'
React                     = require 'kd-react'
KDReactorMixin            = require 'app/flux/reactormixin'
ActivityFlux              = require 'activity/flux'
immutable                 = require 'immutable'
classnames                = require 'classnames'
PrivateChatPane           = require 'activity/components/privatechatpane'
ChannelParticipantAvatars = require 'activity/components/channelparticipantavatars'


module.exports = class PrivateMessageThreadPane extends React.Component

  { getters } = ActivityFlux

  getDataBindings: ->

    return {
      channelThread         : getters.selectedChannelThread
      channelThreadMessages : getters.selectedChannelThreadMessages
      channelParticipants   : getters.selectedChannelParticipants
    }


  constructor: (props) ->

    super props

    @state =
      channelThread         : immutable.Map()
      channelThreadMessages : immutable.List()
      channelParticipants   : immutable.List()


  componentDidMount: -> reset @props


  componentWillReceiveProps: (nextProps) -> reset nextProps


  renderHeader: ->

    <ChannelParticipantAvatars
      channelThread = { @state.channelThread }
      participants  = { @state.channelParticipants }
    />


  renderChat: ->

    <PrivateChatPane
      thread   = { @state.channelThread }
      messages = { @state.channelThreadMessages }
    />


  renderSidebar: ->


  render: ->
    <div className='PrivateMessageThreadPane'>
      <section className="PrivateMessageThreadPane-content">
        <header className="PrivateMessageThreadPane-header">
          {@renderHeader()}
        </header>
        <div className="PrivateMessageThreadPane-body">
          <section className="PrivateMessageThreadPane-chatWrapper">
            {@renderChat()}
          </section>
        </div>
      </section>
      <aside className="PrivateMessageThreadPane-sidebar">
        {@renderSidebar()}
      </aside>
    </div>


React.Component.include.call PrivateMessageThreadPane, [KDReactorMixin]

reset = (props) ->

  { privateChannelId } = props.params
  {
    thread : threadActions,
    channel : channelActions,
    message : messageActions } = ActivityFlux.actions

  if privateChannelId
    channelActions.loadChannelById(privateChannelId).then ({ channel }) ->
      threadActions.changeSelectedThread channel.id
      messageActions.loadMessages channel.id
      channelActions.loadParticipants channel.id, channel.participantsPreview
  else
    thread.changeSelectedThread null
