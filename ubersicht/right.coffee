command: "sys-line '[ {cpu.load_avg}{cpu.temp? | {}_C}{cpu.fan? | {} RPM} ]{mem.percent? [ Mem: {}% ]}{disk.percent? [ {disk.dev}: {}% ]}{bat.is_present? [ Bat: {bat.percent}%{bat.time? | {}} ]}{net.ssid? [ {} ]} [ {misc.vol?vol: {}%}{misc.scr? | scr: {}%} ] [ {date.date} | {date.time} ]' --disk-short-dev --cpu-temp-round=1 --{mem,disk,bat}-percent-round=1"

refreshFrequency: 5000 # ms

render: (output) ->
  "#{output}"

style: """
  webkit-font-smoothing: antialiased
  color: #c5c8c6
  font: 14px inconsolata
  right: 5px
  bottom: 2.5px
"""
