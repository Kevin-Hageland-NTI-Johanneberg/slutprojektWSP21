require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require './model.rb'
require 'byebug'

enable :sessions

include Model # why you not work huh

# First login:
first_login = true

# Error messages:
not_logged_in_error = "You need to be logged in to see this."
wrong_password = "Wrong username or password. >:("
not_matching = "Passwords didn't match!"
data_error = "You've not entered the correct data, check if:\nYou've entered data in every field.\nEntered correct data type."
not_enough_money = "You don't have that amount of money on your account."
business_not_found = "There's no business with this name."
user_not_found = "There's no user with that name."
already_admin = "The user is already an Admin."
no_access = "You don't have access to this data."
cooldown_error = "The cooldown login cooldown is not ready."

before do
  if request.path_info != "/"  && request.path_info != "/register" && request.path_info != "/login" && request.path_info != "/browse" && request.path_info != "/error" && session[:id] == nil 
    session[:error] = not_logged_in_error
    redirect("/error")
  end
  # Försöker förhindra att man kan gå in på någon annans account när man väl är inloggad:
  # if params[:id] != session[:id] && params[:id] != nil
  #   session[:error] = no_access
  #   redirect("/error")
  # end
end

# Displays the error
#
# @session [String] error, the error message that should be displayed
get("/error") do
  error = session[:error]
  slim(:error, locals:{error:error})
end

# Display the home page to log in or register
#
get('/') do
    slim(:index)
end

# Display the log in page
#
get('/login') do
    slim(:login)
end

# Display the home page to log in or register and redirects to the browse page
#
# @param [String] username, the username of the user
# @param [String] password, the non-decrypted password of the user
# @see Model#logged_in?
post('/login') do
    username = params[:username]
    password = params[:password]
    if first_login == true
      session[:cooldown] = nil
    end

    login_response = logged_in?(username, password, first_login, session[:cooldown])
    if login_response[:success] == true
      if first_login == true
        first_login = false
      end
      session[:cooldown] = login_response[:cooldown_timer]
      redirect('/browse/')
    elsif login_response[:success] == "cooldown"
      if first_login == true
        first_login = false
      end
      session[:cooldown] = login_response[:cooldown_timer]
      session[:error] = cooldown_error
      redirect("/error")
    else
      if first_login == true
        first_login = false
      end
      session[:cooldown] = login_response[:cooldown_timer]
      session[:error] = wrong_password
      redirect("/error")
    end
end

# Display the register a new user page
#
get('/register') do
    slim(:register)
end

# Registering a new user and inserting the data into the database and redirects to the browse page
#
# @param [String] username, the username of the user
# @param [String] password, the non-decrypted password of the user
# @param [String] password_confirm, a confirmation string that should be equal to "password" for the registration to ge through
# @see Model#register_user
post('/register') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
 
  if password == password_confirm
    register_user(username, password) # Missade felhantering här, enkel if-statement
    redirect("/browse/")
  else 
    session[:error] = not_matching
    redirect("/error")
  end
end

# Displays the posts browsing page
# 
get('/browse/') do
    slim(:"posts/index")
end

# Displays the businesses data of the current user
#
# @param [Integer] :id, the id of the current user
# @see Model#get_businesses_from_user
get('/business/:id') do # if the user have 0 businesses, make it show another page
  id = params[:id].to_i
  business = get_businesses_from_user(id)
  slim(:"businesses/show", locals:{business:business})
end

# Displays the post creating page
#
# @param [Integer] :id, the id of the user
# @params [Integer] business_id, the id of the business that wants to create a new post
get('/create_post/:id/new') do
  id = params[id].to_i
  business_id = params[:business_selected].to_i
  slim(:"posts/new", locals:{business_id:business_id})
end

# Creates a new invention post with the following information and then redirects to the the users businesses tab:
#
# @param [Integer] :id, the id of the business creating the post
# @param [String] title, the title of the post
# @param [String] picture, a picture of the invention # might not be a string depending on how I make it work lol
# @param [String] body, the description of the invention
# @param [Integer] money_offer, the amount of money the user wants
# @param [Integer] percentage_offer, the percentage the user gives to the buyer for that money
# @see Model#create_post
post('/create_post/:id/update') do # fix how picture works
  business_id = params[:id].to_i
  user_id = session[:id]
  title = params[:title]
  picture = params[:picture]
  body = params[:body]
  money_offer = params[:money_offer].to_i
  percent_offer = params[:percent_offer].to_i

  if business_id == nil || title == nil || picture == nil || body == nil || money_offer == nil || percent_offer == nil || percent_offer == 0 || money_offer == 0
    session[:error] = data_error
    redirect("/error")
  end

  create_post(business_id, title, picture, body, money_offer, percent_offer)
  redirect("/business/#{user_id}")
end

# Displays the current users profile
#
# @param [Integer] :id, the id of the current user which will be used to get the users business data
# @see Model#get_user_business_data
get('/account/:id') do
  id = params[:id].to_i
  business = get_user_business_data(id)
  slim(:"user/show", locals:{business:business})
