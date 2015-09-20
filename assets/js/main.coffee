routesJson = null
now = null

init = ->
  moment.tz.add('America/Los_Angeles|PST PDT|80 70|0101|1Lzm0 1zb0 Op0')
  now = moment(moment(), 'America/Los_Angeles')

  setHeight = -> $('#graph').height $('#graph').width() * 0.60
  setHeight()
  $(window).resize -> setHeight()

  updateTime = (t) ->
    now = moment(t)
    makeGraph()

  $('#time').datetimepicker
    onChangeDate: updateTime
    onChangeTime: updateTime
    onChangeDateTime: updateTime
    closeOnDateSelect: true

  plainInput = (key, init) ->
    $('#'+key).val(Cookies.get(key) or init).change ->
      Cookies.set(key, $(@).val())
      makeGraph()
  plainInput('delta', 3)
  plainInput('weeks', 4)

  $.getJSON 'routes.json', (routes) ->
    routesJson = routes
    fillCities('start').parent().val(Cookies.get('start') or 'Redmond')
    fillCities('end').parent().val(Cookies.get('end') or 'Seattle')
    $('select#start').change -> cityChanged('start')
    $('select#end').change -> cityChanged('end')
    $('select#route').change -> makeGraph()
    findRoutes()

makeGraph = (data) ->
  dataFile = 'timing/' + [$('#start').val(), $('#end').val(), $('#route').val()].join('/') + '.base64'
  $.ajax(dataFile).done (compressed) ->
    offset = moment(now, 'America/Los_Angeles').utcOffset()
    delta = $('#delta').val()
    min = now.clone().add(offset, 'minutes').subtract(delta, 'hours')
    max = now.clone().add(offset, 'minutes').add(delta, 'hours')
    options =
      xaxis:
        mode: 'time'
        min: min.valueOf()
        max: max.valueOf()
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
  other = if which is 'start' then 'end' else 'start'
  thisCity = $('select#'+which)
  otherCity = $('select#'+other)

  trySetting = (i) ->
    if otherCity.children().eq(i).val() is thisCity.val()
      return false
    otherCity.val otherCity.children().eq(i).val()
    return true

  # try to set the other city to the first option, but there's a small
  # chance that will collide with *this* city, so use the second option
  # if it comes to that
  if otherCity.val() is thisCity.val()
    if not trySetting(0)
      trySetting(1)

  for x in ['start', 'end']
    Cookies.set(x, $('select#'+x).val())

  findRoutes()

optionTag = (val) -> "<option value=\"#{val}\">#{val}</option>"

# fill in a dropdown with our cities, select the first one, and return it
fillCities = (which) ->
  cities = (x for x of routesJson)
  cities.sort()
  for city in cities
    $('select#'+which).append optionTag(city)
  $('select#'+which).children().first().prop 'selected', true

# given the 2 selected cities, update the list of routes bewteen them and
# reload the graph
findRoutes = ->
  start = $('select#start').val()
  end = $('select#end').val()
  if start is end
    return
  $('select#route').empty()
  for route in routesJson[start][end]
    $('select#route').append optionTag(route)
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

