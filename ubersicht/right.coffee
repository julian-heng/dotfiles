command: "${HOME}/Library/Python/3.8/bin/sys-line '[ {cpu.load_avg}{cpu.temp? | {}°C}{cpu.fan? | {} RPM} ]{mem.used? [ Mem: {} ]}{disk.used? [ {disk.dev}: {} ]}{bat.is_present? [ Bat: {bat.percent}%{bat.time? | {}} ]}{net.ssid? [ {} ]} [ {misc.vol?vol: {}%}{misc.scr? | scr: {}%} ] [ {date.date} | {date.time} ]' --disk-short-dev --mount /System/Volumes/Data --{cpu-temp,bat-percent}-round=1 --{mem,disk}-used-{round=2,prefix=GiB}"

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
