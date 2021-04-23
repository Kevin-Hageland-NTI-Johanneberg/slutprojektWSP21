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
    redirect("/browse")
  else #felhantering
    "Lösenordet matchade inte!"
  end
end

get('/browse') do
    slim(:"posts/index")
end

get('/business/:id') do
  id = session[:id].to_i
  db = SQLite3::Database.new('db/online-investor.db')
  db.results_as_hash = true

  business = db.execute("SELECT businesses.name
  FROM ((user_to_business 
    INNER JOIN users ON user_to_business.user_id = users.id)
    INNER JOIN businesses ON user_to_business.user_id = user_id)
    WHERE users.id = ?", id)
  slim(:"management/businesses", locals:{business:business})
end

get('/account/:id') do
  id = session[:id].to_i
  db = SQLite3::Database.new('db/online-investor.db')
  db.results_as_hash = true
  username = db.execute("SELECT username FROM users WHERE id = ?", id).first #fix dis
  session[:username] = username

  business = db.execute("SELECT businesses.id, businesses.name, businesses.money
  FROM ((user_to_business 
    INNER JOIN users ON user_to_business.user_id = users.id)
    INNER JOIN businesses ON user_to_business.user_id = user_id)
    WHERE users.id = ?", id)
  slim(:"management/user", locals:{business:business})
end

post('/change_username/:id') do
  id = session[:id].to_i
  new_username = params[:username]

  db = SQLite3::Database.new('db/online-investor.db')
  db.execute("UPDATE users SET username = ? WHERE id = ?", new_username, id)
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
  money_to_add = params[:money_to_add]
  db = SQLite3::Database.new('db/online-investor.db')
  current_money = db.execute("SELECT money FROM users WHERE id = ?", id).first
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
    db.execute('UPDATE users SET money = ? WHERE id = ?', user_money, id)
    redirect("/account/:id")
  else
    "Oops, something went wrong!"
  end
end

post('/create post') do
  slim(:"/management/new_post")
end