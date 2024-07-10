# frozen_string_literal: true

class Stacky::DataInjectionController < ApplicationController

  skip_before_action :verify_authenticity_token, only: [:add, :delete, :modify, :increment_injected_favourite, :decrement_injected_favourite, :set_injected_favourite_count, :injected_favourite_count]
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
    status = ActivityPub::FetchRemoteStatusService.new.call(@status_json[:id], prefetched_body: @status_json, request_id: "#{Time.now.utc.to_i}-injected-status-#{@status_json[:performing_actor_uri]}")

    # step3: TODO: return a success message to the external user.
    render json: { msg: 'Inject Successfully', id: status&.id }
  end

  def modify
    puts "TOM DEBUG::32 data injection modify endpoint reached"
    puts params
    render json: { msg: 'Dry Run Modify Successfully', params: params }
  end

  def delete
    puts "TOM DEBUG::32 data injection delete endpoint reached"
    puts params
    render json: { msg: 'Dry run Delete Successfully', params: params }
  end

  def resolve_users
    return if @users.nil?
    #TODO update user if acct changes, uri is the unique identifier.

    @users.each do |user_params|
      @username = user_params[:username]
      @domain = user_params[:domain]
      @json = user_params[:json]
      uri = @json[:id]

      actor ||= ActivityPub::TagManager.instance.uri_to_resource(uri, Account)
      actor ||= Account.find_remote(@username, @domain)

      if actor.nil?
        # create the account
        ActivityPub::ProcessAccountService.new.stacky_inject_data_call(@username, @domain, @json)
        # actor ||= Account.find_remote(@username, @domain) # This should work now as the account is created.
      end
    end
  end

  # The following methods are for injecting favourites

  def increment_injected_favourite
    puts "TOM DEBUG params=#{params}"
    status = find_status(params[:uri], params[:id])
    if status&.internal?
      status.status_stat.increment_stacky_injected_favourite_count
      render json: { msg: 'Increment Favourite Successfully' }
    else
      render json: { msg: 'Increment Favourite Failed', error: 'Status not found or modification not allowed' }
    end
  end

  def decrement_injected_favourite
    status = find_status(params[:uri], params[:id])
    if status&.internal?
      status.status_stat.decrement_stacky_injected_favourite_count
      render json: { msg: 'Decrement Favourite Successfully' }
    else
      render json: { msg: 'Decrement Favourite Failed', error: 'Status not found or modification not allowed' }, status: 422
    end
  end

  def set_injected_favourite_count
    status = find_status(params[:uri], params[:id])
    if status&.internal?
      new_count = params[:count].to_i
      if new_count >= 0
        status.status_stat.update(stacky_injected_favourite_count: new_count)
        render json: { msg: 'Set Favourite Count Successfully' }
      else
        render json: { msg: 'Set Favourite Count Failed', error: 'Count must be non-negative' }, status: 422
      end
    else
      render json: { msg: 'Set Favourite Count Failed', error: 'Status not found or modification not allowed' }, status: 422
    end
  end

  def injected_favourite_count
    status = find_status(params[:uri], params[:id])
    if status
      render json: { stacky_injected_favourite_count: status.status_stat.stacky_injected_favourite_count }
    else
      render json: { msg: 'Status not found' }, status: 404
    end
  end

  private

  def find_status(uri, id = nil)
    status = Status.find_by(id: id) if id.present?
    status ||= Status.find_by(uri: uri)

    status
  end

end
