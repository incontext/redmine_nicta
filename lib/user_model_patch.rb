require 'user'

module UserModelPatch
  def self.included(base)
    base.class_eval do
      acts_as_captcha :base => true
    end
  end
end

User.send(:include, UserModelPatch)
