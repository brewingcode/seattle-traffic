# Seattle Traffic

This is a [historical graph](http://traffic.brewingcode.net) of Seattle
freeway traffic, based on data from
[WSDOT](http://www.wsdot.com/traffic/traveltimes/default.aspx). The idea is
a quick glance at how travel times in the same timespan in the same day of
the week can show a pattern for how reliable the current trend is, today.

### Settings

![screenshot](roots_ignore/screen.png)

Setting|Default|Explanation
:---|------:|:----
Starting at             |     Seattle | City to start at
Via route               | I-5, SR 520 | Possible routes between them
Ending                  |     Redmond | City to end at, may change depending on `Starting at`
Time                    |   (now)     | Time to base the graph on, this time falls in the exact center
Hours before and after  |           6 | Number of hours to show before and after `Time`
\# of days              |           5 | Number of days to include in the graph (days are 1 week apart)

### Setup

- make sure [node.js](http://nodejs.org) and [roots](http://roots.cx) are
  installed
- clone this repo down and run `cd seattle-traffic && npm install`
- run `cp roots_ignore/ship.conf.example ship.conf`, and modify to your env.
  The `directoryWithHTMLFiles` part is, uh, complicated
- install python packages `attrdict beautifulsoup4 pymongo pyyaml`
- run `roots_ignore/mongodata html routes timing` to parse and generate data
- run `roots watch`
