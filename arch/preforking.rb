require 'socket'
require_relative '../common'

module FTP
  class Preforking
    include Common

    CONCURRENCY = 4

    def run
      child_pids = []

      CONCURRENCY.times do
        child_pids << spawn_child
      end

      trap(:INT) {
        child_pids.each do |cpid|
          begin
            Process.kill(:INT,cpid)
          rescue Errno::ESRCH
          end
        end
        exit
      }

      loop do
        pid=Process.wait
        $stderr.puts "Process #{pid} quit unexpectedly"

        child_pids.delete(pid)
        child_pids << spawn_child
      end
    end

    def spawn_child
      fork do
        loop do
          @client = @control_socket.accept

          handler = CommandHandler.new(self)
          request = @client.gets(CRLF+CRLF)
          respond handler.handle(request)
          @client.close
        end
      end
    end
  end
end

server = FTP::Preforking.new(4481)
server.run
