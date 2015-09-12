routesJson = null

exampleData =
  labels: ["January", "February", "March", "April", "May", "June", "July"],
  datasets: [
    label: "My First dataset",
    fillColor: "rgba(220,220,220,0.2)",
    strokeColor: "rgba(220,220,220,1)",
    pointColor: "rgba(220,220,220,1)",
    pointStrokeColor: "#fff",
    pointHighlightFill: "#fff",
    pointHighlightStroke: "rgba(220,220,220,1)",
    data: [65, 59, 80, 81, 56, 55, 40]
  ,
    label: "My Second dataset",
    fillColor: "rgba(151,187,205,0.2)",
    strokeColor: "rgba(151,187,205,1)",
    pointColor: "rgba(151,187,205,1)",
    pointStrokeColor: "#fff",
    pointHighlightFill: "#fff",
    pointHighlightStroke: "rgba(151,187,205,1)",
    data: [28, 48, 40, 19, 86, 27, 90]
  ]

makeGraph = (data) ->
  ctx = $('#graph').get(0).getContext("2d")
  new Chart(ctx).Line data,
    animation:true
    responsive:true
    scaleFontSize: 15

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

  makeGraph(exampleData)

$(document).ready ->
  makeGraph(exampleData)

  $.getJSON 'routes.json', (routes) ->
    routesJson = routes

    fillCities('start').parent().val(Cookies.get('start') or 'Redmond')
    fillCities('end').parent().val(Cookies.get('end') or 'Seattle')
    findRoutes()

    $('select#start').change -> cityChanged('start')
    $('select#end').change -> cityChanged('end')
    $('select#route').change -> makeGraph(exampleData)
