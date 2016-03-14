class AddRateToTimeEntries < ActiveRecord::Migration
  def up
    add_column :time_entries, :rate, :decimal, default: 0.0, precision: 10, scale: 5
    sql = CustomValue.joins(:custom_field).
      where(customized_type: 'Principal').where("customized_id = user_id").
      select(:value).to_sql
    TimeEntry.update_all "rate = coalesce((#{sql}), 0.0)"
  end

  def down
    remove_column :time_entries, :rate
  end
end
