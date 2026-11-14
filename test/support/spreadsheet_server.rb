require "socket"

module SpreadsheetServer
  def with_spreadsheet_response(body:, status: "200 OK")
    server = TCPServer.new("127.0.0.1", 0)
    original_url = Rails.configuration.x.spreadsheet_export_url
    Rails.configuration.x.spreadsheet_export_url = "http://127.0.0.1:#{server.addr[1]}/export?format=xlsx"
    thread = Thread.new do
      loop do
        connection = server.accept
        while (line = connection.gets)
          break if line == "\r\n"
        end
        connection.write "HTTP/1.1 #{status}\r\nContent-Type: application/octet-stream\r\nContent-Length: #{body.bytesize}\r\nConnection: close\r\n\r\n"
        connection.write body
        connection.close
      end
    end
    yield
  ensure
    Rails.configuration.x.spreadsheet_export_url = original_url
    thread&.kill
    thread&.join
    server&.close
  end

  def spreadsheet_content
    file_fixture("spreadsheet.xlsx").binread
  end
end
