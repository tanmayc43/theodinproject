class Flags::Actions::NotifyUser < Flags::Actions::Action
  def perform
    ActiveRecord::Base.transaction do
      send_notification
      flag.resolve(action_taken: :notified_user, resolved_by: admin_user)
    end

    if flag.resolved?
      Result.new(success: true, message: 'Notification sent')
    else
      Result.new(success: false, message: flag.errors.full_messages.join(', '))
    end
  end

  private

  def send_notification
    flag.project_submission.update!(discard_at: 7.days.from_now)

    FlagNotification.with(
      flag:,
      title: message.title,
      message: message.content,
      url: message.url
    ).deliver_later(flag.project_submission.user)
  end

  def message
    Messages::DeadLink.new(flag)
  end
end
