class Reservation < ActiveRecord::Base
  include AASM
  include GCal4Ruby

  validates_presence_of :starts_at, :ends_at, :resource

  belongs_to :project
  belongs_to :user
  has_many :issues, :dependent => :destroy

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

    calendars = {}.tap do |hash|
      AppConfig.resources.each do |r|
        hash[r.gcal] ||= []
        YAML::load(resource).each do |n|
          hash[r.gcal] << n if r.nodes.detect {|v| v == n}
        end
      end
    end

    calendars.each_pair do |g, nodes|
      if !nodes.empty?
        calendar = Calendar.find(service, {:id => g})
        event = Event.new(service, {
          :calendar => calendar,
          :title => user.name,
          :content => nodes.to_yaml,
          :start_time => starts_at,
          :end_time => ends_at,
          :where => AppConfig.gcal.location
        })
        event.save
      end
    end
  end

  def print
    "#{starts_at.strftime('%Y-%m-%d %H:%M:%S')} - #{ends_at.strftime('%Y-%m-%d %H:%M:%S')} " + resource
  end
end
