require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require './app.rb'
require 'byebug'



# module Model
    
    # Retrieves the database
    #
    # @param [String] db, the database path
    # 
    # @return [SQLite3::Database] the database
    def connect_to_db(db)
        return SQLite3::Database.new(db)
    end
    
    # Tries to log in the user
    #
    # @param [String] username, the username
    # @param [String] password, tha password
    # @param [Boolean] first_login, keeps track if it's the first login after server has started
    # @param [Time] cooldown, the time of the last login attempt
    # @see Model#connect_to_db
    #
    # @return [Hash] 
    #       * :sucess [Boolean/String], if the user succeeded or not
    #       * :cooldown_timer [Time], the time of the login attempt 
    def logged_in?(username, password, first_login, cooldown_timer)
        if first_login == true
            cooldown_checker = 15
        else
            cooldown_checker = Time.now - cooldown_timer
        end
        
        db = connect_to_db('db/online-investor.db')
        db.results_as_hash = true
        result = db.execute('SELECT * FROM users WHERE username = ?', username).first
        

        if result != nil
            pwdigest = result['pwdigest']
            id = result['id']

            if BCrypt::Password.new(pwdigest) == password && cooldown_checker >= 15
                cooldown_time = Time.now
                cooldown_timer
                
                session[:id] = id
                session[:username] = username
                business_id = db.execute("SELECT business_id FROM user_to_business WHERE user_id = ?", id).first
                
                admin_id = db.execute("SELECT admin_id FROM admins WHERE user_id = ?", id).first
                if admin_id != nil
                    session[:admin] = true
                end
                return {:success => true, :cooldown_timer => cooldown_time}
            elsif cooldown_checker < 15
                cooldown_time = Time.now
                return {:success => "cooldown", :cooldown_timer => cooldown_time}
            else
                cooldown_time = Time.now
                return {:success => false, :cooldown_timer => cooldown_time}
            end
        elsif cooldown_checker < 15
            cooldown_time = Time.now
            return {:success => "cooldown", :cooldown_timer => cooldown_time}
        else
            cooldown_time = Time.now
            return {:success => false, :cooldown_timer => cooldown_time}
        end
    end

    # Registers a user
    #
    # @param [String] username, the username
    # @param [String] password, the password
    # @see Model#connect_to_db
    def register_user(username, password)
        password_digest = BCrypt::Password.create(password)
        db = connect_to_db('db/online-investor.db')
        db.results_as_hash = true
        db.execute("INSERT INTO users (username,pwdigest,money) VALUES (?,?,0)", username, password_digest)
        result = db.execute("SELECT * FROM users WHERE username = ?", username).first
        id = result['id']
        session[:username] = username
        session[:id] = id
        session[:business_id] = nil
        return
    end

    # The names from the businesses of current user
    #
    # @param [Integer] id, the id of the current user
    # @see Model#connect_to_db
    #
    # @return [Hash] containing the business data 
    def get_businesses_from_user(id)
        db = connect_to_db('db/online-investor.db')
        db.results_as_hash = true
    
        business = db.execute("SELECT businesses.id, businesses.name, businesses.money
        FROM (user_to_business 
        INNER JOIN businesses ON user_to_business.business_id = businesses.id)
        WHERE user_id = ?", id) # if this fucked up, return it by yoinking the code 2 rows below
        return business
    end 
    
    # Creates a post with data from the user
    #
    # @param [Integer] business_id, the id of the business creating the post
    # @param [String] title, the title of the post
    # @param [String] picture, a picture of the invention # might not be a string depending on how I make it work lol
    # @param [String] body, the description of the invention
    # @param [Integer] money_offer, the amount of money the user wants
    # @param [Integer] percent_offer, the percentage the user gives to the buyer for that money
    # @see Model#connect_to_db
    def create_post(business_id, title, picture, body, money_offer, percent_offer)
        db = connect_to_db('db/online-investor.db')
        db.execute("INSERT INTO posts (business_id, title, picture, content, money_offer, percent_offer) VALUES (?, ?, ?, ?, ?, ?)", business_id, title, picture, body, money_offer, percent_offer)  
        return
    end

    # The id, name and money data from the businesses of current user
    #
    # @param [Integer] id, the id of the business
    # @see Model#connect_to_db
    #
    # @return [Hash] containing the business data 
    def get_user_business_data(id)
        db = connect_to_db('db/online-investor.db')
        db.results_as_hash = true
        user_data = db.execute("SELECT * FROM users WHERE id = ?", id).first
        session[:username] = user_data["username"]
        session[:money] = user_data["money"]
    
        business = db.execute("SELECT businesses.id, businesses.name, businesses.money
        FROM (user_to_business 
        INNER JOIN businesses ON user_to_business.business_id = businesses.id)
        WHERE user_id = ?", id)
        return business
    end

    # Puts in the new username as admin in the admins table
    #
    # @param [String] username, the username of the new admin
    # 
    # @return [String] of the outcome
    def make_admin(username)
        db = connect_to_db('db/online-investor.db')

        user_id = db.execute("SELECT id FROM users WHERE username = ?", username).first
        potential_admin = db.execute("SELECT admin_id FROM admins WHERE user_id = ?", user_id).first
        if user_id != nil
            if potential_admin == nil
                db.execute("INSERT INTO admins (user_id) VALUES (?)", user_id)
                return "success"
            else
                return "already_exists"
            end
        else
            return "not_found"
        end
    end

    # Changes the username of the user by updating the database
    #
    # @param [Integer] id, the id of the current user
    # @param [String] username, the username the user wants to swap to
    # @see Model#connect_to_db
    def change_username(id, username)
        db = connect_to_db('db/online-investor.db')
        db.execute("UPDATE users SET username = ? WHERE id = ?", username, id).first
        return
    end

    # Changes the password of the user by updating the database
    #
    # @param [Integer] id, the id of the current user
    # @param [String] password, the password the user wants to swap to
    # @see Model#connect_to_db
    def change_password(id, password)
        password_digest = BCrypt::Password.create(password)
        db = connect_to_db('db/online-investor.db')
        db.results_as_hash = true
        db.execute("UPDATE users SET pwdigest = ? WHERE id = ?", password_digest, id)
        return
    end

    # Checking if the password is correct
    #
    # @param [Integer] id, the id of the current user
    # @param [String] password, the password the user entered
    # @see Model#connect_to_db
    #
    # @return [Hash]:
    #   * :error [Boolean] whether an error occured
    #   * :message [String] the error message
    def password_check(id, password)
        db = connect_to_db('db/online-investor.db')
        pwdigest = db.execute('SELECT pwdigest FROM users WHERE id = ?', id).first.first
        p pwdigest
        if BCrypt::Password.new(pwdigest) == password
            return {:error => false}
        else
            return {:error => true, :message => "That's not your current password."}
        end
    end
      

    # Looking at the users current money
    #
    # @param [Integer] id, the id of the current user
    # @param [Integer] money, the money the user want to add
    # @see Model#connect_to_db
    #
    # @return [Integer] of the users money
        def account_money(id)
            db = connect_to_db('db/online-investor.db')
            user_money = db.execute('SELECT money FROM users WHERE id = ?', id).first.first
            return user_money
        end      

    # Adding money to the current user by adding it onto what the user has and then updating the database
    #
    # @param [Integer] id, the id of the current user
    # @param [Integer] money, the money the user want to add
    # @see Model#account_money
    # @see Model#connect_to_db
    def add_account_money(id, money)
        db = connect_to_db('db/online-investor.db')
        current_money = account_money(id)
        total_money = current_money + money
        db.execute('UPDATE users SET money = ? WHERE id = ?', total_money, id)  
        return
    end

    # Adding money to a business by adding it onto what the business has and subtracting that from the user, then updating the database
    #
    # @param [Integer] business_id, the id of the business
    # @param [Integer] user_id, the id of the current user
    # @param [Integer] money_to_add, the money the user want to add
    # @see Model#account_money
    # @see Model#connect_to_db
    def add_business_money(business_id, user_id, money_to_add)
        db = connect_to_db('db/online-investor.db')
        current_money = db.execute("SELECT money FROM businesses WHERE id = ?", business_id).first.first
        total_money = current_money + money_to_add
        user_money = account_money(user_id)
        user_money -= money_to_add
        db.execute('UPDATE businesses SET money = ? WHERE id = ?', total_money, business_id)
        db.execute('UPDATE users SET money = ? WHERE id = ?', user_money, user_id)
        return
    end

    # Leave a business by removing the user from the business in user_to_business table
    #
    # @param [Integer] business_id, the id of the business
    # @param [Integer] user_id, the id of the current user
    # @see Model#connect_to_db
    def leave_business(user_id, business_id)
        db = connect_to_db('db/online-investor.db')
        db.execute("DELETE FROM user_to_business WHERE business_id = ? AND user_id = ?", business_id, user_id).first
        return
    end  

    # Join a business by inserting the id of the user into the user_to_business that got that specific business name
    #
    # @param [Integer] id, the id of the current user
    # @param [String] business_name, the name of the business the user wants to join
    # @see Model#connect_to_db
    #
    # @return [Hash]:
    #   * :error [Boolean] whether an error occured
    #   * :message [String] the error message
    #
    # ^^ I only did this once due to how I didn't want to redo most of my routes, but to show I'm capable
    def join_business(id, business_name)
        db = connect_to_db('db/online-investor.db')
        business_id = db.execute("SELECT id FROM businesses WHERE name = ?", business_name).first
        if business_id != nil
            db.execute("INSERT INTO user_to_business (user_id, business_id) VALUES (?, ?)", id, business_id)
            session[:business_id] = db.execute("SELECT business_id FROM user_to_business WHERE user_id = ?", id).first.first
            return {:error => false}
        else
            return {:error => true, :message => "There's no business with this name."}
        end
    end

    # User creates a business by inserting data into business table and user_to_business
    #
    # @param [Integer] user_id, the id of the current user
    # @param [Integer] user_money, the balance of the user
    # @param [String] name, the name of the business
    # @param [Integer] budget, the starting budget of the business
    # @see Model#connect_to_db
    def create_business(user_id, user_money, name, budget)
        db = connect_to_db('db/online-investor.db')
        user_money -= budget
        db.execute('UPDATE users SET money = ? WHERE id = ?', user_money, user_id)

        db.execute("INSERT INTO businesses (name, money) VALUES (?, ?)", name, budget)
        business_id = db.execute("SELECT id FROM businesses WHERE name = ?", name).first.first
        db.execute("INSERT INTO user_to_business (user_id, business_id) VALUES (?, ?)", user_id, business_id)
        session[:business_id] = db.execute("SELECT business_id FROM user_to_business WHERE user_id = ?", user_id).first.first
        return
    end

    # Delete a user by removing them from multiple tables
    #
    # @param [Integer] id, the id of the current user
    # @see Model#connect_to_db
    def delete_user(id)
        db = connect_to_db('db/online-investor.db')
        db.execute('DELETE FROM users WHERE id = ?', id)
        db.execute('DELETE FROM user_to_business WHERE user_id = ?', id)
        # db.execute('DELETE users, user_to_business # Attempt at deleting with inner join, also tried cascade but didn't find any good source that helped me solve it
        # FROM (users
        # INNER JOIN user_to_business ON users.id = user_to_business) WHERE users.id = ?', id)
        session[:id] = nil
        return
    end
# end