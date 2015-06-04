def log_in_with_password(email, password)
  return true if session[:logged_in]
  @user = Advertiser.find_by_email(email)
  if @user && BCrypt::Password.new(@user.password) == password
    session[:logged_in] = true
    session[:user] = @user
    return true
  else
    @user = nil
    return false
  end
end

def log_out
  session.clear
end

def logged_in?
  session[:logged_in]
end

def admin?
  session[:user].email == 'andrew_nissen@yahoo.com'
end
