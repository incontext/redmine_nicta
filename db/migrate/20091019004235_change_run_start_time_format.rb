class ChangeRunStartTimeFormat < ActiveRecord::Migration
  def self.up
    start_time = IssueCustomField.find_by_name('Run start time')
    start_time.update_attribute(:regexp, '') unless start_time.nil?
  end

  def self.down
  end
end
