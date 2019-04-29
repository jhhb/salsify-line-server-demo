### Dependencies
* `rvm`
* `ruby` at `2.3.7` (via `rvm`)
* `redis` >= 4.0
* `bundler` at `2.0.1`

### Running
* `cd salsify-line-server-demo`
* `bash build.sh`
* `bash run.sh`

### Answers
> How does your system work? (if not addressed in comments in source)

Currently, this version of the line server satisfies requirements (according
to some definition of "perform well for small and large files" and
"perform well as the number of GET requests per unit time increases").

This most recent version of the system makes use of reading the given file 
line-by-line to find the requested line, as well as chunking the original file
into a smaller file in the filesystem to make subsequent accesses to the same
line (and nearby lines) faster; this is primarily beneficial for accesses
not near the beginning of the file.

When a request is made, the system checks if we have already chunked the
file such that the given index is accessible via a smaller file. If we have
already chunked the file, we use the smaller chunked file in the filesystem; if
we have not, we spawn a thread to begin writing the chunk, and then read through
the original file, line-by-line, to find the requested line. Once the thread is
done, subsequent accesses of the requested index and lines in the same chunk
will be much faster.

The system will also return a 413 error if the requested line (0-indexed) is out
of range

> How will your system perform with a 1 GB file? a 10 GB file? a 100 GB file?

Given the current implementation, the system performance is highly dependent
upon access patterns. In the worst-case, all file accesses occur at the
end of the file, meaning the entire file must be iterated on each request
before a result can be returned. Assuming random access, system performance
will decrease as file size increases. However, given enough time, and assuming
random access patterns, eventually the file should end up fully partitioned
into the filesystem, resulting in much faster lookups. Lookup time is still
dependent on how close a line is to the start of the file.

On my machine, using a partition size of 1,000,000 for a 1GB file resulted in
end-of-file accesses decreasing from ~2 minutes to just a few seconds.

> How will your system perform with 100 users? 10000 users? 1000000 users?

All else equal, with no additional configuration, the version of Passenger used
supports a pool of 6 workers and can handle (serve and queue) up to 100
connections. Both the pool size and queue size are configurable. 

> with 100

Testing via
```
wrk -t 16 -c 100 http://localhost:3000/lines/0
```

yields:
```
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

To support additional users, we would need to do some combination of upgrading
the host machine, as well as running additional instances on additional hosts.

> What documentation, websites, papers, etc did you consult in doing this assignment?

I mostly consulted documentation for various Ruby HTTP servers, Ruby API
documentation, and Sinatra documentation, including:
* https://github.com/sinatra/sinatra
* https://www.phusionpassenger.com/library/walkthroughs/basics/ruby/process_management.html
* https://www.linode.com/docs/development/ror/use-unicorn-and-nginx-on-ubuntu-14-04/
* https://www.speedshop.co/2015/07/29/scaling-ruby-apps-to-1000-rpm.html
* https://github.com/macournoyer/thin
* Uncountable StackOverflow posts

>What third-party libraries or other tools does the system use? How did you choose each library or framework you used?

Each technology is followed by the reason for using it.

Sinatra
* I had never used Sinatra before and have heard it's nice to use. It's also
much lighter weight than Rails (which is an alternative) so I thought I would try
something new.

Phusion
* This project makes use of the Phusion Passenger HTTP server which handles
multiple requests simultaneously (non-blocking) by running a process that 
first loads the project into memory, and then forks new processes to handle 
additional requests.
* The decision to use Passenger as a server was motivated largely by having a 
server that is easy to setup without requiring configuration. In a real-world 
scenario, it might well be the case that the best solution would be to run the 
system as an ECS task using the Thin HTTP server, rather than using Passenger
as I've done. Using Passenger allows me to focus more on a working solution
and less on configuration, setup, and infrastructure assumptions.
* I began by using Thin, but because I wanted to support multiple clients
(non-blocking) simultaneously and did not want to perform setup required to
run a load balancer in front of multiple Thin processes, I looked to Unicorn
and Passenger. I ultimately went with Passenger over Unicorn because it
required virtually no configuration to setup.

Redis
* I thought at one point about using background jobs (via Resque, which uses
redis) for the I/O, and also wanted to use some simple locking primitive for
locking on a file + partition size combination when writing files.
* I didn't end up using Resque, but I did keep Redis for the locking pattern
it allows with `setnx`; this is a pattern I've used before so it seemed like
a natural choice, especially since I thought I'd be using Redis anyway.

> How long did you spend on this exercise? If you had unlimited more time to spend on this, how would you spend it and how would you prioritize each item?

~7 - 10 hrs, excluding time I spent setting up boilerplate Github repos that I could
use for future projects.

Not to give a cop-out answer, but it's really hard to say without further, explicit requirements.

Priority #1 would be writing tests around the public interfaces of all the classes I use. Now that
the interfaces appear somewhat stable, I think investing that time makes a lot of sense.

The next priorities would seriously depend upon requirements and expected usage of this
service. If I had more time, I would talk with the stakeholders to understand
how this service is going to be used. (Ideally, that is done before you begin
work on a project, but for demo projects like this, exceptions must be made).

Without anymore stakeholder information, if we expected to need to support 
more additional connections than the service currently does, I would very likely
prioritize that above other needs because there is no clear path given the code
that has already been written for improving issues regarding # of connections,
whereas attempting to make reads from the file faster is already something
I've made improvements to over the naive solution.

> If you were to critique your code, what would you have to say about it?

On the positive side, I think the encapsulation is pretty reasonable throughout.
I had spent time thinking about the problem but not working on it prior, so I had
an idea of the types of objects I would need in my application even if I wasn't
certain of their exact implementation. Consequently, having reasonable encapsulation
means it is not hard to modify existing classes in case something changes in the code.
I found this to be the case for me as I was working.

On the negative side, I think some parts of the code are a bit sloppy -- the code
doesn't handle any errors; in any system, errors could happen anywhere and arbitrarily,
and the current system cannot correctly recover. Imagine that an error occurs in the middle
of writing a partition file -- everything will appear correct to the system but actually half
of the file would be missing. 

Furthermore, for better or worse, I've tried to implement a solution to this problem
with more of an interest in allowing an interesting discussion to take place, and less
with the intention of creating "the right solution," because there are so many unknowns. So
in some places, e.g. in my partitioning optimization, I've picked problems areas to improve a bit
arbitrarily, just for the sake of having something to show and discuss.
