class Reservation < ActiveRecord::Base
  include AASM
  include GCal4Ruby

  validates_presence_of :starts_at, :ends_at, :resource

  belongs_to :project
  belongs_to :user

  aasm_column :status

  aasm_initial_state :pending
  aasm_state :pending
  aasm_state :approved
  aasm_state :denied

  aasm_event :approve, :success => :add_to_google_calendar do
    transitions :to => :approved, :from => :pending
  end

  aasm_event :deny do
    transitions :to => :denied, :from => :pending
  end

  def add_to_google_calendar
    service = Service.new
    service.authenticate(AppConfig.gcal.account, AppConfig.gcal.password)
    calendar = Calendar.find(service, {:id => AppConfig.gcal.calendars.first.identifier})
    event = Event.new(service, {
      :calendar => calendar,
      :title => "#{resource} - #{user.name}",
      :start_time => starts_at,
      :end_time => ends_at,
      :where => resource})
    event.save
  end

  def print
    "#{resource} #{starts_at.strftime('%Y-%m-%d %H:%M:%S')}-#{ends_at.strftime('%Y-%m-%d %H:%M:%S')}"
  end
end
