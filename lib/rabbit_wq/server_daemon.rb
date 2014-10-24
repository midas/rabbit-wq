require 'rubygems'
require 'fileutils'
require 'timeout'

module RabbitWQ
  class ServerDaemon

    attr_reader :name,
                :options,
                :pid,
                :pid_path,
                :script,
                :timeout

    def initialize( options )
      @options  = options
      @name     = options[:name] || APP_NAME
      @pid_path = options[:pid] || '.'
      @pid      = get_pid
      @timeout  = options[:timeout] || 10
    end

    def start
      abort "Process already running!" if process_exists?

      pid = fork do
        exit if fork
        Process.setsid
        exit if fork
        store_pid( Process.pid )
        File.umask 0000
        redirect_output!
        run
      end

      Process.waitpid( pid )
    end

    def run
      Server.new( options ).start
    end

    def stop
      kill_process
      FileUtils.rm pid_path
    end

    def status
      $stdout.print "#{APP_NAME} "
      if process_exists?
        $stdout.puts "process running with PID: #{pid}"
        true
      else
        $stdout.puts "process does not exist"
        false
      end
    end

   protected

    #def create_pid( pid )
    def store_pid( pid )
      File.open( pid_path, 'w' ) do |f|
        f.puts pid
      end
    rescue => e
      $stderr.puts "Unable to open #{pid_path} for writing:\n\t(#{e.class}) #{e.message}"
      exit!
    end

    def get_pid
      return nil unless File.exists?( pid_path )
      pid = nil
      File.open( @pid_path, 'r' ) do |f|
        pid = f.readline.to_s.gsub( /[^0-9]/, '' )
      end
      pid.to_i
    rescue Errno::ENOENT
      nil
    end

    def remove_pidfile
      File.unlink( pid_path )
    rescue => e
      $stderr.puts "Unable to unlink #{pid_path}:\n\t(#{e.class}) #{e.message}"
      exit
    end

    def kill_process
      abort "#{APP_NAME} process is not running" unless process_exists?
      $stdout.write "Attempting to stop #{APP_NAME} process #{pid}..."
      Process.kill INT, pid
      iteration_num = 0
      while process_exists? && iteration_num < 10
        sleep 1
        $stdout.write "."
        iteration_num += 1
      end
      if process_exists?
        $stderr.puts "\nFailed to stop #{APP_NAME} process #{pid}"
      else
        $stdout.puts "\nSuccessfuly stopped #{APP_NAME} process #{pid}"
      end
    rescue Errno::EPERM
      $stderr.puts "No permission to query #{pid}!";
    end

    def process_exists?
      return false unless pid
      Process.kill( 0, pid )
      true
    rescue Errno::ESRCH, TypeError # "PID is NOT running or is zombied
      false
    rescue Errno::EPERM
      $stderr.puts "No permission to query #{pid}!";
      false
    end

    def redirect_output!
      if log_path = options[:log]
        #puts "redirecting to log"
        # if the log directory doesn't exist, create it
        FileUtils.mkdir_p( File.dirname( log_path ), :mode => 0755 )
        # touch the log file to create it
        FileUtils.touch( log_path )
        # Set permissions on the log file
        File.chmod( 0644, log_path )
        # Reopen $stdout (NOT +STDOUT+) to start writing to the log file
        $stdout.reopen( log_path, 'a' )
        # Redirect $stderr to $stdout
        $stderr.reopen $stdout
        $stdout.sync = true
      else
        #puts "redirecting to /dev/null"
        # We're not bothering to sync if we're dumping to /dev/null
        # because /dev/null doesn't care about buffered output
        $stdin.reopen '/dev/null'
        $stdout.reopen '/dev/null', 'a'
        $stderr.reopen $stdout
      end
      log_path = options[:log] ? options[:log] : '/dev/null'
    end

  end
end
