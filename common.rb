module FTP
  module Common
    CRLF="\r\n"
    def initialize(port=21)
      @control_socket = TCPServer.new(port)
      trap(:INT){exit}
    end
    def respond(response)
      @client.write(response)
      @client.write(CRLF)
    end

    class CommandHandler
      attr_reader :connection
      def initialize(connection)
        @connection = connection
      end
      def pwd
        @pwd || Dir.pwd
      end
      def handle(data)
        puts "connected #{data}"
        cmd = data[0..3].strip.upcase
        options = data[4..-1].strip
        case cmd
        when 'USER'
          # Accept any username anonymously
          "230 Logged in anonymously"
        when 'SYST'
          # what's your name?
          "215 UNIX Working With FTP"
        when 'CWD'
          if File.directory?(options)
            @pwd = options
            "250 directory changed to #{pwd}"
          else
            "550 directory not found"
          end
        when 'PWD'
          "257 \"#{pwd}\" is the current directory"
        when 'PORT'
          parts = options.split(',')
          ip_address = parts[0..3].join('.')
          port = Integer(parts[4])*256+Integer(parts[5])
          puts "port #{parts} #{ip_address} #{port}"
          @data_socket = TCPSocket.new(ip_address,port)
          "200 Active connection established (#{port})"
        when 'RETR'
          file = File.open(File.join(pwd,options),'r')
          connection.respond "125 Data transfer starting #{file.size} bytes"

          bytes = IO.copy_stream(file,@data_socket)
          @data_socket.close

          "226 Closing data connection, send #{bytes} bytes"
        when 'LIST'
          connection.respond "125 Opening data connection for file list"

          result = Dir.entries(pwd).join(CRLF)
          @data_socket.write(result)
          @data_socket.close
          "226 Closing data connection, sent #{result.size} bytes"
        when 'QUIT'
          "221 Ciao"
        else
          "502 Don't know how to respond to #{cmd}"
        end
      end
    end
  end
end
#ftp -4 -A localhost 4481
#ls
#get serial.rb
