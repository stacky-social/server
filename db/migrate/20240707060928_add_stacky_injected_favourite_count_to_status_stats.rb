class AddStackyInjectedFavouriteCountToStatusStats < ActiveRecord::Migration[7.1]
  def change
    add_column :status_stats, :stacky_injected_favourite_count, :bigint, null: true, default: nil
  end
end
