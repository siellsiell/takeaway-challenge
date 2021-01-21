require 'takeaway'

describe "Takeaway" do
  describe "#order" do

    it "prints menu" do
      menu_mock = class_double("Menu", :list => "stuff", :valid_order? => true)
      texter_mock = instance_double("Texter", :send_sms => nil)
      takeaway = Takeaway.new(texter: texter_mock, menu: menu_mock)
      allow(takeaway).to receive(:gets).and_return("1 1 1 20\n")

      expect { takeaway.order() }.to output(/stuff\n/).to_stdout
    end

    it "asks user to order" do
      menu_mock = class_double("Menu", :list => "stuff", :valid_order? => true)
      texter_mock = instance_double("Texter", :send_sms => nil)
      takeaway = Takeaway.new(texter: texter_mock, menu: menu_mock)
      allow(takeaway).to receive(:gets).and_return("1 1 1 20\n")

      expect { takeaway.order() }.to output(
        /Please enter the quantities for each dish/
      ).to_stdout
    end

    it "allows user to order and sends text when total is correct" do
      menu_mock = class_double("Menu", :list => "stuff", :valid_order? => true)
      texter_mock = instance_double("Texter", :send_sms => nil)
      takeaway = Takeaway.new(texter: texter_mock, menu: menu_mock)
      allow(takeaway).to receive(:gets).and_return("1 1 1 20\n")

      takeaway.order()

      expect(texter_mock).to have_received(:send_sms)
    end

    it "if ordering at midnight the text should be sent with delivery time at 1am" do
      menu_mock = class_double("Menu", :list => "stuff", :valid_order? => true)
      texter_mock = instance_double("Texter", :send_sms => nil)
      takeaway = Takeaway.new(texter: texter_mock, menu: menu_mock)
      current_time = Time.new(2020, 1, 1)
      takeaway.stub(:current_time) { current_time }
      allow(takeaway).to receive(:gets).and_return("1 1 1 20\n")

      takeaway.order()

      expect(texter_mock).to have_received(:send_sms).with(Time.new(2020, 1, 1, 1, 0, 0))
    end

    it "if ordering at 1pm the text should be sent with delivery time at 2pm" do
      menu_mock = class_double("Menu", :list => "stuff", :valid_order? => true)
      texter_mock = instance_double("Texter", :send_sms => nil)
      takeaway = Takeaway.new(texter: texter_mock, menu: menu_mock)
      current_time = Time.new(2020, 1, 1, 13, 0, 0)
      takeaway.stub(:current_time) { current_time }
      allow(takeaway).to receive(:gets).and_return("1 1 1 20\n")

      takeaway.order()

      expect(texter_mock).to have_received(:send_sms).with(Time.new(2020, 1, 1, 14, 0, 0))
    end

    it "allows user to order and raises error when total is incorrect" do
      menu_mock = class_double("Menu", :list => "stuff", :valid_order? => false)
      texter_mock = instance_double("Texter", :send_sms => nil)
      takeaway = Takeaway.new(texter: texter_mock, menu: menu_mock)
      allow(takeaway).to receive(:gets).and_return("1 1 1 13\n")

      expect { takeaway.order() }.to raise_error(/Total is incorrect/)

      expect(texter_mock).not_to have_received(:send_sms)
    end
  end
end

describe "Menu" do

  # TODO write test for Menu.list

  describe "#valid_order?" do
    it "returns true when expected total matches real total: 1,2,0 18" do
      expect(Menu.valid_order?([1, 2, 0], 18)).to be true
    end
    it "returns true when expected total matches real total: 0,0,1 3" do
      expect(Menu.valid_order?([0, 0, 1], 3)).to be true
    end
    it "returns true when expected total matches real total: 0,1,0 8" do
      expect(Menu.valid_order?([0, 1, 0], 8)).to be true
    end
    it "returns true when expected total matches real total: 1,0,0 2" do
      expect(Menu.valid_order?([1, 0, 0], 2)).to be true
    end
    it "returns false when expected total doesn't match real total: 1,2,0 10" do
      expect(Menu.valid_order?([1, 2, 0], 10)).to be false
    end
    it "returns false when expected total doesn't match real total: 0,0,1 29" do
      expect(Menu.valid_order?([0, 0, 1], 29)).to be false
    end
    it "returns false when expected total doesn't match real total: 0,1,0 0" do
      expect(Menu.valid_order?([0, 1, 0], 0)).to be false
    end
    it "returns false when expected total doesn't match real total: 1,0,0 100" do
      expect(Menu.valid_order?([0, 1, 0], 100)).to be false
    end
  end
end

class FakeMessages
  def initialize
    @sms = []
  end
  def create(from, to, body)
    @sms << {:from => from, :to => to, :body => body}
  end
  attr_reader :sms
end

class FakeTwilio
  def initialize
    @messages = FakeMessages.new
  end
  attr_reader :messages
end

describe Texter do
  it "sends an SMS with the delivery time" do
    twilio = FakeTwilio.new
    texter = Texter.new(twilio)
    delivery_time = Time.new(2020, 1, 1, 13, 23)

    texter.send_sms(delivery_time)

    expect(twilio.messages.sms).to eq([{
      :from => "+123",
      :to => "+447",
      :body => "Thank you! Your order was placed and will be delivered before 13:23."
    }])
  end
end

describe "IntegrationTest" do
  ["1 1 1 13", "1 0 3 11", "0 1 1 11"].each do |input|
    it "prints menu, allows user to order and returns success message when total is correct: #{input}" do
      takeaway = Takeaway.new(texter: Texter.new(FakeTwilio.new))
      allow(takeaway).to receive(:gets).and_return("#{input}\n")
      expect { takeaway.order() }.to output(
        "1) Vitamins 2.00\n" + 
        "2) Iron 8.00\n" + 
        "3) Calcium 3.00\n" + 
        "Please enter the quantities for each dish: " +
        "Success\n"
      ).to_stdout
    end
  end
  it "prints menu, allows user to order and raises error when total is incorrect" do
    takeaway = Takeaway.new(texter: Texter.new(FakeTwilio.new))
    allow(takeaway).to receive(:gets).and_return("1 1 1 20\n")
    expect { takeaway.order() }.to output(
      "1) Vitamins 2.00\n" + 
      "2) Iron 8.00\n" + 
      "3) Calcium 3.00\n" + 
      "Please enter the quantities for each dish: "
    ).to_stdout
      .and raise_error(/Total is incorrect/)
  end
end
