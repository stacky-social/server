# frozen_string_literal: true

class Stacky::DataInjectionController < ApplicationController

  skip_before_action :verify_authenticity_token, only: [:add, :delete, :modify]
  def add
    puts "TOM DEBUG::32 data injection add endpoint reached"
    puts params # try to receive the POST params!

    @users = params[:users] # array of users with username, domain, and json fields.
    @status_json = params[:status] # the status message to be injected.
    @status_json[:ext_flag] = "stacky-status-injection" # add a injection_flag to the status_json to indicate that this is an injected status.
    # user's ext-flag is set within the special function `resolve_users` called.

    # step0: TODO: add an authentication method to make sure this comes from curate.

    # step1: check if the external user exists, if not, add it using ResolveAccountService
    resolve_users

    # step2: TODO: create the activitypub json file and call an existing service to insert the create status message.
    # (Bypassing the Webfinger lookup in code, as well as the authentication service)
    # TODO: check if this should be the same @json as the one that is used for user injection.
    # TODO: Also there should be some regulations on the actor's inbox url. in order to successfully deliver the status. (For replys especially)
    # for other injected posts, maybe we can keep it system wise.
    # ActivityPub::ProcessingWorker.perform_async(actor.id, body, @account&.id, signed_request_actor.class.name)
    # ActivityPub::ProcessCollectionService.new.call(@json, actor) # override_timestamps: true, delivered_to_account_id: delivered_to_account_id, delivery: true)
    # NOTE: update: Seems like this one below is on the suitable layer for us to use. Make sure prefetched_body is not empty.
    ActivityPub::FetchRemoteStatusService.new.call(@status_json[:id], prefetched_body: @status_json, expected_actor_uri: @status_json[:performing_actor_uri], request_id: "#{Time.now.utc.to_i}-injected-status-#{@status_json[:performing_actor_uri]}")

    # step3: TODO: return a success message to the external user.

    render plain: 'Inject Successfully'
  end

  def modify
    puts "TOM DEBUG::32 data injection modify endpoint reached"
    puts params
    render json: {msg: 'Dry Run Modify Successfully', params: params}
  end

  def delete
    puts "TOM DEBUG::32 data injection delete endpoint reached"
    puts params
    render json: {msg: 'Dry run Delete Successfully', params: params}
  end

  def inject_post(params)
    puts "Injecting..."
  end

  def resolve_users
    return if @users.nil?

    @users.each do |user_params|
      @username = user_params[:username]
      @domain = user_params[:domain]
      @json = user_params[:json]

      actor ||= Account.find_remote(@username, @domain)

      if actor.nil?
        # create the account
        ActivityPub::ProcessAccountService.new.stacky_inject_data_call(@username, @domain, @json)
        # actor ||= Account.find_remote(@username, @domain) # This should work now as the account is created.
      end
    end
  end
end
