require 'pry'

module Lita
  module Handlers
    class AlexaNewsPublisher < Handler
      # insert handler code here
      
      http.get '/alexa/newsfeed/:username', :user_newsfeed

      def user_newsfeed(request, response)
        username = request.env["router.params"][:username]

        msg = redis.get('message') || 'Hello, alexa!'

        build = { message: msg}

        response.headers["Content-Type"] = "application/json"
        response.write(MultiJson.dump(build))
      end

      route /(newsfeed) (.*)/i, :publish_to_newsfeed

      def publish_to_newsfeed(response)
        # TODO: figure out redis LIFO arrays via redis.client
        #binding.pry

        redis.set('message', ':pogchamp:')
      end

      Lita.register_handler(self)
    end
  end
end
