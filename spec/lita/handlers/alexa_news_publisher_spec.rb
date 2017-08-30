require "spec_helper"
require 'pry'
require 'date'

describe Lita::Handlers::AlexaNewsPublisher, lita_handler: true do
  let(:robot) { Lita::Robot.new(registry) }

  subject { described_class.new(robot) }

  describe 'routes' do
      it { is_expected.to route_http(:get, "/alexa/newsfeed/a_user_name").to(:user_newsfeed) }

      it { is_expected.to route("Lita newsfeed hello, alexa!") }
  end

  describe ':save_message' do
    let(:body) { 'hello, alexa!' }
    it 'saves a message and acknowledges' do
      result = subject.save_message(username: 'dpritchett', message: body)

      expect(result.fetch(:message)).to eq body
    end

    it { is_expected.to route_event(:save_alexa_message).to(:save_message) }
  end

  describe ':alexify' do
    let(:message) { subject.save_message username: 'daniel', message: 'test message'}

    it 'should return a hash with an alexa-specific shape' do
      result = subject.alexify(message)
      expect(result.fetch(:mainText)).to eq('test message')
    end
  end

  it 'can grab a message from chat and store it' do
    send_message "lita newsfeed hello there #{DateTime.now}"
    response = replies.last
    expect(response =~ /hello there/i).to be_truthy
    expect(response =~ /Saved message for Alexa/).to be_truthy
  end

end
