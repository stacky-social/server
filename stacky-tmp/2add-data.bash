curl http://localhost:3000/inject-data/add -H "Content-Type: application/json"  -d '{ "text": "This is the content", "actor_id": 1234567890, "username": "random_name_qweasd", "domain": "some-random-site-qweasd28739476", "json":  {"id": "https://some-random-site-qweasd28739476/random_name_qweasd", "inbox": "http://some-random-site-qweasd28739476/user/random_name_qweasd/fake_inbox", "outbox": "http://some-random-site-qweasd28739476/user/random_name_qweasd/fake_outbox", "name": "TOM_RED_DISPLAYYYY" } }' -X POST