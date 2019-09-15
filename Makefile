images:
	docker-compose build --no-cache

up:
	docker-compose up -d

down:
	docker-compose down

restart:
	make down
	make up

ps:
	docker-compose ps

logs:
	docker-compose logs -f

exec:
	docker-compose exec t bash

serve:
	docker-compose exec t bash -c 'hugo serve -p 1314 -D --bind=0.0.0.0'

hugo:
	docker-compose exec t bash -c 'hugo'

new:
	docker-compose exec t bash -c 'hugo new ${OPTION}'

# OPTION=--profile makoto
deploy:
	make hugo
	aws s3 sync --exact-timestamps --delete public s3://t.makototokuyama.com ${OPTION}
	git add .
	git ci -m 'update'
	git push origin master
