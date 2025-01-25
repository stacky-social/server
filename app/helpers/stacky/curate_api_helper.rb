# frozen_string_literal: true
require 'net/http'
require 'json'

module Stacky::CurateApiHelper
  def self.get(url)
    uri = URI.parse(url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    response = https.get(uri.request_uri)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      puts "Error: #{response.message}"
      nil
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
    nil
  end

  def self.post(url, body)
    uri = URI(url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'application/json'})
    request.body = body.to_json
    response = https.request(request)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      puts "Error: #{response.message}"
      nil
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
    nil
  end



  def self.index_status(status)
    # extract the status information
    # and then call the GET api endpoints
    res = post('https://beta.stacky.social:3002/insert', request_body(status))
    "stub index success >>>> status id: #{status.id} msg: #{status.text} visibility: #{status.visibility} res: #{res}"
  end
  def self.update_index_status(status)
    # extract the status information
    # and then call the post to api endpoints
    res = post('https://beta.stacky.social:3002/update', request_body(status))

    "stub update index success >>>> status: #{status.id} msg: #{status.text} res: #{res}"
  end

  def self.delete_index_status(status)
    # extract the status information
    # and then call the post to api endpoints
    res = post('https://beta.stacky.social:3002/delete', request_body(status))

    "stub delete index success >>>> status: #{status.id} msg: #{status.text} res: #{res}"
  end

  def self.request_body(status)
    puts "DEBUG BODY=#{{ body: status.text, id: status.id, origin: server_origini, insert_flag: status.ext_flag }}"
    { body: status.text, id: status.id, visibility: status.visibility, origin: server_origin, insert_flag: status.ext_flag }
  end

  def self.server_origin
    if Rails.env.development?
      'development'
    elsif Rails.env.production?
      'production'
    else
      'test'
    end
  end

end

