require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require './model.rb'
require 'byebug'

enable :sessions

include Model # why you not work huh

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
    if logged_in?(username, password) == true
      redirect('/browse/')
    else
      "Fel lösenord >:(" # Gör till en slimfil
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
 
  if password == password_confirm # Felhantera koden
    register_user(username, password)
    redirect("/browse/")
  else #felhantering
    "Lösenordet matchade inte!"
  end
end

# Displays the posts browsing page
# 
get('/browse/') do
    slim(:"posts/index")
end

# Displays the businesses data of the current user
#
# @param [Integer] :id, the id of the business currently being hovered 
# @see Model#get_businesses_from_user
get('/business/:id') do # if the user have 0 businesses, make it show another page
  id = params[:id].to_i
  business = get_businesses_from_user(id)
  slim(:"businesses/show", locals:{business:business})
end

# Refreshing the webpage to show the newly selected business on the businesses webpage by refreshing the business session
#
# @param [String] business_selected, a string of the id to store inside the business session
post('/refresh_businesses') do # can you remove this completely?? since i changed from sessions to params
  session[:business_id] = params[:business_selected]
  redirect('/business/:business_id')
end

# Displays the post creating page
#
get('/create_post/:id') do
  slim(:"posts/new")
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
post('/create_post/:id') do # fix how picture works
  business_id = params[:id].to_i
  title = params[:title]
  picture = params[:picture]
  p picture.class
  p picture
  body = params[:body]
  money_offer = params[:money_offer].to_i
  percent_offer = params[:percentage_offer].to_i

  create_post(business_id, title, picture, body, money_offer, percent_offer)
  redirect('/business/:business_id')
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

# Allows the user to change its username and redirects back to the account tab
#
# @param [Integer] :id, id of the current user
# @param [String] username, the new username of the user
# @see Model#change_username
post('/change_username/:id') do
  id = session[:id].to_i
  new_username = params[:username]
  change_username(id, new_username)
  redirect('/account/:id')
end

# Allows the user to change its password and redirects back to the account tab
#
# @param [Integer] :id, id of the current user
# @param [String] password, the new non-decrypted password of the user
# @param [String] username, the new password confirmation of the user
# @see Model#change_password
post('/change_password/:id') do
  id = params[:id].to_i
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == password_confirm # create a helpfunction which is a password check?
    change_password(id, password)
    redirect("/account/:id")
  else #felhantering
    "Lösenordet matchade inte!" # Samma felhantering som tidigare (SLIM)
  end
end

# Adds money to the current users account and redirects back to the account tab
#
# @param [Integer] :id, id of the current user
# @param [Integer] money_to_add, the amount of money the user wants to add
# @see Model#add_account_money
post('/add_account_money/:id') do
  id = session[:id].to_i
  money_to_add = params[:money_to_add].to_i
  add_account_money(id, money_to_add)
  redirect('/account/:id')
end

# Adds money to a selected business of the current user (while subtracting that amount from the users account balance) and redirects back to the account tab
#
# @param [Integer] :id, id of the business
# @session [Integer] :id, the id of the current user
# @param [Integer] money_to_add, the amount of money the user wants to add
# @see Model#account_money
# @see Model#add_account_money
post('/add_money/:id') do
  id = params[:id].to_i
  user_id = session[:id]
  user_money = account_money(id)

  money_to_add = params[:money_to_add].to_i
  
  if user_money > money_to_add
    add_account_money(id, money_to_add)
    redirect("/account/:id")
  else
    "You don't have that amount of money on your bank account" #  Felhantering (SLIM)
  end
end

# Makes the user "leave" a business and redirects them back to their account
#
# @param [Integer] :id, id of the business
# @session [Integer] :id, the id of the current user
# @see Model#leave_business
post('/leave/:id') do
  id = params[:id].to_i
  user_id = session[:id]
  leave_business(user_id, id)
  redirect('/account/:id')
end

# Lets the user type in the name of a business to join that business and then redirects them back to their account
#
# @param [Integer] :id, the id of the current user
# @param [String] business_name, the name of the business the user wants to join
# @see Model#join_business
post('/join_business/:id') do
  id = params[:id]
  business_name = params[:business_name]
  if join_business(id, business_name) == true #fixa felhantering
    redirect('/account/:id')
  else
    "This business doesn't exist"
  end
end

# Let the current user create a business and then redirects them back to their account
#
# @param [Integer] :id, the id of the current user
# @param [String] business_name, the name of the business the user wants to create
# @param [Integer] startingh_budget, the starting budget of the business
# @see Model#account_money
# @see Model#create_business
post('/create_business/:id') do
  id = params[:id]
  business_name = params[:business_name]
  starting_budget = params[:starting_budget].to_i
  user_money = account_money(id)

  if user_money > starting_budget
    create_business(id, user_money, business_name, starting_budget)
    redirect('/account/:id')
  else
    "You don't have enough money on your account for that starting budget :(" # Felhantering med SLIM
  end
end