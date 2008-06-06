Ruby 1.9 is a development release in anticipation of Ruby 2.0, which has
overall better performance, real threading, and character encoding support.
Note: Ruby 1.9 is a development release, meaning that everything is
subject to change without prior notice.  Among other things, this means
that xmpp4r could stop working on Ruby 1.9 at any time.

This version of xmpp4r has made a number of internal changes (nothing visible
at the API) to remove depency on deprecated Ruby Kernel APIs, support the new
encoding APIs, etc.

At the present time, all tests pass except tc_helper.rb and tc_stream.rb.
These tests themselves make assumptions about timinings of events,
assumptions that are not guaranteed with true multi-tasking.  Initial
analysis indicates that xmpp4r is operating correctly, it is the tests
themselves that need to be corrected, but this could turn out to be
incorrect.

The executing of these two tests are disabled by a check in ts_xmpp4r.rb,
which is marked as a TODO.

A specific example: test_bidi in test/tc_stream.rb defines two threads,
one pumps out requests, the other echoes them.  The receiver then verifies
that it gets back what it sent.  With Ruby 1.8, these threads tend to
alternate in lock step, and the test usually passes.  What happens in Ruby 1.9
is that the first thread waits for a message, and the second one creates a
callback block, generates a message, and then proceeds on to create a second
callback block -- even before the first message has been responded to.
The way xmpp4r works is that callbacks are saved on a pushdown stack.

The net result is that the first response typically is processed first by 
the second callback, which decides that the ids don't match, and the test fails.

The way it is supposed to work is that the reply callback is supposed to
only process requests destined for it (and return true) and ignore
everything else (returning false).

This is but one test.  Many of the tests in these two files are of this
nature.

The current status of the tests that are expected to pass on Ruby 1.9
can generally be found here:

http://intertwingly.net/projects/ruby19/logs/xmpp4r.html
