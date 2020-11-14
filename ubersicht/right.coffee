command: "${HOME}/Library/Python/3.9/bin/sys-line '[ {cpu.load_avg}{cpu.temp[round=1]? | {}°C}{cpu.fan? | {} RPM} ]{mem.used[round=2,prefix=GiB]? [ Mem: {} ]}{disk.used[round=2,prefix=GiB]? [ {disk.dev[short_dev]}: {} ]}{bat.is_present? [ Bat: {bat.percent[round=1]}%{bat.time? | {}} ]}{net.ssid? [ {} ]} [ {misc.vol?vol: {}%}{misc.scr? | scr: {}%} ] [ {date.date} | {date.time} ]' --mount /System/Volumes/Data"

refreshFrequency: 5000 # ms

render: (output) ->
  "#{output}"

style: """
  webkit-font-smoothing: antialiased
  color: #c5c8c6
  font: 13px inconsolata
  right: 5px
  bottom: 4px
"""
