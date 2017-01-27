session = %InstaCrawler.PrivateAPI.Session{username: "svrakitin", password: "instagram334", identity: InstaCrawler.PrivateAPI.Identity.create_random}
{:ok, session} = InstaCrawler.Gateway.request(%InstaCrawler.PrivateAPI.Request{resource: :login}, session)
{:ok, producer1} = GenStage.from_enumerable([
  %InstaCrawler.PrivateAPI.Request{entity: :location, id: 134778816555630, resource: :feed},
  %InstaCrawler.PrivateAPI.Request{entity: :location, id: 133002480073460, resource: :feed}
])
{:ok, producer2} = GenStage.from_enumerable([
  %InstaCrawler.PrivateAPI.Request{entity: :location, id: 108744925826049, resource: :feed},
  %InstaCrawler.PrivateAPI.Request{entity: :location, id: 1399182130337989, resource: :feed}
])
{:ok, producer3} = GenStage.from_enumerable([
  %InstaCrawler.PrivateAPI.Request{entity: :location, id: 451269535049323, resource: :feed},
  %InstaCrawler.PrivateAPI.Request{entity: :location, id: 123416311036378, resource: :feed}
])

{:ok, parser1} = InstaCrawler.Parser.Supervisor.new(default_params: %{min_timestamp: 1454284800})
{:ok, parser2} = InstaCrawler.Parser.Supervisor.new(default_params: %{min_timestamp: 1454284800})
{:ok, parser3} = InstaCrawler.Parser.Supervisor.new(default_params: %{min_timestamp: 1454284800})

{:ok, crawler1} = InstaCrawler.Crawler.Supervisor.new(session, parser1)
{:ok, crawler2} = InstaCrawler.Crawler.Supervisor.new(session, parser2)
{:ok, crawler3} = InstaCrawler.Crawler.Supervisor.new(session, parser3)

GenStage.async_subscribe(crawler1, to: producer1)
GenStage.async_subscribe(crawler2, to: producer2)
GenStage.async_subscribe(crawler3, to: producer3)
