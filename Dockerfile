FROM golang:1.13.6-alpine

# Set env
ENV LANG C.UTF-8
ENV TZ Asia/Tokyo

RUN apk --update --no-cache add \
	git \
	gcc \
	libc-dev \
	g++ \
	tzdata \
	&& cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
	&& apk del --purge tzdata

# Set working directory
WORKDIR /go/src/github.com/marugoshi/t.makototokuyama.com

# Install Hugo from source
RUN mkdir ~/src \
    && cd ~/src \
    && git clone https://github.com/gohugoio/hugo.git \
    && cd hugo \
    && go install --tags extended

COPY . .
