module RavMeserV2
  class Connection
    include HTTParty
    debug_output $stdout

    include List
    include Subscriber
    include Webhook
    include Tag
    include PersonalField

    RAV_MESER_ENDPOINT = 'https://graph.responder.live/v2/'

    attr_accessor :access_token, :endpoint
    attr_reader :auth_error

    def initialize(client_key, client_secret, user_secret, endpoint = nil)
      @endpoint = endpoint || RAV_MESER_ENDPOINT
      params = { 
                 grant_type: "client_credentials",
                 scope: "*",
                 client_id: client_key,
                 client_secret: client_secret,
                 user_token: user_secret
               }

      response = send_request(:post, '/oauth/token', params, {}, skip_auth: true)

      if response[:token].present?
        @access_token = response[:token]
      else
        @auth_error = response
      end
    end

    def authenticated?
      access_token.present?
    end

    private

    def send_request(type, url, params = {}, query_params = {}, skip_auth: false)
      if !skip_auth && access_token.nil?
        return { error: "unauthorized", message: "Invalid access token." }
      end

      headers = { 'Content-Type' => 'application/json' }
      headers['Authorization'] = "Bearer #{access_token}" unless skip_auth

      request_params = {
        headers: headers,
        base_uri: endpoint,
        debug_output: $stdout
      }

      case type
        when :get
          url += "?#{URI.encode_www_form(params)}" unless params.empty?
        else
          request_params.merge!({ body: params.to_json })
        end

      request_params.merge!(query: query_params) if query_params.present?
  
      response = self.class.send(type, url, request_params)
      begin
        response = JSON.parse(response.body, symbolize_names: true)
      rescue StandardError => e
        if ENV['RAV_MESER_DEBUG']
          pp "Response was: ", response, response.body
        end
        raise StandardError, "#{e.message} - Response body: #{response.body}"
      end
      response
    end
  end
end