class Reservation < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  before_validation :default_status
  validates_presence_of :status
  validates_inclusion_of :status, :in => ['pending approval', 'approved', 'denied']


  def default_status
    self.status ||= 'pending approval'
  end

  def approve
    self.status = 'approved'
    self.save
  end
end