end

# Logs the current user out by setting the session to nil and redirects to the home page
#
get('/logout') do
  session[:id] = nil
  session[:admin] = nil
  redirect('/')
end

# Deletes the current user out of the database and redirects back to the home screen
#
# @param [Integer] :id, id of the current user
# @see Model#delete_user
post('/user/:id/delete') do
  id = params[:id].to_i
  delete_user(id)
  redirect('/')
end

# Gives other admins the opertunity to make someone else also an admin
#
# @session [Integer] :id, the id of the user
# @param [String] username, the name of the new admin
# @see Model#make_admin
post('/make_admin') do
  id = session[:id].to_i
  username = params[:username]
  if make_admin(username) == "already_exists"
    session[:error] = already_admin
    redirect("/error")
  elsif make_admin(username) == "not_found"
    session[:error] = user_not_found
    redirect("/error")
  else
    redirect("/account/#{id}")
  end
end


# Allows the user to change its username and redirects back to the account tab
#
# @param [Integer] :id, id of the current user
# @param [String] username, the new username of the user
# @see Model#change_username
post('/change_username/:id/update') do
  id = session[:id].to_i
  new_username = params[:username]
  change_username(id, new_username)
  redirect("/account/#{id}")
end

# Allows the user to change its password and redirects back to the account tab
#
# @param [Integer] :id, id of the current user
# @param [String] password, the new non-decrypted password of the user
# @param [String] password_confirm, the new password confirmation of the user
# @param [String] old_password, the old password entered by the user
# @see Model#password_check
# @see Model#change_password
post('/change_password/:id/update') do
  id = params[:id].to_i
  password = params[:password]
  password_confirm = params[:password_confirm]
  old_password = params[:old_password]
  
  result = password_check(id, old_password)
  if result[:error] == true
    session[:error] = result[:message]
    redirect("/error")
  end

  if password == password_confirm
    change_password(id, password)
    redirect("/account/#{id}")
  else 
    session[:error] = not_matching
    redirect("/error")
  end
end

# Adds money to the current users account and redirects back to the account tab
#
# @param [Integer] :id, id of the current user
# @param [Integer] money_to_add, the amount of money the user wants to add
# @see Model#add_account_money
post('/add_account_money/:id/update') do
  id = params[:id].to_i
  money_to_add = params[:money_to_add].to_i

  if money_to_add <= 0 || money_to_add == nil
    session[:error] = data_error
    redirect("/error")
  end

  add_account_money(id, money_to_add)
  redirect("/account/#{id}")
end

# Adds money to a selected business of the current user (while subtracting that amount from the users account balance) and redirects back to the account tab
#
# @param [Integer] :id, id of the business
# @session [Integer] :id, the id of the current user
# @param [Integer] money_to_add, the amount of money the user wants to add
# @see Model#account_money
# @see Model#add_account_money
post('/add_money/:id/update') do
  id = params[:id].to_i
  user_id = session[:id]
  user_money = account_money(id)

  money_to_add = params[:money_to_add].to_i

  if money_to_add <= 0 || money_to_add == nil
    session[:error] = data_error
    redirect("/error")
  elsif user_money > money_to_add
    add_account_money(id, money_to_add)
    redirect("/account/#{id}")
  else
    session[:error] = not_enough_money
    redirect("/error")
  end
end

# Makes the user "leave" a business and redirects them back to their account
#
# @param [Integer] :id, id of the business
# @session [Integer] :id, the id of the current user
# @see Model#leave_business
post('/leave/:id/delete') do
  id = params[:id].to_i
  user_id = session[:id]
  leave_business(user_id, id)
  redirect("/account/#{id}")
end

# Lets the user type in the name of a business to join that business and then redirects them back to their account
#
# @param [Integer] :id, the id of the current user
# @param [String] business_name, the name of the business the user wants to join
# @see Model#join_business
post('/join_business/:id/update') do
  id = params[:id]
  business_name = params[:business_name]
  result = join_business(id, business_name)
  if result[:error] == false
    redirect("/account/#{id}")
  else
    session[:error] = result[:message]
    redirect("/error")
  end
end

# Let the current user create a business and then redirects them back to their account
#
# @param [Integer] :id, the id of the current user
# @param [String] business_name, the name of the business the user wants to create
# @param [Integer] startingh_budget, the starting budget of the business
# @see Model#account_money
# @see Model#create_business
post('/create_business/:id/update') do
  id = params[:id]
  business_name = params[:business_name]

  if params[:starting_budget] == nil
    starting_budget = 0
  else
    starting_budget = params[:starting_budget].to_i
  end

  user_money = account_money(id)

  if user_money > starting_budget
    create_business(id, user_money, business_name, starting_budget)
    redirect("/account/#{id}")
  else
    session[:error] = not_enough_money
    redirect("/error")
  end
end