require 'net/http'
require 'json'

class BudaAPI
  API_URL = "https://www.buda.com/api/v2/markets"
  def trades(market_id, timestamp, limit = 50)
    uri = URI("#{API_URL}/#{market_id}/trades?timestamp=#{timestamp}&limit=#{limit}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    if response.code == '200'
      data = JSON.parse(response.body)
      tradeData = data["trades"]
      trades = Trade.new(tradeData['timestamp'].to_i, tradeData['last_timestamp'].to_i, tradeData['market_id'], [])
      tradeData['entries'].each do |entry_data|
        entry = Entrie.new(entry_data[0].to_i, entry_data[1].to_f, entry_data[2].to_f, entry_data[3])
        trades.entries << entry
      end
      return trades
    else
      puts "Error: #{response.code} - #{response.message}"
      return nil6
    end
  end
end

class Trade
  attr_accessor :timestamp, :last_timestamp, :market_id, :entries

  def initialize(timestamp, last_timestamp, market_id, entries)
    @timestamp = timestamp
    @last_timestamp = last_timestamp
    @market_id = market_id
    @entries = entries
  end
  def to_s
    "Trade: { timestamp: #{@timestamp}, last_timestamp: #{@last_timestamp}, market_id: #{@market_id}, entries: #{@entries} }"
  end
end

class Entrie
  attr_accessor :timestamp, :amount, :price, :direction

  def initialize(timestamp, amount, price, direction)
    @timestamp = timestamp
    @amount = amount
    @price = price
    @direction = direction
  end
  def to_s
    "Entrie: { timestamp: #{@timestamp}, amount: #{@amount}, price: #{@price}, direction: #{@direction} }"
  end
  def getTotal
    @amount * @price
  end
end

def timestamp(year, month, day, hour, minute, timezone_offset)
  time = Time.new(year, month, day, hour, minute, 0, timezone_offset)
  return time.to_i * 1000
end

def totalTransactedCLP(entries)
  total = 0
  entries.each do |entrie|
    total += entrie.getTotal()
  end
  total.truncate(2)
end

def totalTransactedBTC(entries)
  entries.sum{|entrie| entrie.amount}
end

def getEntriesByTimestamp(startTimestamp, endTimestamp, market_id)
  api = BudaAPI.new
  entries = []
  currentTimestamp = endTimestamp
  while currentTimestamp >= startTimestamp
    trade = api.trades(market_id, currentTimestamp, 100)
    trade.entries.each do |entrie|
      if entrie.timestamp >= startTimestamp && entrie.timestamp <= endTimestamp
        entries << entrie
      end
    end
    currentTimestamp = trade.last_timestamp
  end
  entries
end

startTimestamp2024 = timestamp(2024, 3, 1, 12, 0, "-03:00")
endTimestamp2024 = timestamp(2024, 3, 1, 13, 0, "-03:00")

startTimestamp2023 = timestamp(2023, 3, 1, 12, 0, "-03:00")
endTimestamp2023 = timestamp(2023, 3, 1, 13, 0, "-03:00")
market_id = "btc-clp"

entriesBlackBuda2024 = getEntriesByTimestamp(startTimestamp2024, endTimestamp2024, market_id)
entriesBlackBuda2023 = getEntriesByTimestamp(startTimestamp2023, endTimestamp2023, market_id)

totalTransactedCLP = totalTransactedCLP(entriesBlackBuda2024)
puts "En el evento BlackBuda 2024 se transó un total de $#{totalTransactedCLP} en pesos chilenos."

totalTransactedBTC2024 = totalTransactedBTC(entriesBlackBuda2024)
totalTransactedBTC2023 = totalTransactedBTC(entriesBlackBuda2023)
difference = totalTransactedBTC2024 - totalTransactedBTC2023
percentage_increase = (difference / totalTransactedBTC2023) * 100

puts "El aumento porcentual en el volumen de transacciones de BTC de 2023 a 2024 fue del #{percentage_increase.truncate(2)}%."

commission_rate = 0.008
commission_earned = totalTransactedCLP * commission_rate

puts "El dinero que se dejó de ganar debido a la liberación de comisiones fue de $#{commission_earned.truncate(2)} pesos chilenos."