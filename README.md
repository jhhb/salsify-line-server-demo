### Dependencies
* `rvm`
* `ruby` at `2.3.7` (via `rvm`)
* `redis` >= 4.0

### Running
* `cd sinatra-passenger-rspec-redis-boilerplate/`
* `bundle install`
* `sh run.sh`

#### Running tests
* `cd sinatra-passenger-rspec-redis-boilerplate/`
* `bundle exec rspec spec`

### POSTing
`curl -X  POST http://localhost:3000/keys/new_key_name`
