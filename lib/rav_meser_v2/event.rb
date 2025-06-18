module RavMeserV2
  module Event
    def call(event_name, body_params = {})
      send_request(:post, '/events', body_params)
    end
  end
end
