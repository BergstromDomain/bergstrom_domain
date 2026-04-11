class EventPerson < ApplicationRecord
  # ── Associations  ────────────────────────────────────────────────────────
  belongs_to :event
  belongs_to :person

  after_destroy :destroy_event_if_no_people_remain

  private

  def destroy_event_if_no_people_remain
    event.destroy if event.reload.people.empty?
  end
end
