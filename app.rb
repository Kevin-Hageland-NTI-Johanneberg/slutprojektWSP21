require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require './model.rb'
require 'byebug'

enable :sessions

get('/') do
    slim(:index)
end

get('/showlogin') do
    slim(:"users/login")
end

post('/login') do
    username = params[:username]
    password = params[:password]
    if logged_in?(username, password) == true
      redirect('/browse')
    else
      "Fel lösenord >:(" # Gör till en slimfil
    end
end

get('/showregister') do
    slim(:"users/register")
end

post('/register') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
 
  if password == password_confirm # Felhantera koden
    register_user(username, password)
    redirect("/browse")
  else #felhantering
    "Lösenordet matchade inte!"
  end
end

get('/browse') do
    slim(:"posts/index")
end

get('/business/:business_id') do
  id = session[:id].to_i
  business = get_businesses_from_user(id)
  slim(:"management/businesses", locals:{business:business})
end

post('/refresh_businesses') do
  session[:business_id] = params[:business_selected]
  redirect('/business/:business_id')
end

get('/create_post/:id') do
  slim(:"/management/new_post")
end

post('/create_post/:id') do # fix how picture works
  business_id = params[:id].to_i
  title = params[:title]
  picture = params[:picture]
  body = params[:body]
  money_offer = params[:money_offer].to_i
  percent_offer = params[:percentage_offer].to_i

  create_post(business_id, title, picture, body, money_offer, percent_offer)
  redirect('/business/:business_id')
end

get('/account/:id') do
  id = session[:id].to_i # params
  business = get_user_business_data(id)
  slim(:"management/user", locals:{business:business})
end

get('/logout') do
  session[:id] = nil
  redirect('/')
end

post('/change_username/:id') do
  id = session[:id].to_i
  new_username = params[:username]
  change_username(id, new_username)
  redirect('/account/:id')
end

post('/change_password/:id') do
  id = session[:id].to_i # params?
  password = params[:password]
  password_confirm = params[:password_confirm]

  if password == password_confirm # create a helpfunction which is a password check?
    change_password(id, password)
    redirect("/account/:id")
  else #felhantering
    "Lösenordet matchade inte!" # Samma felhantering som tidigare (SLIM)
  end
end

post('/add_account_money/:id') do
  id = session[:id].to_i
  money_to_add = params[:money_to_add].to_i
  add_account_money(id, money_to_add)
  redirect('/account/:id')
end

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

post('/leave/:id') do
  id = params[:id].to_i
  user_id = session[:id]
  leave_business(user_id, id)
  redirect('/account/:id')
end

post('/join_business') do
  id = session[:id]
  business_name = params[:business_name]
  if join_business(id, business_name) == true #fixa felhantering
    redirect('/account/:id')
  else
    "This business doesn't exist"
  end
end

post('/create_business') do
  id = session[:id]
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