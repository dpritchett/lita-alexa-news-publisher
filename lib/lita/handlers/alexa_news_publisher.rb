require 'pry'
require 'securerandom'
require 'json'

module Lita
  module Handlers
    class AlexaNewsPublisher < Handler
      http.get '/alexa/newsfeed/:username', :user_newsfeed

      STORE_KEY = 'alexa_newsfeed'
      MAX_MESSAGE_COUNT = 100

      def user_newsfeed(request, response)
        username = request.env["router.params"][:username]

        messages = Lita.redis.lrange(STORE_KEY, 0, MAX_MESSAGE_COUNT)

        formatted_messages = messages.map { |m| alexify JSON.parse(m, symbolize_names: true) }

        response.headers["Content-Type"] = "application/json"
        response.write(MultiJson.dump(formatted_messages))
      end

      def alexify(message)
        main_text = message.fetch(:message)

        {
          "uid": message.fetch(:uuid),
          "updateDate": message.fetch(:timestamp),
          "titleText": "Lita update",
          "mainText": main_text,
          "redirectionUrl": "https://github.com/dpritchett/lita-alexa-news-publisher"
         }
      end

      # allow other handlers to send messages through this system
      #  usage: robot.trigger(:save_alexa_message, username: 'user', message: 'message')
      on :save_alexa_message, :save_message

      def save_message(username:, message:)
        payload = {
          username: username,
          message: message,
          uuid: SecureRandom.uuid,  # e.g. 752fc85e-61b1-429f-8a69-cf6e6489c8c1
          timestamp: Time.now.utc.iso8601 # e.g. 2017-08-18T12:59:51Z
        }

        begin
          Lita.redis.rpush(STORE_KEY, JSON.dump(payload))

          prune_message_list!
          payload
        rescue Redis::CommandError
          @retries ||= 0
          @retries += 1

          Lita.redis.del(STORE_KEY)

          if @retries < 5
            retry
          else
            # handle failure
          end
        end
      end

      route /(newsfeed) (.*)/i, :publish_to_newsfeed

      def publish_to_newsfeed(response)
        # TODO: cleanup match parsing
        msg = response.matches.last.last
        save_message(username: response.user.name, message: msg)

        response.reply("Saved message for Alexa: [#{msg}]")
      end

      # only store the latest N messages in redis at a time
      def prune_message_list!
        while Lita.redis.llen(STORE_KEY) > MAX_MESSAGE_COUNT do
          Lita.redis.lpop(STORE_KEY)
        end
      end

      Lita.register_handler(self)
    end
  end
end
