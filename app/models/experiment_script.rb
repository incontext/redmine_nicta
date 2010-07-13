class ExperimentScript < ActiveRecord::Base
  include Paperclip
  validates_presence_of :script

  has_attached_file :script

  def versions
    ExperimentScript.find(:all, :conditions => {:script_file_name => self.script_file_name})
  end
end
