# RabbitWQ

A work queue built on RabbitMQ and Celluloid.

This is NOT production ready.  Released only to reserve gem name.


## Installation

Add this line to your application's Gemfile:

    gem 'rabbit-wq'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rabbit-wq


## Usage

### Queueing Work

    class SomeWorker < Struct.new( :some_variable )
      def call
        # do some work
      end
    end
    
    worker = SomeWorker.new( 1 )
    RabbitWQ::Work.enqueue( worker )

### Queueing Work in the Future

    RabbitWQ::Work.enqueue( worker, delay: 30000 )

### Queueing Work with a Retry

    RabbitWQ::Work.enqueue( worker, retry: 1 )

### Queueing Work with a Retry and a Retry Delay

    RabbitWQ::Work.enqueue( worker, retry: 1, retry_delay: 30000 )

### Queueing Work with a Retry and Auto-Scaling Retry Dealy

    RabbitWQ::Work.enqueue( worker, retry: 1, retry_delay: 'auto-scale' )

Auto-scale will set up retries at the following intervals: 1 min, 5 mins, 15 mins, 30 mins, 
1 hr, 6 hrs, 12 hrs, 24 hrs. and 48 hrs.

### Using the Worker Module

    class SomeWorker < Struct.new( :some_variable )
      include RabbitWQ::Worker

      def call
        # do some work
      end
    end
    
    worker = SomeWorker.new( 1 )
    worker.work # same as RabbitWQ::Work.enqueue( worker )

### Error Queue

Once a worker has thrown an exception and no retry attempts are remaining, the worker is placed on 
the error queue with the exception type, message and backtraces.
