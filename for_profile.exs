session = %InstaCrawler.PrivateAPI.Session{username: "svrakitin", password: "instagram334", identity: InstaCrawler.PrivateAPI.Identity.create_random}
{:ok, producer} = GenStage.from_enumerable([
  {%{}, %InstaCrawler.PrivateAPI.Request{entity: :username, id: "spbifmo", resource: :info}}
  ])
{:ok, crawler} = InstaCrawler.Crawler.Supervisor.new(session, max_crawls: 10_000_000)
{:ok, parser} = InstaCrawler.Parser.Supervisor.new#(default_params: %{min_timestamp: 1454284800})

GenStage.sync_subscribe(:storage, to: crawler, min_demand: 0, max_demand: 128)
GenStage.sync_subscribe(crawler, to: parser, min_demand: 2, max_demand: 64)
GenStage.sync_subscribe(parser, to: crawler, min_demand: 4, max_demand: 64)
GenStage.sync_subscribe(crawler, to: producer)
