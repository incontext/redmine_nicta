class ExperimentScript < ActiveRecord::Base
  include Paperclip

  has_attached_file :script, :path => "#{NICTA['fs_dir']}/:attachment/:basename/:id/:filename"

  has_many :issues

  def versions
    ExperimentScript.find(:all, :conditions => {:script_file_name => self.script_file_name})
  end
end
