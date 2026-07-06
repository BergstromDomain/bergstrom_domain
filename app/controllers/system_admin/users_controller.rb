# app/controllers/system_admin/users_controller.rb
module SystemAdmin
  class UsersController < BaseController
    def index
      @users = if params[:status].present?
                 User.where(status: params[:status]).order("LOWER(last_name), LOWER(first_name)")
      else
                 User.all.order("LOWER(last_name), LOWER(first_name)")
      end
    end

    def show
      @user = User.find(params[:id])
    end

    def approve
      @user = User.find(params[:id])
      @user.update!(status: :active)
      UserMailer.approved(@user).deliver_later
      redirect_to system_admin_user_path(@user), notice: "#{@user.first_name} #{@user.last_name} has been approved."
    end

    def reject
      @user = User.find(params[:id])
      UserMailer.rejected(@user).deliver_later
      @user.destroy!
      redirect_to system_admin_users_path, notice: "Registration rejected and user removed."
    end

    def suspend
      @user = User.find(params[:id])
      @user.update!(status: :suspended)
      UserMailer.suspended(@user).deliver_later
      redirect_to system_admin_user_path(@user), notice: "#{@user.first_name} #{@user.last_name} has been suspended."
    end

    def reactivate
      @user = User.find(params[:id])
      @user.update!(status: :active)
      redirect_to system_admin_user_path(@user), notice: "#{@user.first_name} #{@user.last_name} has been reactivated."
    end

    def role
      @user = User.find(params[:id])
      @user.update!(role: params[:role])
      redirect_to system_admin_user_path(@user), notice: "Role updated."
    end
  end
end
