require_dependency 'account_controller'

module AccountControllerPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.extend InstanceMethods

    base.class_eval do
      acts_as_captcha
      alias_method_chain :register, :captcha
    end
  end

  module InstanceMethods
    def register_with_captcha
      redirect_to(home_url) && return unless Setting.self_registration? || session[:auth_source_registration]
      if request.get?
        session[:auth_source_registration] = nil
        @user = User.new(:language => Setting.default_language)
      else
        @user = User.new(params[:user])
        @user.admin = false
        @user.status = User::STATUS_REGISTERED
        if session[:auth_source_registration]
          @user.status = User::STATUS_ACTIVE
          @user.login = session[:auth_source_registration][:login]
          @user.auth_source_id = session[:auth_source_registration][:auth_source_id]
          if @user.save
            session[:auth_source_registration] = nil
            self.logged_user = @user
            flash[:notice] = l(:notice_account_activated)
            redirect_to :controller => 'my', :action => 'account'
          end
        else
          @user.login = params[:user][:login]
          @user.password, @user.password_confirmation = params[:password], params[:password_confirmation]
          @user.known_captcha = session[:captcha]
          @user.captcha = params[:captcha]

          case Setting.self_registration
          when '1'
            register_by_email_activation(@user)
          when '3'
            register_automatically(@user)
          else
            register_manually_by_administrator(@user)
          end
        end
      end
    end
  end
end

AccountController.send(:include, AccountControllerPatch)
