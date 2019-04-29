### Dependencies
* `rvm`
* `ruby` at `2.3.7` (via `rvm`)
* `redis` >= 4.0
* `bundler` at `2.0.1`

### Running
* `cd salsify-line-server-demo`
* `bash build.sh`
* `bash run.sh`

### POSTing
`curl -X  POST http://localhost:3000/keys/new_key_name`

### Answers
> How does your system work? (if not addressed in comments in source)

Currently, this version of the line server satisfies requirements (according
to some definition of "perform well for small and large files" and
"perform well as the number of GET requests per unit time increases").

This project makes use of the Phusion Passenger HTTP server which handles
multiple requests simultaneously (non-blocking) by running a process that 
first loads the project into memory, and then forks new processes to handle 
additional requests.

The decision to use Passenger as a server was motivated largely by having a 
server that is easy to setup without requiring configuration. In a real-world 
scenario, it might well be the case that the best solution would be to run the 
system as an ECS task using the Thin HTTP server, rather than using Passenger
as I've done. Using Passenger allows me to focus more on a working solution
and less on configuration, setup, and infrastructure assumptions.

I began by using Thin, but because I wanted to support multiple clients
(non-blocking) simultaneously and did not want to perform setup required to
run a load balancer in front of multiple Thin processes, I looked to Unicorn
and Passenger. I ultimately went with Passenger over Unicorn because it
required virtually no configuration to setup.

Currently, the system will iterate an entire file line-by-line and return
the requested line if it is in range; otherwise, it will return an error.

> How will your system perform with a 1 GB file? a 10 GB file? a 100 GB file?

Given the current implementation, the system performance is highly dependent
upon access patterns. In the worst-case, all file accesses occur at the
end of the file, meaning the entire file must be iterated on each request
before a result can be returned. Assuming random access, system performance
will decrease as file size increases. 

In the worst case for a 1 GB file on my local machine, ~75 seconds is how long
a response takes.

> How will your system perform with 100 users? 10000 users? 1000000 users?

All else equal, with no additional configuration, the version of Passenger used
supports a pool of 6 workers and can handle (serve and queue) up to 100
connections. Both the pool size and queue size are configurable. 

> with 100

Testing via
```
wrk -t 16 -c 100 http://localhost:3000/lines/0

Running 10s test @ http://localhost:3000/lines/0
  16 threads and 100 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    52.49ms  150.97ms 988.05ms   93.43%
    Req/Sec   435.02     63.56   600.00     84.63%
  63493 requests in 10.06s, 21.61MB read
Requests/sec:   6314.39
Transfer/sec:      2.15MB
```

The system supports 100 requests without additional tuning.

Going beyond that number, however, it's necessary to increase the pool size
(denoted by ```--max-pool-size```) or the queue size
(```--max-request-queue-size```) or both.

> 10000 users? 1000000 users?

For the sake of argument, if we use an unbounded request queue size
(```---max-request-queue-size=0```) in `run.sh`, at some point in the 1000s, 
the system will refuse new connections.

At 1,000,000 users, the system will generate a seg fault.

> What documentation, websites, papers, etc did you consult in doing this assignment?

I mostly consulted documentation for various Ruby HTTP servers, Ruby API
documentation, and Sinatra documentation, including:
* https://github.com/sinatra/sinatra
* https://www.phusionpassenger.com/library/walkthroughs/basics/ruby/process_management.html
* https://www.linode.com/docs/development/ror/use-unicorn-and-nginx-on-ubuntu-14-04/
* https://www.speedshop.co/2015/07/29/scaling-ruby-apps-to-1000-rpm.html
* https://github.com/macournoyer/thin

>What third-party libraries or other tools does the system use? How did you choose each library or framework you used?

Each technology is followed by the reason for using it.

Sinatra
* I had never used Sinatra before and have heard it's nice to use. It's also
much lighter weight than Rails (which is an alternative) so I thought I would try
something new.

Phusion
* As mentioned previously, I wanted to be able to use a server that would 
"just work" while allowing concurrent processing of client requests. Also 
mentioned previously, the ideal design for this kind of system might well use 
a different server or infrastructure, but I chose Phusion for simplicity's sake.
