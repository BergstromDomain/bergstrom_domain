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

  def toast_validation_error(record)
    flash.now[:error] = record.errors.full_messages.to_sentence
  end
end
