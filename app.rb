require 'rubygems'
require 'jdbc/postgres'
require 'java'
require './lib/java/TwsApi.jar'

Jdbc::Postgres.load_driver

IB = Java::ComIbClient

class Wrapper
  include IB::EWrapper

  def initialize
    @signal = IB::EJavaSignal.new
    @client = IB::EClientSocket.new(self, @signal)
  end

  def connect(id: 1, host: '127.0.0.1', port: 4001)
    @client.e_connect(host, port, id)
    reader = IB::EReader.new(@client, @signal)
    reader.start

    Thread.new do
      loop do
        break unless @client.is_connected

        @signal.wait_for_signal

        reader.process_msgs
      end
    end

    sleep 1
  end

  def disconnect
    @client.e_disconnect
  end

  def run_in_session(opts = {})
    connect(opts)
    yield if @client&.is_connected?
  ensure
    disconnect
  end

  def error(*args)
    STDERR.puts 'Received an error'
    STDERR.puts args.inspect
  end

  def connect_ack
    @client.start_api
  end

  def method_missing(method, *args, &block)
    puts "Method #{method} was called with arguments #{args.inspect}"

    if @client.respond_to?(method)
      puts "Client responds to method #{method}"

      @client.public_send(method.to_sym, *args)
    end
  end

  def account_summary(*args)
    pp args
  end

  def position(account_id, contract, pos, avg_cost)
    puts "#{contract.symbol}: #{pos} @ #{avg_cost}"
    insert(contract.symbol, pos, avg_cost) unless %w[EUR USD].include?(contract.symbol)
  end

  def position_end
    conn.close
    exit(0)
  end

  def insert(symbol, quantity, average_cost)
    stmt = conn.create_statement
    stmt.execute_update("
      INSERT INTO positions(time, symbol, quantity, average_cost)
      VALUES('#{Time.now}', '#{symbol}', #{quantity}, #{average_cost})
      ON CONFLICT (time, symbol)
      DO UPDATE
        SET quantity = EXCLUDED.quantity, average_cost = EXCLUDED.average_cost
    ")
    stmt.close
  end

  def conn
    return @conn if @conn

    url = 'jdbc:postgresql://10.2.0.2/postgres?user=postgres&password=password'
    @conn = java.sql.DriverManager.get_connection(url)
  end
end

class CheckAccount
  class << self
    def run
      w = Wrapper.new
      #req_id = rand(2^32 - 1)

      w.run_in_session do
        #w.req_account_summary(req_id, 'All', 'TotalCashValue')

        #contract = IB::Contract.new
        #contract.symbol('VOO')
        #contract.sec_type('STK')
        #contract.exchange('SMART')
        #contract.currency('USD')
        #w.req_historical_data(req_id, contract, '20130701 23:59:59 GMT', '3 D', '1 day', 'TRADES', 1, 1, false, [])

        w.req_positions
        loop {}
      end
    end
  end
end

pp CheckAccount.run
