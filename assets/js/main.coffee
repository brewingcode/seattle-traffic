routesJson = null
config = {
  time: moment.utc().subtract(72, 'h'), # time shown in middle of graph
  delta: 2,           # duration before and after .time (in hours)
  weeks: 4,           # number of weeks to go back
}

makeGraph = (data) ->
  dataFile = '/timing/' + [$('#start').val(), $('#end').val(), $('#route').val()].join('/') + '.json'
  $.getJSON dataFile, (timing) ->
    graphdef =
      categories: []
      dataset: {}

    for i in [0 .. config.weeks - 1]
      thisTime = config.time.clone().subtract(i, 'weeks')
      thisCategory = thisTime.format('MMM D')
      lower = thisTime.clone().subtract(config.delta, 'hours')
      upper = thisTime.clone().add(config.delta, 'hours')

      graphdef.categories.push thisCategory
      graphdef.dataset[thisCategory] = _.chain(timing).filter (p) ->
        moment.unix(p.u).isBetween(lower, upper)
      .map (p) ->
        name: moment.unix(p.u).format('H:mm a')
        value: p.t
      .value()

    console.log graphdef
    chart = uv.chart 'Line', graphdef,
      graph:
        orientation: 'Vertical'
        hlabel: 'minutes'
        vlabel: 'time'
      axis:
        ticks: 5

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

$.getJSON 'routes.json', (routes) ->
  routesJson = routes

  fillCities('start').parent().val(Cookies.get('start') or 'Redmond')
  fillCities('end').parent().val(Cookies.get('end') or 'Seattle')
  findRoutes()

  $('select#start').change -> cityChanged('start')
  $('select#end').change -> cityChanged('end')
  $('select#route').change -> makeGraph()
