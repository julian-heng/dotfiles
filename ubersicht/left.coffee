command: "/usr/local/bin/bash ${HOME}/.dotfiles/ubersicht/chunkwm.bash"

refreshFrequency: 400 # ms

render: (output) ->
  "#{output}"

style: """
  webkit-font-smoothing: antialiased
  color: #c5c8c6
  font: 14px inconsolata
  left: 12px
  bottom: 2.5px
"""
