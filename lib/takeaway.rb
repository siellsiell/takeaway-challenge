class Menu

  @@dishes = [
    { :name => :Vitamins, :price => 2 },
    { :name => :Iron, :price => 8 },
    { :name => :Calcium, :price => 3 },
  ]

  # todo move formatting to Takeaway
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
  def initialize(menu = Menu, texter = Texter)
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

    @texter.send
    puts "Success"
  end

end

class Texter

  def self.send
  end
end

