# frozen_string_literal: true

module Api::CachingConcern
  extend ActiveSupport::Concern

  def cache_if_unauthenticated!
    expires_in(15.seconds, public: true, stale_while_revalidate: 30.seconds, stale_if_error: 1.day) unless user_signed_in? # NOTE: Config Cache's length, if unauth, don't want to cache it for too long
  end

  def cache_even_if_authenticated!
    expires_in(5.minutes, public: true, stale_while_revalidate: 30.seconds, stale_if_error: 1.day) unless limited_federation_mode?
  end
end
