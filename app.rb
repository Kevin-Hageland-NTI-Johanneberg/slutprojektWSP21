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
    db = SQLite3::Database.new('db/online-investor.db')
    db.results_as_hash = true
    result = db.execute('SELECT * FROM users WHERE username = ?', username).first
    pwdigest = result['pwdigest']
    id = result['id']
  
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      session[:username] = username
      business_id = db.execute("SELECT business_id FROM user_to_business WHERE user_id = ?", id).first
      session[:business_id] = business_id["business_id"]
      redirect('/browse')
    else
      "Fel lösenord >:("
    end
end

get('/showregister') do
    slim(:"users/register")
end

post('/register') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
 
  if (password == password_confirm) #lägg till användare
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/online-investor.db')
    db.results_as_hash = true
    db.execute("INSERT INTO users (username,pwdigest,money) VALUES (?,?,0)", username, password_digest)
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    id = result['id']
    session[:username] = username
    session[:id] = id
    session[:business_id] = nil
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
  db = SQLite3::Database.new('db/online-investor.db')
  db.results_as_hash = true

  business = db.execute("SELECT businesses.id, businesses.name, businesses.money
  FROM (user_to_business 
    INNER JOIN businesses ON user_to_business.business_id = businesses.id)
    WHERE user_id = ?", id)
  slim(:"management/businesses", locals:{business:business})
end

post('/refresh_businesses') do
  session[:business_id] = params[:business_selected]
  redirect('/business/:business_id')
end

get('/create_post/:id') do
  slim(:"/management/new_post")
end

post('/create_post/:business_id') do
  business_id = session[:business_id].to_i
  title = params[:title]
  picture = params[:picture]
  body = params[:body]
  money_offer = params[:money_offer].to_i
  percent_offer = params[:percentage_offer].to_i

  db = SQLite3::Database.new('db/online-investor.db')
  db.execute("INSERT INTO posts (business_id, title, content, money_offer, percent_offer) VALUES (?, ?, ?, ?, ?)", business_id, title, body, money_offer, percent_offer)
  redirect('/business/:business_id')
end

get('/account/:id') do
  id = session[:id].to_i
  db = SQLite3::Database.new('db/online-investor.db')
  db.results_as_hash = true
  user_data = db.execute("SELECT * FROM users WHERE id = ?", id).first
  session[:username] = user_data["username"]
  session[:money] = user_data["money"]

  business = db.execute("SELECT businesses.id, businesses.name, businesses.money
  FROM (user_to_business 
    INNER JOIN businesses ON user_to_business.business_id = businesses.id)
    WHERE user_id = ?", id)
  slim(:"management/user", locals:{business:business})
end

get('/logout') do
  session[:id] = nil
  redirect('/')
end

post('/change_username/:id') do
  id = session[:id].to_i
  new_username = params[:username]

  db = SQLite3::Database.new('db/online-investor.db')
  db.execute("UPDATE users SET username = ? WHERE id = ?", new_username, id).first
  redirect('/account/:id')
end

post('/change_password/:id') do
  id = session[:id].to_i
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password == password_confirm) #lägg till användare
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/online-investor.db')
    db.results_as_hash = true
    db.execute("UPDATE users SET pwdigest = ? WHERE id = ?", password_digest, id)
    redirect("/account/:id")
  else #felhantering
    "Lösenordet matchade inte!"
  end
end

post('/add_account_money/:id') do
  id = session[:id].to_i
  money_to_add = params[:money_to_add].to_i
  db = SQLite3::Database.new('db/online-investor.db')
  current_money = db.execute("SELECT money FROM users WHERE id = ?", id).first.first
  total_money = current_money + money_to_add
  db.execute('UPDATE users SET money = ? WHERE id = ?', total_money, id)
  redirect('/account/:id')
end

post('/add_money/:id') do
  id = params[:id].to_i
  user_id = session[:id]
  money_to_add = params[:money_to_add].to_i
  db = SQLite3::Database.new('db/online-investor.db')
  user_money = db.execute('SELECT money FROM users WHERE id = ?', user_id).first.first
  if user_money > money_to_add
    current_money = db.execute("SELECT money FROM businesses WHERE id = ?", id).first.first
    total_money = current_money + money_to_add
    user_money -= money_to_add
    db.execute('UPDATE businesses SET money = ? WHERE id = ?', total_money, id)
    db.execute('UPDATE users SET money = ? WHERE id = ?', user_money, user_id)
    redirect("/account/:id")
  else
    "Oops, something went wrong!"
  end
end

post('/leave/:id') do
  id = params[:id].to_i
  user_id = session[:id]
  db = SQLite3::Database.new('db/online-investor.db')
  db.execute("DELETE FROM user_to_business WHERE business_id = ? AND user_id = ?", id, user_id).first
  redirect('/account/:id')
end

post('/join_business') do
  id = session[:id]
  business_name = params[:business_name]
  db = SQLite3::Database.new('db/online-investor.db')
  business_id = db.execute("SELECT id FROM businesses WHERE name = ?", business_name)
  db.execute("INSERT INTO user_to_business (user_id, business_id) VALUES (?, ?)", id, business_id)
  session[:business_id] = db.execute("SELECT business_id FROM user_to_business WHERE user_id = ?", id).first.first
  redirect('/account/:id')
end

post('/create_business') do
  id = session[:id]
  business_name = params[:business_name]
  starting_budget = params[:starting_budget].to_i
  db = SQLite3::Database.new('db/online-investor.db')
  user_money = db.execute('SELECT money FROM users WHERE id = ?', id).first.first

  if user_money > starting_budget
    user_money -= starting_budget
    db.execute('UPDATE users SET money = ? WHERE id = ?', user_money, id)

    db.execute("INSERT INTO businesses (name, money) VALUES (?, ?)", business_name, starting_budget)
    business_id = db.execute("SELECT id FROM businesses WHERE name = ?", business_name).first.first
    db.execute("INSERT INTO user_to_business (user_id, business_id) VALUES (?, ?)", id, business_id)
    session[:business_id] = db.execute("SELECT business_id FROM user_to_business WHERE user_id = ?", id).first.first
    redirect('/account/:id')
  else
    "You don't have enough money on your account for that starting budget :("
  end
end

