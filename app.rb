#encoding: utf-8
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def init_db
	@db = SQLite3::Database.new 'leprosorium.db'
	@db.results_as_hash = true
end


# before вызывается каждый раз при перезагрузке любой страницы
before do
	init_db
end

# configure вызывается каждый раз при конфигурации приложения:
# когда изменился код программы И перезагрузилась страница
configure do
	# инициализация базы данных

	init_db

	# создаёт таблицу , если её не существует
	@db.execute 'CREATE TABLE IF NOT EXISTS Posts
	(
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		created_date DATE, 
		content TEXT
	)'

	@db.execute 'CREATE TABLE IF NOT EXISTS Comments
	(
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		created_date DATE, 
		content TEXT,
		post_id INTEGER
	)'

end

get '/' do

	# Выбираем список постов из БД
	@results = @db.execute 'select * from Posts order by id desc'

	erb :index
end

# обработчик get запроса для /new
# (браузер получает страницу с сервера)
get '/new' do
  erb :new
end

# обработчик post запроса /new
# (браузер отправляет данные на сервер)
post '/new' do

  content = params[:content]

  if content.size <= 0
  	@error = 'Please enter text'
  	return erb :new
  end

  # сохранение данных в БД
  @db.execute 'insert into Posts (content, created_date) values (?, datetime())', [content]

  redirect '/'
end

get '/details/:post_id' do

	# получаем переменную из url
	post_id = params[:post_id]

	# получаем список постов
	# (у нас будет только один пост)
	results = @db.execute 'select * from Posts where id = ?', [post_id]
	
	# выбираем этот один пост в переменную @row
	@row = results[0]

	# выбираем комментариц для нашего поста
	@comments = @db.execute 'select * from Comments where post_id = ? order by id', [post_id]

	# возвращаем представление details.erb
	erb :details
end

# обработчик post-запроса /details/...
# (браузер отправляет данные на сервер, мы их принимаем)

post '/details/:post_id' do 

	# получаем переменную из url'a
	post_id = params[:post_id]

	# получаем переменную из post-запроса
	content = params[:content]

		@db.execute 'insert into Comments 
		(
			content, 
			created_date, 
			post_id
		) 
			values 
		(
			?, 
			datetime(), 
			?
		)', [content, post_id]

	redirect to('/details/' + post_id)

end