class AddUpdaterToPeopleAndEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :people, :updater, index: true
    add_reference :events, :updater, index: true
  end
end
