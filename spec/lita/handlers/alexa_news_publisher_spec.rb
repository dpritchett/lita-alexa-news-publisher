require "spec_helper"
require 'pry'
require 'date'

describe Lita::Handlers::AlexaNewsPublisher, lita_handler: true do
  let(:robot) { Lita::Robot.new(registry) }

  subject { described_class.new(robot) }

  describe 'routes' do
    it { is_expected.to route("Lita newsfeed hello, alexa!") }
  end

  describe ':save_message' do
    it 'saves a message and acknowledges' do
      result = subject.save_message(username: 'dpritchett', message: 'hello, alexa!')
    end

    it { is_expected.to route_event(:save_alexa_message).to(:save_message) }
  end

  it 'can grab a message from chat and store it' do
    send_message "lita newsfeed hello there #{DateTime.now}"
    response = replies.last
    expect(response =~ /hello there/i).to be_truthy
    expect(response =~ /Saved message for Alexa/).to be_truthy
  end

end
