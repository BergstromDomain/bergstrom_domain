# app/controllers/concerns/toastable.rb
module Toastable
  extend ActiveSupport::Concern

  def toast_created(record)
    flash[:success] = "#{record.to_toast_label} has been successfully created"
  end

  def toast_updated(record, previous_label:)
    flash[:success] = "#{record.to_toast_label} has been successfully updated"
    if previous_label != record.to_toast_label
      flash[:info] = "#{previous_label} has been updated to #{record.to_toast_label}"
    end
  end

  def toast_deleted(record, info: nil)
    flash[:success] = "#{record.to_toast_label} has been successfully deleted"
    flash[:info] = info if info
  end

  def toast_published(record)
    flash[:success] = "#{record.to_toast_label} has been successfully published"
  end

  def toast_unpublished(record)
    flash[:success] = "#{record.to_toast_label} has been successfully unpublished"
  end

  def toast_error(record, prefix: nil)
    message = record.errors.full_messages.to_sentence
    flash[:error] = prefix ? "#{prefix}: #{message}" : message
  end
end
