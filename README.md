# RabbitWQ

A work queue built on RabbitMQ and Celluloid.


## Installation

Add this line to your application's Gemfile:

    gem 'rabbit-wq'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rabbit-wq


## Usage

### Queue Subscriber

#### Starting the Work Queue Subscriber in Interactive Mode

    $ rabbit-wq start --interactive

#### Starting the Work Queue Subscriber as a Daemon

    $ rabbit-wq start

#### Stopping the Work Queue Subscriber

    $ rabbit-wq stop

#### Restarting the Work Queue Subscriber

    $ rabbit-wq restart

#### Checking the Status of the Work Queue Subscriber

    $ rabbit-wq status


#### Queueing Work

#### Implementing as a PORO

    class SomeWorker < Struct.new( :some_variable )
      def call
        # do some work
      end
    end
    
    worker = SomeWorker.new( 1 )
    RabbitWQ::Work.enqueue( worker )

#### Work in the Future

    RabbitWQ::Work.enqueue( worker, delay: 30000 )

#### Queueing Work with a Retry

    RabbitWQ::Work.enqueue( worker, retry: 1 )

#### Queueing Work with a Retry and a Retry Delay

    RabbitWQ::Work.enqueue( worker, retry: 1, retry_delay: 30000 )

#### Skipping Retry by Forcing a Final Error

You can use the RabbitWQ::FinalError to skip retry functionality in the case of an error that will never recover given a time delay.

    class SomeWorker < Struct.new( :some_variable )
      def call
        final_error( "Some message" )
      end
    end

The #final_error method will raise a RabbitWQ::FinalError which triggers the normal final error functionality (callbacks, logging, 
error queue queueing).  If you owuld like to treat the final error as something other than an error level occurence, you can pass the level
to #final_error.

    class SomeWorker < Struct.new( :some_variable )
      def call
        final_error( "Some message", :info )
      end
    end

When a level other than :error is provided, an log entry to the work log is created at the level provided, ie. :info.  However, an error is
not logged and an error is not queued on the error queue.  The error callbacks are still executed.  If you want to avoid functionality in 
an existing callback, you can test the #level of the error.

### Queueing Work with a Retry and Auto-Scaling Retry Dealy

    RabbitWQ::Work.enqueue( worker, retry: 1, retry_delay: 'auto-scale' )

Auto-scale will set up retries at the following intervals: 1 min, 5 mins, 15 mins, 30 mins, 
1 hr, 6 hrs, 12 hrs, 24 hrs. and 48 hrs.

#### Implementing with the Worker Module

    class SomeWorker < Struct.new( :some_variable )
      include RabbitWQ::Worker

      def call
        # do some work
      end
    end
    
    worker = SomeWorker.new( 1 )
    worker.work # same as RabbitWQ::Work.enqueue( worker )

### Success Callback

#### on_success

Called on success when defined on a worker.


### Error Handling

Once a worker has raised an exception and no retry attempts are remaining, the worker is placed on 
the error queue with the exception type, message and backtraces.

#### Error Callbacks

There are several error callbacks that will be called if defined on a worker.  Each error callback will receive
a single parameter, the error.

##### on_error

Called anytime an error is raised, including if a retry will be attempted.

##### on_final_error

Called when an error is raised and either no retries were requested or are remaining.

##### on_retryable_error

Called when an error is raised and a retry will be attempted.

### Disabling a Worker

A worker can be disabled by overriding the #enabled? method.

    class SomeWorker
      include RabbitWQ::Worker

      def enabled?
        # some logic to determine enabled
      end
    end

By default, when a worker is disabled a log entry is created and the worker does no work and leaves hte work queue 
system.  In order to have the worker sent to the error queue if disabled, simply override the #error_on_disabled? method:

    class SomeWorker
      include RabbitWQ::Worker

      def error_on_disabled?
        true
      end
    end


### Logging

RabbitWQ provides a work logger that is available within all workers.  You must send a reference to self
so that the #object_id may be put into the log message.

    RabbitWQ.work_logger.info( self, 'Some message' )

When the RabbitWQ::Worker module is mixed into a worker you can use the logging convenience methods.  You
do not have to provide a refrence to self in this case.

    class SomeWorker < Struct.new( :some_variable )
      include RabbitWQ::Worker

      def call
        info( 'Some message' )
        # do some work
      end
    end

The RabbitWQ loggers provide the following log levels: debug, info, warn, error and fatal.

### Work Publish vs. Subscribe Queue

Quite often the work publish and subscribe queues are the same queue.  However, certain use cases require a seprarate work publish
and subscribe queue.  For instance, when you use te RabbitMQ shovel plugin to effectively create a distributed queue, you may want 
to publish to a local queue that is shoveled to a central work queue, where the subscriber resides and performs the actual work.


### Configuration File

The RabbitWQ configuration file uses JSON syntax.  The default location for the configuration file is /var/run/rabbit-wq/rabbit-wq.conf

Here is an example configuration file with each option's default value:

    {
      "delayed_exchange_prefix": "work-delay",
      "delayed_queue_prefix": "work-delay",
      "environment_file_path": nil,
      "env": "production",
      "error_queue": "work-error",
      "threads": 1,
      "time_zone": "UTC",
      "work_exchange": "work",
      "work_exchange_type": "fanout",
      "work_log_level": "info",
      "work_log_path": "/var/log/rabbit-wq/rabbit-wq-work.log",
      "work_publish_queue": "work"
      "work_subscribe_queue": "work"
    }

#### Options

#####delayed_exchange_prefix
The prefix for the delayed exchanges.  Defaults to work-delay.

#####delayed_queue_prefix
The prefix for the delayed queues.  Defaults to work-delay.

#####environment_file_path
The path to the environment file (loads all or some of application environment).  No default.

#####env
The environment to run in.  Defaults to production.

#####error_queue
The name of the error queue. Defaults to error.

#####threads
The size of the thread pool.  Can be overridden with the command line option --threads or -t.  Defaults to 1.

#####time_zone
The time zone to use with ActiveRecord.

#####work_exchange
The name of the work exchange.  Defaults to work.

#####work_exchange_type
The RabbitMQ exchange type of the work exchange.  Defaults to fanout.  For more information see [RabbitMQ Docs](https://www.rabbitmq.com/tutorials/amqp-concepts.html).

#####work_log_level
The log level of the worker logger.  Defaults to info.

#####work_log_path
The path the worker logger will log to. Defaults to /var/log/rabbit-wq/rabbit-wq-work.log.

#####work_publish_queue
The name of the work queue to publish to.  Defaults to work.

#####work_subscribe_queue
The name of the work queue to subscribe to.  Defaults to work.


### Command Line Interface

#### Commands

#####start
Starts the subscriber.

#####stop
Stops the subscriber.

#####restart
Restarts the subscriber.

#####status
Reports the status of the subscriber, started or stopped.

#### Options

#####config (--config or -c)
The path for the configuration file.  Defaults to /etc/rabbit-wq/rabbit-wq.conf.

#####log_level (--log_level)
The log level for the work subscriber's logger.  This does not have an effect on the worker logger.  Defaults to info.

#####log (--log or -l)
The path for the work subsciber's log file.  Defaults to /var/log/rabbit-wq/rabbit-wq.log.

#####pid (--pid)
The path to the PID file.  Defaults to /var/run/rabbit-wq/rabbit-wq.pid.

#####interactive (--interactive or -i)
When used the work subscriber is executed in interactive (attached) mode as opposed to as a daemon.
