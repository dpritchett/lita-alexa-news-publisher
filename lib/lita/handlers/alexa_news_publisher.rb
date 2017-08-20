require 'pry'
require 'securerandom'
require 'json'

module Lita
  module Handlers
    class AlexaNewsPublisher < Handler
      http.get '/alexa/newsfeed/:username', :user_newsfeed

      STORE_KEY = 'alexa_newsfeed'

      def user_newsfeed(request, response)
        username = request.env["router.params"][:username]

        messages = Lita.redis.lrange(STORE_KEY, 0, 10)

        formatted_messages = messages.map { |m| alexify m }

        response.headers["Content-Type"] = "application/json"
        response.write(MultiJson.dump(formatted_messages))
      end

      def alexify(message)
        parsed = JSON.parse(message)

        {
          "uid": parsed.fetch('uuid'),
          "updateDate": parsed.fetch('timestamp'),
          "titleText": "Multi Item JSON (TTS)",
          "mainText": parsed.fetch('message'),
          "redirectionUrl": "https://github.com/dpritchett"
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
          binding.pry
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

      Lita.register_handler(self)
    end
  end
end
