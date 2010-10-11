class CleanUpCustomFields < ActiveRecord::Migration
  def self.up
    default_tracker = Tracker.create!(:name => 'Experiment', :is_in_chlog => true, :is_in_roadmap => true)

    IssueCustomField.all(
      :conditions => { :name => ['Batch', 'Resume', 'Run start time', 'Run duration', 'Log file', 'Measurements DB', 'Measurements metadata']}
    ).each do |cf|
      cf.trackers.clear
      puts "Remove custom field #{cf.name}\n"
      cf.destroy
    end

    test_bed = IssueCustomField.find_by_name('Type')
    test_bed.update_attributes!(:name => 'Test bed')
    puts "Rename custom field 'Type' to '#{test_bed.name}'\n"
    test_bed.trackers.clear
    test_bed.trackers << default_tracker
    Project.all.each do |p|
      p.trackers.clear
      p.trackers << default_tracker
    end
    Issue.all.each do |i|
      i.tracker = default_tracker
      i.save!
    end
    Tracker.destroy_all("name != 'Experiment'")
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
