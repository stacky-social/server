# frozen_string_literal: true

# == Schema Information
#
# Table name: status_stats
#
#  id                              :bigint(8)        not null, primary key
#  status_id                       :bigint(8)        not null
#  replies_count                   :bigint(8)        default(0), not null
#  reblogs_count                   :bigint(8)        default(0), not null
#  favourites_count                :bigint(8)        default(0), not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  stacky_injected_favourite_count :bigint(8)
#
class StatusStat < ApplicationRecord
  belongs_to :status, inverse_of: :status_stat

  validates :stacky_injected_favourite_count, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  def replies_count
    [attributes['replies_count'], 0].max
  end

  def reblogs_count
    [attributes['reblogs_count'], 0].max
  end

  def favourites_count
    [attributes['favourites_count'], 0].max + (stacky_injected_favourite_count || 0)
  end

  def stacky_injected_favourite_count
    return 0 unless status.internal? && attributes['stacky_injected_favourite_count'].present?
    [attributes['stacky_injected_favourite_count'], 0].max
  end

  def increment_stacky_injected_favourite_count
    return unless status.internal?

    self.stacky_injected_favourite_count ||= 0
    self.stacky_injected_favourite_count += 1
    save!
  end

  def decrement_stacky_injected_favourite_count
    return unless status.internal?

    self.stacky_injected_favourite_count ||= 0
    self.stacky_injected_favourite_count -= 1 if self.stacky_injected_favourite_count > 0
    save!
  end
end
