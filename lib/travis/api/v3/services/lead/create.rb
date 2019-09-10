require 'uri'
require 'closeio'

module Travis::API::V3
  class Services::Lead::Create < Service
    result_type :lead
    params :name, :email, :team_size, :phone, :message, :utm_source

    def run!
      # Validation
      raise WrongParams, 'missing name' unless params['name'] && params['name'].length > 0
      raise WrongParams, 'invalid email' unless params['email'] && params['email'].length > 0 && params['email'].match(URI::MailTo::EMAIL_REGEXP).present?
      raise WrongParams, 'missing message' unless params['message'] && params['message'].length > 0

      # Prep data for request
      lead_data = {}
      lead_data['status'] = 'Potential'
      lead_data['name'] = params['name']
      lead_data['custom.team_size'] = params['team_size']
      lead_data['custom.utm_source'] = params['utm_source'] || 'Travis API'

      contact = {}
      contact['name'] = params['name']
      contact['emails'] = [{ type: "office", email: params['email'] }]
      contact['phones'] = []
      contact['phones'].push({ type: "office", phone: params['phone'] }) unless params['phone'].nil?

      lead_data['contacts'] = [contact]

      # Send request
      api_client = Closeio::Client.new(Travis.config.closeio.key)
      lead = api_client.create_lead(lead_data)
      note = api_client.create_note({ lead_id: lead['id'], note: params['message'] })

      # Return result
      model = Travis::API::V3::Models::Lead.new(lead)
      result model
    end
  end
end