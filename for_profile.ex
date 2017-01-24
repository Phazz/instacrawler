session = %InstaCrawler.PrivateAPI.Session{username: "svrakitin", password: "instagram334", identity: InstaCrawler.PrivateAPI.Identity.create_random}
{:ok, producer} = GenStage.from_enumerable([{%{},  %InstaCrawler.PrivateAPI.Request{entity: :location, id: "141029732589857", resource: :feed}}])

{:ok, crawler} = InstaCrawler.Crawler.Supervisor.new(session, max_crawls: 10000000)
{:ok, parser} = InstaCrawler.Parser.Supervisor.new

GenStage.sync_subscribe(:storage, to: crawler, min_demand: 8)
GenStage.sync_subscribe(parser, to: crawler, min_demand: 2)
GenStage.sync_subscribe(crawler, to: parser)
GenStage.sync_subscribe(crawler, to: producer)
