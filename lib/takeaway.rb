require 'twilio-ruby'

TWILIO_ACCOUNT_SID = "AC8e9f8ff6a5a57ce87a2cc0739fd365ae"

class Menu

  @@dishes = [
    { :name => :Vitamins, :price => 2 },
    { :name => :Iron, :price => 8 },
    { :name => :Calcium, :price => 3 },
  ]

  def self.list
    @@dishes.map.with_index { |dish, index|
      format("%<number>s) %<name>s %<price>.2f", number: index + 1,
        name: dish[:name], price: dish[:price])
    }
  end

  def self.valid_order?(dish_quantities, expected_total)
    real_total = tally(dish_quantities, prices())
    real_total == expected_total
  end

  private_class_method def self.prices
    @@dishes.map { |d| d[:price] }
  end

  private_class_method def self.tally(order, prices)
    order.map.with_index { |quantity, index|
      prices[index] * quantity
    }.sum
  end

end

class Takeaway
  def initialize(texter:, menu: Menu)
    @menu = menu
    @texter = texter
  end

  def order
    puts @menu.list()
    print "Please enter the quantities for each dish: "

    input = gets.chomp

    order = input.split(" ").map(&:to_i)
    dishes = order[0..-2]
    total = order[-1]

    unless @menu.valid_order?(dishes, total)
      raise "Total is incorrect"
    end

    @texter.send_sms(delivery_time)
    puts "Success"
  end

  def self.create
    Takeaway.new(
      menu: Menu,
      texter: Texter.new(
        Twilio::REST::Client.new(
          TWILIO_ACCOUNT_SID,
          ENV["TWILIO_AUTH_TOKEN"]
        ),
        ENV["TO_PHONE_NUMBER"]
      )
    )
  end

  private

  def delivery_time
    current_time + 60 * 60
  end

  def current_time
    Time.new
  end

end

class Texter

  FROM_NUMBER = "+19842144030"
  def initialize(client, to_number)
    @sms_client = client
    @to_number = to_number
  end

  def send_sms(delivery_time)
    @sms_client.messages.create(
      from: FROM_NUMBER,
      to: @to_number,
      body: "Thank you! Your order was placed and will be delivered before " +
      "#{delivery_time.strftime("%R")}.")
  end
end

