spotify = require 'spotify-node-applescript'
https = require 'https'

Number::times = (fn) ->
  do fn for [1..@valueOf()] if @valueOf()
  return

class AtomSpotifyStatusBarView extends HTMLElement
  initialize: () ->
    @classList.add('spotify', 'inline-block')

    div = document.createElement('div')
    div.classList.add('spotify-container')

    @soundBars = document.createElement('span')
    @soundBars.classList.add('spotify-sound-bars')
    @soundBars.data = {
      hidden: true,
      state: 'paused'
    }

    5.times =>
      soundBar = document.createElement('span')
      soundBar.classList.add('spotify-sound-bar')
      @soundBars.appendChild(soundBar)

    div.appendChild(@soundBars)

    @trackInfo = document.createElement('span')
    @trackInfo.classList.add('track-info')
    @trackInfo.setAttribute('data-prev', '')
    @trackInfo.textContent = ''
    div.appendChild(@trackInfo)

    @coverArt = document.createElement('img')
    @coverArt.classList.add('foo')
    @coverArt.setAttribute('id', 'atom-spotify2-cover-art')
    @coverArt.setAttribute('src', 'https://i.scdn.co/image/c61f7be95d1f892a6b4bddd60dd0bb5d99e5fc66')
    @coverArt.setAttribute('height', '24')
    div.insertBefore(@coverArt, @trackInfo)

    @appendChild(div)

    atom.commands.add 'atom-workspace', 'atom-spotify:next', => spotify.next => @updateTrackInfo()
    atom.commands.add 'atom-workspace', 'atom-spotify:previous', => spotify.previous => @updateTrackInfo()
    atom.commands.add 'atom-workspace', 'atom-spotify:play', => spotify.play => @updateTrackInfo()
    atom.commands.add 'atom-workspace', 'atom-spotify:pause', => spotify.pause => @updateTrackInfo()
    atom.commands.add 'atom-workspace', 'atom-spotify:togglePlay', => @togglePlay()

    atom.config.observe 'atom-spotify2.showEqualizer', (newValue) =>
      @toggleShowEqualizer(newValue)

    setInterval =>
      @updateTrackInfo()
    , 3000

  updateTrackInfo: () ->
    spotify.isRunning (err, isRunning) =>
      if isRunning
        spotify.getState (err, state)=>
          if state
            spotify.getTrack (error, track) =>
              if track
                console.log track
                trackInfoText = ""
                if atom.config.get('atom-spotify2.showPlayStatus')
                  if !atom.config.get('atom-spotify2.showPlayIconAsText')
                    trackInfoText = if state.state == 'playing' then '► ' else '|| '
                  else
                    trackInfoText = if state.state == 'playing' then 'Now Playing: ' else 'Paused: '
                trackInfoText += "#{track.artist} - #{track.name}"

                if !atom.config.get('atom-spotify2.showEqualizer')
                  if atom.config.get('atom-spotify2.showPlayStatus')
                    trackInfoText += " ♫"
                  else
                    trackInfoText = "♫ " + trackInfoText

                @trackInfo.textContent = trackInfoText
                trackId = track.id.split(':').pop()

                apiData = ''
                console.log 'before HTTP'
                art = @coverArt
                https.get 'https://api.spotify.com/v1/tracks/' + trackId, (res) ->
                  res.on 'data', (chunk) ->
                    apiData += chunk.toString()
                  res.on 'end', () ->
                    apiParsed = JSON.parse apiData
                    thumbnail = apiParsed.album.images.pop()
                    art.setAttribute('src', thumbnail.url)
                    console.log art, thumbnail
                console.log 'after HTTP'
              else
                @trackInfo.textContent = ''
              @updateEqualizer()
      else # spotify isn't running, hide the sound bars!
        @trackInfo.textContent = ''


  updateEqualizer: ()->
    spotify.isRunning (err, isRunning)=>
      spotify.getState (err, state)=>
        return if err
        @togglePauseEqualizer state.state isnt 'playing'

  togglePlay: ()->
    spotify.isRunning (err, isRunning) =>
      if isRunning
        spotify.playPause =>
          @updateEqualizer()

  toggleShowEqualizer: (shown) ->
    if shown
      @soundBars.removeAttribute 'data-hidden'
    else
      @soundBars.setAttribute 'data-hidden', true

  togglePauseEqualizer: (paused) ->
    if paused
      @soundBars.setAttribute 'data-state', 'paused'
    else
      @soundBars.removeAttribute 'data-state'

module.exports = document.registerElement('status-bar-spotify',
                                          prototype: AtomSpotifyStatusBarView.prototype,
                                          extends: 'div');
