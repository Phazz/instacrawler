session = %InstaCrawler.PrivateAPI.Session{username: "svrakitin", password: "instagram334", identity: InstaCrawler.PrivateAPI.Identity.create_random}
{:ok, producer} = GenStage.from_enumerable([
  {%{}, %InstaCrawler.PrivateAPI.Request{entity: :location, id: "", resource: :search, params: %{latitude: 59.971278, longitude: 30.257200}}},
  {%{}, %InstaCrawler.PrivateAPI.Request{entity: :location, id: "", resource: :search, params: %{latitude: 59.866683, longitude: 30.322654}}},
  {%{}, %InstaCrawler.PrivateAPI.Request{entity: :location, id: "", resource: :search, params: %{latitude: 59.934005, longitude: 30.337235}}},
  {%{}, %InstaCrawler.PrivateAPI.Request{entity: :location, id: "", resource: :search, params: %{latitude: 59.933609, longitude: 30.305086}}},
  {%{}, %InstaCrawler.PrivateAPI.Request{entity: :location, id: "", resource: :search, params: %{latitude: 59.943775, longitude: 30.368887}}},
  {%{}, %InstaCrawler.PrivateAPI.Request{entity: :location, id: "", resource: :search, params: %{latitude: 59.945056, longitude: 30.303000}}}
  ])
{:ok, crawler} = InstaCrawler.Crawler.Supervisor.new(session, max_crawls: 10_000_000)
{:ok, parser1} = InstaCrawler.Parser.Supervisor.new(default_params: %{min_timestamp: 1454284800})
{:ok, parser2} = InstaCrawler.Parser.Supervisor.new(default_params: %{min_timestamp: 1459468800})
{:ok, parser3} = InstaCrawler.Parser.Supervisor.new(default_params: %{min_timestamp: 1477958400})

GenStage.sync_subscribe(:storage, to: crawler, min_demand: 0, max_demand: 128)
GenStage.sync_subscribe(crawler, to: parser1, min_demand: 2, max_demand: 64)
GenStage.sync_subscribe(parser1, to: crawler, min_demand: 4, max_demand: 64)
GenStage.sync_subscribe(crawler, to: parser2, min_demand: 2, max_demand: 64)
GenStage.sync_subscribe(parser2, to: crawler, min_demand: 4, max_demand: 64)
GenStage.sync_subscribe(crawler, to: parser3, min_demand: 2, max_demand: 64)
GenStage.sync_subscribe(parser3, to: crawler, min_demand: 4, max_demand: 64)
GenStage.sync_subscribe(crawler, to: producer)
