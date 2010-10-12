class UserProjectHook  < Redmine::Hook::Listener
  def controller_account_success_authentication_after(context)
    user = context[:user]
    roles = Role.givable
    identifier = "#{user.login}-personal"
    unless Project.find_by_identifier(identifier)
      project = Project.create!(:identifier => identifier, :name => "#{user.login.capitalize} personal", :is_public => false, :git_repository => true)
      project.members << Member.new(:user => user, :role_ids => roles.map {|v| v.id})
    end
  end
end
