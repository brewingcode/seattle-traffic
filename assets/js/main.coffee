routesJson = null
now = null

init = ->
  moment.tz.add('America/Los_Angeles|PST PDT|80 70|0101|1Lzm0 1zb0 Op0')
  now = moment(moment(), 'America/Los_Angeles')

  setHeight = -> $('#graph').height $('#graph').width() * 0.50
  setHeight()
  $(window).resize -> setHeight()

  updateTime = (t) ->
    now = moment(t)
    ga 'send', 'event', 'change', 'now', now.toISOString()
    makeGraph()

  $('#time').datetimepicker
    onChangeDate: updateTime
    onChangeTime: updateTime
    onChangeDateTime: updateTime
    closeOnDateSelect: true

  plainInput = (key, init) ->
    $('#'+key).val(Cookies.get(key) or init).change ->
      Cookies.set key, $(@).val()
      ga 'send', 'event', 'change', key, $(@).val()
      makeGraph()
  plainInput('delta', 6)
  plainInput('weeks', 5)

  $.getJSON 'routes.json', (routes) ->
    routesJson = routes
    fillCities('start', Cookies.get('start') or 'Seattle')
    fillCities('end', Cookies.get('end') or 'Redmond')
    findRoutes()
    $('select#start').change -> cityChanged('start')
    $('select#end').change -> cityChanged('end')
    $('select#route').change ->
      ga 'send', 'event', 'change', 'route', $('#route').val()
      makeGraph()

makeGraph = (data) ->
  dataFile = 'timing/' + [$('#start').val(), $('#end').val(), $('#route').val()].join('/') + '.base64'
  $.ajax(dataFile).done (compressed) ->
    offset = moment(now, 'America/Los_Angeles').utcOffset()
    delta = $('#delta').val()
    options =
      xaxis:
        mode: 'time'
        min: now.clone().add(offset, 'minutes').subtract(delta, 'hours').valueOf()
        max: now.clone().add(offset, 'minutes').add(delta, 'hours').valueOf()
        tickFormatter: (val) ->
          offset = moment(val, 'America/Los_Angeles').utcOffset()
          moment(val).subtract(offset, 'minutes').format('h:mma')
      grid:
        hoverable: true

    timing = $.parseJSON(JXG.decompress compressed)
    graphdef = []
    for i in [0 .. $('#weeks').val() - 1]
      thisTime = now.clone().subtract(i, 'weeks')
      lower = thisTime.clone().subtract(delta, 'hours')
      upper = thisTime.clone().add(delta, 'hours')

      graphdef.push
        label: thisTime.format('MMM D')
        data: _.chain(timing).filter (p) ->
          moment.unix(p[0]).isBetween(lower, upper) and p[1] > 0
        .map (p) ->
          utc = moment.unix(p[0]).add(i, 'weeks')
          offset = moment(moment.unix(p[0]), 'America/Los_Angeles').utcOffset()
          [utc.add(offset, 'minutes').valueOf(), p[1]]
        .value()

    plot = $.plot $('#graph'), graphdef, options
    $('#graph').bind 'plothover', makeTooltip

cityChanged = (which) ->
  start = $('#start').val()
  end = $('#end').val()

  if which == 'start'
    ga 'send', 'event', 'change', 'start', $('#start').val()
    if routesJson[start][end].length > 0
      fillCities 'end', end
    else
      fillCities 'end'
  else
    ga 'send', 'event', 'change', 'end', $('#end').val()

  for x in ['start', 'end']
    Cookies.set(x, $('select#'+x).val())

  findRoutes()

optionTag = (val, selected) ->
  html = "<option value=\"#{val}\""
  html += if selected then " selected" else ""
  html += ">#{val}</option>"

# fill in a dropdown with our cities, and either select a specific city,
# or just the first one
fillCities = (which, selected) ->
  allCities = _.sortBy(x for x of routesJson)
  if which == 'start'
    $('select#'+which).html(_.chain(allCities).map (city) ->
      optionTag city, selected is city
    .value())
  else
    $('select#'+which).html(_.chain(allCities).map (city) ->
      if routesJson[$('#start').val()][city].length > 0
        optionTag city, selected is city
      else
        ''
    .filter().value())

  if not selected
    $('select#'+which).children().first().prop 'selected', true

# given the 2 selected cities, update the list of routes bewteen them and
# reload the graph
findRoutes = ->
  start = $('select#start').val()
  end = $('select#end').val()
  $('select#route').html(_.chain(x for x in routesJson[start][end]).sortBy (r) ->
    r.length
  .map (r) ->
    optionTag(r)
  .value())

  $('select#route').children().first().prop 'selected', true

  makeGraph()

makeTooltip = (event, pos, item) ->
  if item
    x = item.datapoint[0]
    y = item.datapoint[1]
    localTime = moment(x).subtract(moment(0, 'America/Los_Angeles').utcOffset(), 'minutes').subtract(item.seriesIndex, 'weeks')
    shiftTime = moment(localTime, 'America/Los_Angeles').format('MMM D h:mma')
    $('#tooltip').html("#{shiftTime}: #{y} mins").css
      top: item.pageY + 5
      left: item.pageX + 5
      'border-color': item.series.color
    .fadeIn 200
  else
    $('#tooltip').hide()

init()

