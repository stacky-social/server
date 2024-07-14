# frozen_string_literal: true

class ActivityPub::Activity::Delete < ActivityPub::Activity
  def perform
    if @account.uri == object_uri
      delete_person
    else
      delete_note
    end
  end

  private

  def delete_person
    with_redis_lock("delete_in_progress:#{@account.id}", autorelease: 2.hours, raise_on_failure: false) do
      DeleteAccountService.new.call(@account, reserve_username: false, skip_activitypub: true)
    end
  end

  def delete_note
    return if object_uri.nil?

    with_redis_lock("delete_status_in_progress:#{object_uri}", raise_on_failure: false) do
      unless non_matching_uri_hosts?(@account.uri, object_uri) || @json[:stacky_force_internal_delete].present? # NOTE: don't create a tombstone if the delete is from the data injection endpoint.
        # This lock ensures a concurrent `ActivityPub::Activity::Create` either
        # does not create a status at all, or has finished saving it to the
        # database before we try to load it.
        # Without the lock, `delete_later!` could be called after `delete_arrived_first?`
        # and `Status.find` before `Status.create!`
        with_redis_lock("create:#{object_uri}") { delete_later!(object_uri) }

        Tombstone.find_or_create_by(uri: object_uri, account: @account)
      end

      @status   = Status.find_by(uri: object_uri, account: @account)
      @status ||= Status.find_by(uri: @object['atomUri'], account: @account) if @object.is_a?(Hash) && @object['atomUri'].present?

      return if @status.nil?

      forwarder.forward! if forwarder.forwardable?
      delete_now!
    end
  end

  def forwarder
    @forwarder ||= ActivityPub::Forwarder.new(@account, @json, @status)
  end

  def delete_now!
    # NOTE: add api call request to update the index the status that comes from remote/injection.
    # Add before calling to prevent status from being deleted before the index is updated.
    api_response = Stacky::CurateApiHelper.delete_index_status(@status)
    puts "DEBUG:: Delete statues from activitypub, curate api response: #{api_response}"

    RemoveStatusService.new.call(@status, redraft: false, stacky_force_internal_delete: @json[:stacky_force_internal_delete]) # NOTE: the @json[:force_internal_delete] is a tag added if the delete injection data endpoint is called.
  end
end
